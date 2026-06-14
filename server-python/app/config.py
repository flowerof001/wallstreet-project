"""Application configuration."""
import os

class Settings:
    APP_NAME: str = "Wallstreet"
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"
    JWT_SECRET: str = os.getenv("JWT_SECRET", "wallstreet-dev-secret-change-in-production")
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60 * 24 * 30
    SMS_PROVIDER: str = os.getenv("SMS_PROVIDER", "mock")
    MARKET_SERVICE_URL: str = os.getenv("MARKET_SERVICE_URL", "")
    ADMIN_USERNAME: str = os.getenv("ADMIN_USERNAME", "admin")
    ADMIN_PASSWORD: str = os.getenv("ADMIN_PASSWORD", "admin123")

settings = Settings()
