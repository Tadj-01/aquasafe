from typing import Dict, List, Optional
from pydantic import BaseModel
from app.schemas.report import ReportMapItem, ReportResponse


class WilayaCount(BaseModel):
    wilaya_code: Optional[str] = None
    wilaya_name: Optional[str] = None
    count: int


class DashboardStatistics(BaseModel):
    total_reports: int
    new_reports: int
    verified_reports: int
    assigned_reports: int
    under_repair_reports: int
    resolved_reports: int
    priority_counts: Dict[str, int]
    top_wilayas: List[WilayaCount] = []
    recent_reports: List[ReportResponse] = []
    map_preview: List[ReportMapItem] = []
