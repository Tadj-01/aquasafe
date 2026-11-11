from datetime import datetime
from typing import List, Optional
from uuid import UUID
from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    UploadFile,
    Query,
    status,
)
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.authentication import get_current_admin
from app.models.administrator import Administrator
from app.schemas.report import (
    ReportResponse,
    ReportPublicConfirmation,
    ReportPublicStatus,
    ReportMapItem,
    ReportStatusUpdate,
    ReportPriorityUpdate,
    ReportAssignmentUpdate,
    StatusHistoryResponse,
)
from app.services.storage_service import storage_service
from app.services.report_service import report_service

router = APIRouter(prefix="/reports", tags=["Reports"])


# ============================================================
# PUBLIC CITIZEN ENDPOINTS
# ============================================================


@router.post(
    "",
    response_model=ReportPublicConfirmation,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a water leak report (Citizen, no auth required)",
)
async def submit_report(
    latitude: float = Form(..., description="GPS Latitude (-90 to 90)"),
    longitude: float = Form(..., description="GPS Longitude (-180 to 180)"),
    gps_accuracy: Optional[float] = Form(None, description="GPS accuracy in meters"),
    note: Optional[str] = Form(None, description="Optional citizen notes/description"),
    photo: UploadFile = File(..., description="Photograph of the leak"),
    db: Session = Depends(get_db),
):
    """
    Citizens can report water leaks immediately without creating accounts.
    Coordinates are validated, administrative Wilaya/Commune are identified using Syscli Algeria,
    and the photo is securely stored.
    """
    # 1. Store photograph
    photo_url = await storage_service.save_upload_file(photo)

    # 2. Create report
    report = report_service.create_report(
        db=db,
        latitude=latitude,
        longitude=longitude,
        photo_url=photo_url,
        gps_accuracy=gps_accuracy,
        note=note,
    )

    return report


@router.get(
    "/{report_id}/public-status",
    response_model=ReportPublicStatus,
    summary="Get limited public status of a report by ID",
)
def get_public_report_status(
    report_id: UUID,
    db: Session = Depends(get_db),
):
    """
    Allows citizens to check limited public status of their submitted report
    using the unique report reference ID without authentication.
    """
    report = report_service.get_report_by_id(db, report_id)
    return report


# ============================================================
# ADMINISTRATOR MANAGEMENT ENDPOINTS (PROTECTED)
# ============================================================


@router.get(
    "",
    response_model=List[ReportResponse],
    summary="List all reports with filtering and search (Admin)",
)
def list_reports(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    status: Optional[str] = Query(None, description="NEW, VERIFIED, ASSIGNED, UNDER_REPAIR, RESOLVED"),
    priority: Optional[str] = Query(None, description="NORMAL, HIGH, CRITICAL"),
    wilaya_code: Optional[str] = Query(None, description="Filter by 2-digit Wilaya ONS code"),
    commune_code: Optional[str] = Query(None, description="Filter by Commune code"),
    search: Optional[str] = Query(None, description="Search term for note or location"),
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """
    Retrieve reports list with pagination, filtering by status, priority, wilaya, commune, date, and search.
    Protected for authorized administrators.
    """
    reports = report_service.list_reports(
        db=db,
        skip=skip,
        limit=limit,
        status=status,
        priority=priority,
        wilaya_code=wilaya_code,
        commune_code=commune_code,
        search_query=search,
        start_date=start_date,
        end_date=end_date,
    )
    return reports


@router.get(
    "/map",
    response_model=List[ReportMapItem],
    summary="Get report markers for interactive map (Admin)",
)
def get_map_reports(
    status: Optional[str] = Query(None, description="Filter by status or 'ALL'"),
    wilaya_code: Optional[str] = Query(None, description="Filter by wilaya code"),
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """
    Returns coordinate markers for Google Maps display.
    """
    reports = report_service.get_map_reports(
        db=db, status=status, wilaya_code=wilaya_code
    )
    return reports


@router.get(
    "/{report_id}",
    response_model=ReportResponse,
    summary="Get full details of a specific report (Admin)",
)
def get_report_details(
    report_id: UUID,
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """
    Get complete details of a leak report including history and assigned team.
    """
    report = report_service.get_report_by_id(db, report_id)
    return report


@router.get(
    "/{report_id}/history",
    response_model=List[StatusHistoryResponse],
    summary="Get status change history of a report (Admin)",
)
def get_report_history(
    report_id: UUID,
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """
    Get complete status transition audit log for a report.
    """
    report = report_service.get_report_by_id(db, report_id)
    return report.status_history


@router.patch(
    "/{report_id}/status",
    response_model=ReportResponse,
    summary="Update report status (Admin)",
)
def update_report_status(
    report_id: UUID,
    payload: ReportStatusUpdate,
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """
    Update report status (NEW, VERIFIED, ASSIGNED, UNDER_REPAIR, RESOLVED)
    and records the change in status history.
    """
    report = report_service.update_status(
        db=db,
        report_id=report_id,
        new_status=payload.status,
        admin=current_admin,
        note=payload.note,
    )
    return report


@router.patch(
    "/{report_id}/priority",
    response_model=ReportResponse,
    summary="Update report priority (Admin)",
)
def update_report_priority(
    report_id: UUID,
    payload: ReportPriorityUpdate,
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """
    Update report priority (NORMAL, HIGH, CRITICAL).
    """
    report = report_service.update_priority(
        db=db,
        report_id=report_id,
        new_priority=payload.priority,
        admin=current_admin,
        note=payload.note,
    )
    return report


@router.patch(
    "/{report_id}/assignment",
    response_model=ReportResponse,
    summary="Assign a repair team to report (Admin)",
)
def assign_repair_team(
    report_id: UUID,
    payload: ReportAssignmentUpdate,
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """
    Assign or unassign a repair team to the report.
    """
    report = report_service.assign_repair_team(
        db=db,
        report_id=report_id,
        assigned_team_id=payload.assigned_team_id,
        admin=current_admin,
        note=payload.note,
    )
    return report
