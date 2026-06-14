"""Application configuration."""

import os
from typing import Optional


class Settings:
    APP_NAME: str = "Wallstreet"
    DEBUG: bool = os.getenv("DEBUG", "true").lower() == "true"

    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql+asyncpg://postgres:postgres@localhost:5432/wallstreet",
    )

    # Redis
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379")

    # JWT
    JWT_SECRET: str = os.getenv("JWT_SECRET", "dev-secret-change-in-production")
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60 * 24 * 30  # 30 days

    # SMS (mock for development)
    SMS_PROVIDER: str = os.getenv("SMS_PROVIDER", "mock")

    # Go market data service
    MARKET_SERVICE_URL: str = os.getenv("MARKET_SERVICE_URL", "http://localhost:8080")

    # Admin account
    ADMIN_USERNAME: str = os.getenv("ADMIN_USERNAME", "admin")
    ADMIN_PASSWORD: str = os.getenv("ADMIN_PASSWORD", "admin123")


settings = Settings()
