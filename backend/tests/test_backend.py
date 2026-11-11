import io
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import verify_password
from app.services.geographic_service import geo_service

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_geo_service_wilayas():
    wilayas = geo_service.get_all_wilayas()
    assert len(wilayas) == 69
    # Check Algiers
    algiers = next((w for w in wilayas if w["code"] == "16"), None)
    assert algiers is not None
    assert algiers["name_fr"] == "Alger"
    assert "الجزائر" in algiers["name_ar"]


def test_geo_service_lookup_algiers():
    # Place des Martyrs, Algiers
    res = geo_service.lookup_location(36.785, 3.060)
    assert res["wilaya_code"] == "16"
    assert res["wilaya_name"] == "Alger"
    assert res["commune_code"] is not None


def test_geo_service_lookup_oran():
    # Oran city center
    res = geo_service.lookup_location(35.698, -0.634)
    assert res["wilaya_code"] == "31"
    assert res["wilaya_name"] == "Oran"


def test_geo_service_lookup_outside_algeria():
    # Paris coordinates
    res = geo_service.lookup_location(48.8566, 2.3522)
    assert res["wilaya_code"] is None
    assert res["wilaya_name"] is None


def test_admin_login_success():
    response = client.post(
        "/api/auth/login",
        json={"email": "admin@aquasafe.dz", "password": "AquaSafe2026!"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_admin_login_invalid_password():
    response = client.post(
        "/api/auth/login",
        json={"email": "admin@aquasafe.dz", "password": "wrongpassword"},
    )
    assert response.status_code == 401


def test_citizen_report_submission_and_workflow():
    # 1. Citizen submits report without auth
    test_image_bytes = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15c4\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"
    file = ("leak_test.png", io.BytesIO(test_image_bytes), "image/png")

    post_resp = client.post(
        "/api/reports",
        data={
            "latitude": 36.7538,
            "longitude": 3.0588,
            "gps_accuracy": 4.5,
            "note": "Major pipe burst on the sidewalk",
        },
        files={"photo": file},
    )
    assert post_resp.status_code == 201
    rep_data = post_resp.json()
    report_id = rep_data["id"]
    assert rep_data["status"] == "NEW"
    assert rep_data["priority"] == "NORMAL"
    assert rep_data["wilaya_code"] == "16"
    assert rep_data["wilaya_name"] == "Alger"

    # 2. Check public status as citizen
    pub_resp = client.get(f"/api/reports/{report_id}/public-status")
    assert pub_resp.status_code == 200
    assert pub_resp.json()["status"] == "NEW"

    # 3. Admin login
    auth_resp = client.post(
        "/api/auth/login",
        json={"email": "admin@aquasafe.dz", "password": "AquaSafe2026!"},
    )
    token = auth_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 4. Admin views report details
    det_resp = client.get(f"/api/reports/{report_id}", headers=headers)
    assert det_resp.status_code == 200
    assert det_resp.json()["note"] == "Major pipe burst on the sidewalk"

    # 5. Admin updates status to VERIFIED
    patch_resp = client.patch(
        f"/api/reports/{report_id}/status",
        json={"status": "VERIFIED", "note": "Leak confirmed on site by inspection."},
        headers=headers,
    )
    assert patch_resp.status_code == 200
    assert patch_resp.json()["status"] == "VERIFIED"

    # 6. Admin updates priority to CRITICAL
    prio_resp = client.patch(
        f"/api/reports/{report_id}/priority",
        json={"priority": "CRITICAL", "note": "High water loss volume."},
        headers=headers,
    )
    assert prio_resp.status_code == 200
    assert prio_resp.json()["priority"] == "CRITICAL"

    # 7. Check audit history
    hist_resp = client.get(f"/api/reports/{report_id}/history", headers=headers)
    assert hist_resp.status_code == 200
    history = hist_resp.json()
    assert len(history) >= 2  # initial + verified

    # 8. Check dashboard statistics
    dash_resp = client.get("/api/dashboard/statistics", headers=headers)
    assert dash_resp.status_code == 200
    dash_data = dash_resp.json()
    assert dash_data["total_reports"] >= 1
    assert dash_data["verified_reports"] >= 1
    assert dash_data["priority_counts"]["CRITICAL"] >= 1

    # 9. Check map reports endpoint
    map_resp = client.get("/api/reports/map", headers=headers)
    assert map_resp.status_code == 200
    map_points = map_resp.json()
    assert any(p["id"] == report_id for p in map_points)
