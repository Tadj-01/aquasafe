import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Boolean, DateTime, Float, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base


class RepairTeam(Base):
    __tablename__ = "repair_teams"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    phone = Column(String(50), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)

    # Enhanced fields
    leader_name = Column(String(255), nullable=True)
    leader_phone = Column(String(50), nullable=True)
    wilaya_code = Column(String(10), nullable=True, index=True)
    wilaya_name = Column(String(100), nullable=True)
    commune_code = Column(String(10), nullable=True)
    commune_name = Column(String(100), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    specialization = Column(String(100), nullable=True)
    members_count = Column(Integer, default=1, nullable=True)

    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    reports = relationship("Report", back_populates="assigned_team")
