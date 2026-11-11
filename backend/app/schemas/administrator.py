from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, EmailStr, ConfigDict


class AdministratorBase(BaseModel):
    name: str
    email: EmailStr
    role: str = "ADMIN"
    is_active: bool = True
    approval_status: str = "APPROVED"
    signup_source: str = "EMAIL"


class AdministratorCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: Optional[str] = "ADMIN"
    is_active: Optional[bool] = True
    approval_status: Optional[str] = "APPROVED"


class AdministratorSignupRequest(BaseModel):
    name: str
    email: EmailStr
    password: str


class AdministratorUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None
    approval_status: Optional[str] = None
    password: Optional[str] = None


class AdministratorProfileUpdate(BaseModel):
    name: Optional[str] = None
    password: Optional[str] = None


class AdministratorApprovalAction(BaseModel):
    action: str  # "APPROVE" or "REJECT"
    role: Optional[str] = "ADMIN"


class AdministratorResponse(AdministratorBase):
    id: UUID
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
