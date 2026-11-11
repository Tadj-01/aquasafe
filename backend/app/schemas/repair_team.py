from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict


class RepairTeamBase(BaseModel):
    name: str
    description: Optional[str] = None
    phone: Optional[str] = None
    is_active: bool = True
    leader_name: Optional[str] = None
    leader_phone: Optional[str] = None
    wilaya_code: Optional[str] = None
    wilaya_name: Optional[str] = None
    commune_code: Optional[str] = None
    commune_name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    specialization: Optional[str] = None
    members_count: Optional[int] = 1


class RepairTeamCreate(RepairTeamBase):
    pass


class RepairTeamUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    phone: Optional[str] = None
    is_active: Optional[bool] = None
    leader_name: Optional[str] = None
    leader_phone: Optional[str] = None
    wilaya_code: Optional[str] = None
    wilaya_name: Optional[str] = None
    commune_code: Optional[str] = None
    commune_name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    specialization: Optional[str] = None
    members_count: Optional[int] = None


class RepairTeamResponse(RepairTeamBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
