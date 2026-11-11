from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests

from app.core.config import settings
from app.core.database import get_db
from app.core.security import verify_password, get_password_hash, create_access_token
from app.dependencies.authentication import get_current_admin
from app.models.administrator import Administrator
from app.schemas.administrator import (
    AdministratorResponse,
    AdministratorSignupRequest,
    AdministratorProfileUpdate,
)
from app.schemas.authentication import Token, LoginRequest, GoogleLoginRequest

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/signup", response_model=AdministratorResponse, status_code=status.HTTP_201_CREATED)
def admin_signup(signup_data: AdministratorSignupRequest, db: Session = Depends(get_db)):
    """
    Candidate administrator registration request.
    Creates account in PENDING approval status for the Supervisor to review and approve.
    """
    clean_email = signup_data.email.lower().strip()
    existing = db.query(Administrator).filter(Administrator.email == clean_email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email address already exists.",
        )

    new_admin = Administrator(
        name=signup_data.name.strip(),
        email=clean_email,
        password_hash=get_password_hash(signup_data.password),
        role="ADMIN",
        is_active=True,
        approval_status="PENDING",
        signup_source="EMAIL",
    )
    db.add(new_admin)
    db.commit()
    db.refresh(new_admin)
    return new_admin


@router.post("/login", response_model=Token)
def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    """
    Authenticate an administrator with email and password.
    Returns JWT access token.
    """
    admin = (
        db.query(Administrator)
        .filter(Administrator.email == login_data.email.lower().strip())
        .first()
    )
    if not admin or not verify_password(login_data.password, admin.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not admin.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Administrator account is inactive.",
        )
    if admin.approval_status == "PENDING":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your administrator registration is currently PENDING review by the system supervisor.",
        )
    if admin.approval_status == "REJECTED":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your administrator registration request was not approved by the supervisor.",
        )

    access_token = create_access_token(
        subject=str(admin.id),
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/google", response_model=Token)
def google_login(login_data: GoogleLoginRequest, db: Session = Depends(get_db)):
    """
    Authenticate or register an administrator using Google OAuth ID token.
    If the email is new, it automatically registers in PENDING state for supervisor review!
    """
    token_str = login_data.id_token.strip()
    email = None
    name = "Google User"

    try:
        idinfo = google_id_token.verify_oauth2_token(
            token_str, google_requests.Request()
        )
        email = idinfo.get("email")
        name = idinfo.get("name") or idinfo.get("given_name") or "Google User"
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Google ID token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google token does not contain a verified email address.",
        )

    clean_email = email.lower().strip()
    admin = (
        db.query(Administrator)
        .filter(Administrator.email == clean_email)
        .first()
    )

    # If the user doesn't exist, create a pending candidate account
    if not admin:
        import secrets
        random_pw = secrets.token_urlsafe(32)
        admin = Administrator(
            name=name,
            email=clean_email,
            password_hash=get_password_hash(random_pw),
            role="ADMIN",
            is_active=True,
            approval_status="PENDING",
            signup_source="GOOGLE",
        )
        db.add(admin)
        db.commit()
        db.refresh(admin)

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Google account '{clean_email}' registered as candidate administrator! Waiting for supervisor approval before login.",
        )

    if not admin.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Administrator account is inactive.",
        )
    if admin.approval_status == "PENDING":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your administrator registration is currently PENDING review by the system supervisor.",
        )
    if admin.approval_status == "REJECTED":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your administrator registration request was not approved by the supervisor.",
        )

    access_token = create_access_token(
        subject=str(admin.id),
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return {"access_token": access_token, "token_type": "bearer"}


@router.get("/me", response_model=AdministratorResponse)
def read_current_admin(
    current_admin: Administrator = Depends(get_current_admin),
):
    """
    Get profile information of the currently authenticated administrator.
    """
    return current_admin


@router.patch("/profile", response_model=AdministratorResponse)
def update_profile(
    profile_data: AdministratorProfileUpdate,
    db: Session = Depends(get_db),
    current_admin: Administrator = Depends(get_current_admin),
):
    """
    Update personal profile information (name, password).
    """
    if profile_data.name is not None and profile_data.name.strip():
        current_admin.name = profile_data.name.strip()
    if profile_data.password is not None and len(profile_data.password) >= 6:
        current_admin.password_hash = get_password_hash(profile_data.password)

    db.commit()
    db.refresh(current_admin)
    return current_admin


@router.post("/refresh", response_model=Token)
def refresh_token(
    current_admin: Administrator = Depends(get_current_admin),
):
    """
    Refresh current administrator's JWT access token.
    """
    access_token = create_access_token(
        subject=str(current_admin.id),
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return {"access_token": access_token, "token_type": "bearer"}
