import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.core.database import Base


class AdminRole:
    SUPERVISOR = "SUPERVISOR"
    ADMIN = "ADMIN"

    ALL = [SUPERVISOR, ADMIN]


class AdminApprovalStatus:
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"

    ALL = [PENDING, APPROVED, REJECTED]


class Administrator(Base):
    __tablename__ = "administrators"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(50), default="ADMIN", nullable=False)  # SUPERVISOR or ADMIN
    is_active = Column(Boolean, default=True, nullable=False)

    # Supervisor governance fields
    approval_status = Column(
        String(50), default="APPROVED", nullable=False, index=True
    )  # APPROVED, PENDING, REJECTED
    signup_source = Column(
        String(50), default="EMAIL", nullable=False
    )  # EMAIL or GOOGLE

    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    status_changes = relationship("StatusHistory", back_populates="administrator")
