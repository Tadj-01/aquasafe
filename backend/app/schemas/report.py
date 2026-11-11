from datetime import datetime
from typing import Optional, List
from uuid import UUID
from pydantic import BaseModel, Field, ConfigDict
from app.schemas.repair_team import RepairTeamResponse


class StatusHistoryResponse(BaseModel):
    id: UUID
    report_id: UUID
    old_status: Optional[str] = None
    new_status: str
    changed_by: Optional[UUID] = None
    changed_at: datetime
    note: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class ReportPublicConfirmation(BaseModel):
    id: UUID
    status: str
    priority: str
    latitude: float
    longitude: float
    wilaya_code: Optional[str] = None
    wilaya_name: Optional[str] = None
    commune_code: Optional[str] = None
    commune_name: Optional[str] = None
    created_at: datetime
    message: str = "Report submitted successfully."

    model_config = ConfigDict(from_attributes=True)


class ReportPublicStatus(BaseModel):
    id: UUID
    status: str
    priority: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class ReportMapItem(BaseModel):
    id: UUID
    latitude: float
    longitude: float
    photo_url: str
    note: Optional[str] = None
    status: str
    priority: str
    wilaya_name: Optional[str] = None
    commune_name: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ReportResponse(BaseModel):
    id: UUID
    latitude: float
    longitude: float
    gps_accuracy: Optional[float] = None
    photo_url: str
    note: Optional[str] = None
    wilaya_code: Optional[str] = None
    wilaya_name: Optional[str] = None
    commune_code: Optional[str] = None
    commune_name: Optional[str] = None
    status: str
    priority: str
    assigned_team_id: Optional[UUID] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    assigned_team: Optional[RepairTeamResponse] = None
    status_history: List[StatusHistoryResponse] = []

    model_config = ConfigDict(from_attributes=True)


class ReportStatusUpdate(BaseModel):
    status: str = Field(..., description="NEW, VERIFIED, ASSIGNED, UNDER_REPAIR, RESOLVED")
    note: Optional[str] = None


class ReportPriorityUpdate(BaseModel):
    priority: str = Field(..., description="NORMAL, HIGH, CRITICAL")
    note: Optional[str] = None


class ReportAssignmentUpdate(BaseModel):
    assigned_team_id: Optional[UUID] = None
    note: Optional[str] = None
