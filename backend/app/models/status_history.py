import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base


class StatusHistory(Base):
    __tablename__ = "status_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    report_id = Column(
        UUID(as_uuid=True),
        ForeignKey("reports.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    old_status = Column(String(50), nullable=True)
    new_status = Column(String(50), nullable=False)
    changed_by = Column(
        UUID(as_uuid=True),
        ForeignKey("administrators.id", ondelete="SET NULL"),
        nullable=True,
    )
    changed_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    note = Column(Text, nullable=True)

    report = relationship("Report", back_populates="status_history")
    administrator = relationship("Administrator", back_populates="status_changes")
