from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Query, HTTPException, status
from app.services.geographic_service import geo_service

router = APIRouter(prefix="/geo", tags=["Geographic Data (Syscli Algeria)"])


@router.get("/wilayas", response_model=List[Dict[str, Any]])
def list_wilayas():
    """
    Get all 69 Algerian wilayas with official ONS codes, French and Arabic names.
    Powered by syscli-algeria.
    """
    return geo_service.get_all_wilayas()


@router.get("/wilayas/{wilaya_code}/communes", response_model=List[Dict[str, Any]])
def list_communes_for_wilaya(wilaya_code: str):
    """
    Get all communes belonging to a specific wilaya by ONS code.
    """
    communes = geo_service.get_communes_for_wilaya(wilaya_code)
    if not communes:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No communes found for wilaya code '{wilaya_code}'.",
        )
    return communes


@router.get("/search", response_model=List[Dict[str, Any]])
def search_locations(
    q: str = Query(..., min_length=1, description="Search query in French or Arabic"),
    limit: int = Query(10, ge=1, le=50),
):
    """
    Search communes and wilayas by name in French or Arabic, supporting spelling variants and typos.
    Powered by syscli-algeria.
    """
    return geo_service.search_locations(query=q, limit=limit)


@router.get("/lookup")
def lookup_coordinates(
    lat: float = Query(..., description="Latitude"),
    lng: float = Query(..., description="Longitude"),
):
    """
    Lookup Algerian administrative wilaya and commune for given GPS coordinates.
    """
    return geo_service.lookup_location(latitude=lat, longitude=lng)
