import os
from typing import List, Union, Optional, Any
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "AquaSafe API"
    API_V1_STR: str = "/api"
    SECRET_KEY: str = "default_secret_key_change_me_in_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours

    POSTGRES_SERVER: str = "localhost"
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "20050114"
    POSTGRES_DB: str = "lyna_app"
    POSTGRES_PORT: int = 5432
    DATABASE_URL: str = "postgresql+psycopg2://postgres:20050114@localhost:5432/lyna_app"

    @field_validator("DATABASE_URL", mode="before")
    def assemble_db_connection(cls, v: Optional[str]) -> Any:
        if isinstance(v, str):
            if v.startswith("postgresql://"):
                return v.replace("postgresql://", "postgresql+psycopg2://", 1)
            return v
        return v

    UPLOAD_DIR: str = "uploads"
    BASE_URL: str = "http://localhost:8000"

    BACKEND_CORS_ORIGINS: List[str] = ["*"]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )


settings = Settings()
