from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.authentication import get_current_admin
from app.models.administrator import Administrator
from app.models.repair_team import RepairTeam
from app.models.report import Report
from app.schemas.repair_team import (
    RepairTeamResponse,
    RepairTeamCreate,
    RepairTeamUpdate,
)

router = APIRouter(prefix="/repair-teams", tags=["Repair Teams"])


@router.get("", response_model=List[RepairTeamResponse])
def list_repair_teams(
    active_only: Optional[bool] = False,
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """List all repair teams."""
    query = db.query(RepairTeam)
    if active_only:
        query = query.filter(RepairTeam.is_active == True)
    teams = query.order_by(RepairTeam.name.asc()).all()
    return teams


@router.get("/{team_id}", response_model=RepairTeamResponse)
def get_repair_team(
    team_id: UUID,
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """Get single repair team details."""
    team = db.query(RepairTeam).filter(RepairTeam.id == team_id).first()
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Repair team '{team_id}' not found.",
        )
    return team


@router.post("", response_model=RepairTeamResponse, status_code=status.HTTP_201_CREATED)
def create_repair_team(
    team_in: RepairTeamCreate,
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """Create a new repair team."""
    team = RepairTeam(
        name=team_in.name,
        description=team_in.description,
        phone=team_in.phone,
        is_active=team_in.is_active,
        leader_name=team_in.leader_name,
        leader_phone=team_in.leader_phone,
        wilaya_code=team_in.wilaya_code,
        wilaya_name=team_in.wilaya_name,
        commune_code=team_in.commune_code,
        commune_name=team_in.commune_name,
        latitude=team_in.latitude,
        longitude=team_in.longitude,
        specialization=team_in.specialization,
        members_count=team_in.members_count or 1,
    )
    db.add(team)
    db.commit()
    db.refresh(team)
    return team


@router.patch("/{team_id}", response_model=RepairTeamResponse)
def update_repair_team(
    team_id: UUID,
    team_in: RepairTeamUpdate,
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """Update a repair team."""
    team = db.query(RepairTeam).filter(RepairTeam.id == team_id).first()
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Repair team '{team_id}' not found.",
        )

    update_data = team_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(team, field, value)

    db.commit()
    db.refresh(team)
    return team


@router.delete("/{team_id}", status_code=status.HTTP_200_OK)
def delete_repair_team(
    team_id: UUID,
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """Delete or deactivate a repair team."""
    team = db.query(RepairTeam).filter(RepairTeam.id == team_id).first()
    if not team:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Repair team '{team_id}' not found.",
        )

    # Check if team is assigned to any reports
    assigned_count = db.query(Report).filter(Report.assigned_team_id == team_id).count()
    if assigned_count > 0:
        # Soft delete
        team.is_active = False
        db.commit()
        return {"message": f"Team has {assigned_count} linked reports and was deactivated instead of deleted.", "deactivated": True}

    db.delete(team)
    db.commit()
    return {"message": "Repair team deleted successfully.", "deleted": True}
