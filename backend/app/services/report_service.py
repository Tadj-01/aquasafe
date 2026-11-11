from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from uuid import UUID
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, desc

from app.models.report import Report, ReportStatus, ReportPriority
from app.models.status_history import StatusHistory
from app.models.repair_team import RepairTeam
from app.models.administrator import Administrator
from app.services.geographic_service import geo_service


class ReportService:
    @staticmethod
    def create_report(
        db: Session,
        latitude: float,
        longitude: float,
        photo_url: str,
        gps_accuracy: Optional[float] = None,
        note: Optional[str] = None,
    ) -> Report:
        """
        Create a new leak report submitted by a citizen.
        No citizen account required.
        Looks up administrative Wilaya and Commune using Syscli Algeria.
        """
        if not geo_service.validate_coordinates(latitude, longitude):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid coordinates: latitude={latitude}, longitude={longitude}",
            )

        # Lookup administrative info
        geo_data = geo_service.lookup_location(latitude, longitude)

        report = Report(
            latitude=latitude,
            longitude=longitude,
            gps_accuracy=gps_accuracy,
            photo_url=photo_url,
            note=note.strip() if note else None,
            wilaya_code=geo_data.get("wilaya_code"),
            wilaya_name=geo_data.get("wilaya_name"),
            commune_code=geo_data.get("commune_code"),
            commune_name=geo_data.get("commune_name"),
            status=ReportStatus.NEW,
            priority=ReportPriority.NORMAL,
        )

        db.add(report)
        db.flush()

        # Add initial history entry
        initial_history = StatusHistory(
            report_id=report.id,
            old_status=None,
            new_status=ReportStatus.NEW,
            changed_by=None,  # Submitted by citizen
            note="Initial report submission by citizen",
        )
        db.add(initial_history)
        db.commit()
        db.refresh(report)
        return report

    @staticmethod
    def get_report_by_id(db: Session, report_id: UUID) -> Report:
        report = db.query(Report).filter(Report.id == report_id).first()
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Report with ID '{report_id}' not found.",
            )
        return report

    @staticmethod
    def update_status(
        db: Session,
        report_id: UUID,
        new_status: str,
        admin: Administrator,
        note: Optional[str] = None,
    ) -> Report:
        norm_status = new_status.upper().strip()
        if norm_status not in ReportStatus.ALL:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid status '{new_status}'. Allowed: {', '.join(ReportStatus.ALL)}",
            )

        report = ReportService.get_report_by_id(db, report_id)
        old_status = report.status

        if old_status == norm_status:
            return report

        report.status = norm_status
        report.updated_at = datetime.now(timezone.utc)

        history = StatusHistory(
            report_id=report.id,
            old_status=old_status,
            new_status=norm_status,
            changed_by=admin.id,
            note=note,
        )
        db.add(history)
        db.commit()
        db.refresh(report)
        return report

    @staticmethod
    def update_priority(
        db: Session,
        report_id: UUID,
        new_priority: str,
        admin: Administrator,
        note: Optional[str] = None,
    ) -> Report:
        norm_priority = new_priority.upper().strip()
        if norm_priority not in ReportPriority.ALL:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid priority '{new_priority}'. Allowed: {', '.join(ReportPriority.ALL)}",
            )

        report = ReportService.get_report_by_id(db, report_id)
        report.priority = norm_priority
        report.updated_at = datetime.now(timezone.utc)

        if note:
            history = StatusHistory(
                report_id=report.id,
                old_status=report.status,
                new_status=report.status,
                changed_by=admin.id,
                note=f"Priority updated to {norm_priority}. Note: {note}",
            )
            db.add(history)

        db.commit()
        db.refresh(report)
        return report

    @staticmethod
    def assign_repair_team(
        db: Session,
        report_id: UUID,
        assigned_team_id: Optional[UUID],
        admin: Administrator,
        note: Optional[str] = None,
    ) -> Report:
        report = ReportService.get_report_by_id(db, report_id)

        team_name = "None"
        if assigned_team_id is not None:
            team = (
                db.query(RepairTeam)
                .filter(RepairTeam.id == assigned_team_id)
                .first()
            )
            if not team:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Repair team '{assigned_team_id}' not found.",
                )
            team_name = team.name
            report.assigned_team_id = team.id
            if report.status == ReportStatus.NEW or report.status == ReportStatus.VERIFIED:
                report.status = ReportStatus.ASSIGNED
        else:
            report.assigned_team_id = None

        report.updated_at = datetime.now(timezone.utc)

        history = StatusHistory(
            report_id=report.id,
            old_status=report.status,
            new_status=report.status,
            changed_by=admin.id,
            note=f"Assigned team changed to '{team_name}'. {note or ''}".strip(),
        )
        db.add(history)
        db.commit()
        db.refresh(report)
        return report

    @staticmethod
    def list_reports(
        db: Session,
        skip: int = 0,
        limit: int = 50,
        status: Optional[str] = None,
        priority: Optional[str] = None,
        wilaya_code: Optional[str] = None,
        commune_code: Optional[str] = None,
        search_query: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> List[Report]:
        query = db.query(Report)

        if status:
            query = query.filter(Report.status == status.upper().strip())
        if priority:
            query = query.filter(Report.priority == priority.upper().strip())
        if wilaya_code:
            query = query.filter(Report.wilaya_code == str(wilaya_code).zfill(2))
        if commune_code:
            query = query.filter(Report.commune_code == str(commune_code))
        if start_date:
            query = query.filter(Report.created_at >= start_date)
        if end_date:
            query = query.filter(Report.created_at <= end_date)
        if search_query:
            q = f"%{search_query.strip()}%"
            # Support searching by note, wilaya, commune, or report ID string
            query = query.filter(
                (Report.note.ilike(q))
                | (Report.wilaya_name.ilike(q))
                | (Report.commune_name.ilike(q))
            )

        return query.order_by(desc(Report.created_at)).offset(skip).limit(limit).all()

    @staticmethod
    def get_map_reports(
        db: Session,
        status: Optional[str] = None,
        wilaya_code: Optional[str] = None,
    ) -> List[Report]:
        query = db.query(Report)
        if status and status.upper() != "ALL":
            query = query.filter(Report.status == status.upper().strip())
        if wilaya_code:
            query = query.filter(Report.wilaya_code == str(wilaya_code).zfill(2))
        return query.order_by(desc(Report.created_at)).all()

    @staticmethod
    def get_dashboard_statistics(db: Session) -> Dict[str, Any]:
        total = db.query(Report).count()
        new_cnt = db.query(Report).filter(Report.status == ReportStatus.NEW).count()
        verified_cnt = (
            db.query(Report).filter(Report.status == ReportStatus.VERIFIED).count()
        )
        assigned_cnt = (
            db.query(Report).filter(Report.status == ReportStatus.ASSIGNED).count()
        )
        under_repair_cnt = (
            db.query(Report).filter(Report.status == ReportStatus.UNDER_REPAIR).count()
        )
        resolved_cnt = (
            db.query(Report).filter(Report.status == ReportStatus.RESOLVED).count()
        )

        # Priority breakdown
        priorities = (
            db.query(Report.priority, func.count(Report.id))
            .group_by(Report.priority)
            .all()
        )
        priority_counts = {p: 0 for p in ReportPriority.ALL}
        for p, count in priorities:
            if p in priority_counts:
                priority_counts[p] = count

        # Top wilayas
        wilayas = (
            db.query(
                Report.wilaya_code,
                Report.wilaya_name,
                func.count(Report.id).label("cnt"),
            )
            .filter(Report.wilaya_name.isnot(None))
            .group_by(Report.wilaya_code, Report.wilaya_name)
            .order_by(desc("cnt"))
            .limit(10)
            .all()
        )
        top_wilayas = [
            {"wilaya_code": w[0], "wilaya_name": w[1], "count": w[2]} for w in wilayas
        ]

        # Recent reports (5 latest)
        recent = db.query(Report).order_by(desc(Report.created_at)).limit(5).all()

        # Map preview (up to 50 active reports)
        map_preview = (
            db.query(Report)
            .filter(Report.status != ReportStatus.RESOLVED)
            .order_by(desc(Report.created_at))
            .limit(50)
            .all()
        )

        return {
            "total_reports": total,
            "new_reports": new_cnt,
            "verified_reports": verified_cnt,
            "assigned_reports": assigned_cnt,
            "under_repair_reports": under_repair_cnt,
            "resolved_reports": resolved_cnt,
            "priority_counts": priority_counts,
            "top_wilayas": top_wilayas,
            "recent_reports": recent,
            "map_preview": map_preview,
        }


report_service = ReportService()
