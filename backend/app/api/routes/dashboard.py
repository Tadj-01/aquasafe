from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.dependencies.authentication import get_current_admin
from app.models.administrator import Administrator
from app.schemas.dashboard import DashboardStatistics
from app.services.report_service import report_service

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get(
    "/statistics",
    response_model=DashboardStatistics,
    summary="Get aggregated statistics for admin dashboard",
)
def get_dashboard_statistics(
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """
    Returns dashboard counts (total, new, verified, assigned, under repair, resolved),
    priority counts, top wilayas with leak reports, recent reports, and map preview points.
    All data comes from the backend database.
    """
    stats = report_service.get_dashboard_statistics(db)
    return stats
