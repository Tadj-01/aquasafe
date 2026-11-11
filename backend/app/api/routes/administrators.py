from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_password_hash
from app.dependencies.authentication import get_current_admin, get_current_supervisor
from app.models.administrator import Administrator
from app.schemas.administrator import (
    AdministratorResponse,
    AdministratorCreate,
    AdministratorUpdate,
    AdministratorApprovalAction,
)

router = APIRouter(prefix="/administrators", tags=["Administrators"])


@router.get("", response_model=List[AdministratorResponse])
def list_administrators(
    status_filter: Optional[str] = Query(None, description="PENDING, APPROVED, REJECTED, or ALL"),
    db: Session = Depends(get_db),
    supervisor: Administrator = Depends(get_current_supervisor),
):
    """
    List all administrator accounts and applicants.
    Exclusive to the SUPERVISOR.
    """
    query = db.query(Administrator)
    if status_filter and status_filter.upper() != "ALL":
        query = query.filter(Administrator.approval_status == status_filter.upper())
    return query.order_by(Administrator.created_at.desc()).all()


@router.get("/pending-count")
def get_pending_count(
    db: Session = Depends(get_db),
    supervisor: Administrator = Depends(get_current_supervisor),
):
    """Get count of pending candidate administrators."""
    count = db.query(Administrator).filter(Administrator.approval_status == "PENDING").count()
    return {"pending_count": count}


@router.get("/{admin_id}", response_model=AdministratorResponse)
def get_administrator(
    admin_id: UUID,
    db: Session = Depends(get_db),
    supervisor: Administrator = Depends(get_current_supervisor),
):
    """Get a specific administrator's details."""
    admin = db.query(Administrator).filter(Administrator.id == admin_id).first()
    if not admin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Administrator '{admin_id}' not found.",
        )
    return admin


@router.post("", response_model=AdministratorResponse, status_code=status.HTTP_201_CREATED)
def create_administrator(
    admin_in: AdministratorCreate,
    db: Session = Depends(get_db),
    supervisor: Administrator = Depends(get_current_supervisor),
):
    """
    Directly provision a new administrator account (Approved by default).
    Exclusive to SUPERVISOR.
    """
    existing = (
        db.query(Administrator)
        .filter(Administrator.email == admin_in.email.lower().strip())
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An administrator with this email already exists.",
        )

    new_admin = Administrator(
        name=admin_in.name.strip(),
        email=admin_in.email.lower().strip(),
        password_hash=get_password_hash(admin_in.password),
        role=admin_in.role or "ADMIN",
        is_active=admin_in.is_active if admin_in.is_active is not None else True,
        approval_status=admin_in.approval_status or "APPROVED",
        signup_source="MANUAL_PROVISION",
    )
    db.add(new_admin)
    db.commit()
    db.refresh(new_admin)
    return new_admin


@router.patch("/{admin_id}", response_model=AdministratorResponse)
def update_administrator(
    admin_id: UUID,
    admin_in: AdministratorUpdate,
    db: Session = Depends(get_db),
    supervisor: Administrator = Depends(get_current_supervisor),
):
    """Update administrator details, role, status or active state."""
    admin = db.query(Administrator).filter(Administrator.id == admin_id).first()
    if not admin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Administrator '{admin_id}' not found.",
        )

    # Protect supervisor from self-demoting to non-supervisor or locking themselves out
    if admin.id == supervisor.id:
        if admin_in.is_active is False:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot deactivate your own supervisor account.",
            )
        if admin_in.role and admin_in.role.upper() != "SUPERVISOR":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot revoke your own supervisor role.",
            )

    update_data = admin_in.model_dump(exclude_unset=True)
    if "password" in update_data and update_data["password"]:
        admin.password_hash = get_password_hash(update_data.pop("password"))

    for field, value in update_data.items():
        setattr(admin, field, value)

    db.commit()
    db.refresh(admin)
    return admin


@router.post("/{admin_id}/decision", response_model=AdministratorResponse)
def review_admin_application(
    admin_id: UUID,
    decision: AdministratorApprovalAction,
    db: Session = Depends(get_db),
    supervisor: Administrator = Depends(get_current_supervisor),
):
    """
    Approve or Reject a candidate administrator registration (from email signup or Google).
    """
    admin = db.query(Administrator).filter(Administrator.id == admin_id).first()
    if not admin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Administrator application '{admin_id}' not found.",
        )

    if decision.action.upper() == "APPROVE":
        admin.approval_status = "APPROVED"
        admin.is_active = True
        if decision.role:
            admin.role = decision.role.upper()
    elif decision.action.upper() == "REJECT":
        admin.approval_status = "REJECTED"
        admin.is_active = False
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Action must be 'APPROVE' or 'REJECT'.",
        )

    db.commit()
    db.refresh(admin)
    return admin


@router.delete("/{admin_id}", status_code=status.HTTP_200_OK)
def delete_administrator(
    admin_id: UUID,
    db: Session = Depends(get_db),
    supervisor: Administrator = Depends(get_current_supervisor),
):
    """Delete an administrator account."""
    if admin_id == supervisor.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot delete your own supervisor account.",
        )

    admin = db.query(Administrator).filter(Administrator.id == admin_id).first()
    if not admin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Administrator '{admin_id}' not found.",
        )

    db.delete(admin)
    db.commit()
    return {"message": f"Administrator '{admin.name}' deleted successfully."}
