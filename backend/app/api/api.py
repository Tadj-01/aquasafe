from fastapi import APIRouter
from app.api.routes import auth, reports, dashboard, repair_teams, geo, administrators, routing

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(reports.router)
api_router.include_router(dashboard.router)
api_router.include_router(repair_teams.router)
api_router.include_router(geo.router)
api_router.include_router(administrators.router)
api_router.include_router(routing.router)
