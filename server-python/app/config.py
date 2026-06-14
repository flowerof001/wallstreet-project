"""Application configuration."""

import os
from typing import Optional


class Settings:
    APP_NAME: str = "Wallstreet"
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"

    # Database — 默认使用 SQLite（零配置），可通过环境变量切换 PostgreSQL
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "sqlite+aiosqlite:///./wallstreet.db",
    )

    # Redis（可选）
    REDIS_URL: str = os.getenv("REDIS_URL", "")

    # JWT
    JWT_SECRET: str = os.getenv("JWT_SECRET", "wallstreet-dev-secret-change-in-production")
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60 * 24 * 30  # 30 days

    # SMS (mock for development)
    SMS_PROVIDER: str = os.getenv("SMS_PROVIDER", "mock")

    # Market service
    MARKET_SERVICE_URL: str = os.getenv("MARKET_SERVICE_URL", "http://localhost:8080")

    # Admin account
    ADMIN_USERNAME: str = os.getenv("ADMIN_USERNAME", "admin")
    ADMIN_PASSWORD: str = os.getenv("ADMIN_PASSWORD", "admin123")


settings = Settings()
