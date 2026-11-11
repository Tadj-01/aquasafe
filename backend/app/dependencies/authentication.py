from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.database import get_db
from app.models.administrator import Administrator
from app.schemas.authentication import TokenData

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/auth/login"
)


def get_current_admin(
    db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)
) -> Administrator:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        admin_id: Optional[str] = payload.get("sub")
        if admin_id is None:
            raise credentials_exception
        token_data = TokenData(admin_id=admin_id)
    except JWTError:
        raise credentials_exception

    admin = (
        db.query(Administrator)
        .filter(Administrator.id == token_data.admin_id)
        .first()
    )
    if admin is None:
        raise credentials_exception
    if not admin.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Inactive administrator account"
        )
    if admin.approval_status != "APPROVED":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Administrator account is {admin.approval_status.lower()}. Awaiting supervisor approval.",
        )
    return admin


def get_current_supervisor(
    current_admin: Administrator = Depends(get_current_admin),
) -> Administrator:
    """
    Ensure the current administrator holds the SUPERVISOR role.
    """
    if current_admin.role.upper() != "SUPERVISOR":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operation requires SUPERVISOR administrator privileges.",
        )
    return current_admin
