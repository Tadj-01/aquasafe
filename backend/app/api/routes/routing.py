from fastapi import APIRouter, HTTPException, Query, status
import httpx

router = APIRouter(prefix="/routing", tags=["Routing"])


@router.get("/route")
async def get_route(
    from_lat: float = Query(..., description="Origin latitude"),
    from_lng: float = Query(..., description="Origin longitude"),
    to_lat: float = Query(..., description="Destination latitude"),
    to_lng: float = Query(..., description="Destination longitude"),
):
    """
    Get driving route between two points using open-source OSRM routing.
    Returns polyline coordinates, distance in km, and duration in minutes.
    """
    osrm_url = (
        f"http://router.project-osrm.org/route/v1/driving/"
        f"{from_lng},{from_lat};{to_lng},{to_lat}"
        f"?overview=full&geometries=geojson"
    )

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(osrm_url)
            if resp.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail="Routing service returned an error",
                )
            data = resp.json()
            if not data.get("routes"):
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="No route found between coordinates",
                )

            route = data["routes"][0]
            coordinates = route["geometry"]["coordinates"]  # [[lng, lat], ...]
            # Format as [[lat, lng], ...] for mobile maps
            lat_lng_points = [[coord[1], coord[0]] for coord in coordinates]

            distance_km = round(route["distance"] / 1000.0, 2)
            duration_minutes = round(route["duration"] / 60.0, 1)

            return {
                "points": lat_lng_points,
                "distance_km": distance_km,
                "duration_minutes": duration_minutes,
            }
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Unable to contact routing engine: {str(exc)}",
        )
