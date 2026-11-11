import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Float, Text, DateTime, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base


class ReportStatus:
    NEW = "NEW"
    VERIFIED = "VERIFIED"
    ASSIGNED = "ASSIGNED"
    UNDER_REPAIR = "UNDER_REPAIR"
    RESOLVED = "RESOLVED"

    ALL = [NEW, VERIFIED, ASSIGNED, UNDER_REPAIR, RESOLVED]


class ReportPriority:
    NORMAL = "NORMAL"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"

    ALL = [NORMAL, HIGH, CRITICAL]


class Report(Base):
    __tablename__ = "reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    gps_accuracy = Column(Float, nullable=True)
    photo_url = Column(Text, nullable=False)
    note = Column(Text, nullable=True)

    wilaya_code = Column(String(10), nullable=True, index=True)
    wilaya_name = Column(String(100), nullable=True)
    commune_code = Column(String(10), nullable=True, index=True)
    commune_name = Column(String(100), nullable=True)

    status = Column(String(50), default=ReportStatus.NEW, nullable=False, index=True)
    priority = Column(String(50), default=ReportPriority.NORMAL, nullable=False, index=True)

    assigned_team_id = Column(
        UUID(as_uuid=True),
        ForeignKey("repair_teams.id", ondelete="SET NULL"),
        nullable=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        index=True,
    )
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=True,
    )

    assigned_team = relationship("RepairTeam", back_populates="reports")
    status_history = relationship(
        "StatusHistory",
        back_populates="report",
        cascade="all, delete-orphan",
        order_by="StatusHistory.changed_at.desc()",
    )

    __table_args__ = (
        Index("idx_reports_coords", "latitude", "longitude"),
        Index("idx_reports_status_priority", "status", "priority"),
    )
