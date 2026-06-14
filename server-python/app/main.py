"""Wallstreet Python Server — 用户系统 + 管理后台 API + 实时行情

FastAPI application entry point.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import engine, Base
from app.routes import auth, user, admin, search, market, websocket


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: create tables + start market collector
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    websocket.start_collector()
    yield
    # Shutdown
    websocket.stop_collector()
    await engine.dispose()


app = FastAPI(
    title="Wallstreet API",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(user.router, prefix="/api/v1/user", tags=["User"])
app.include_router(admin.router, prefix="/api/v1/admin", tags=["Admin"])
app.include_router(search.router, prefix="/api/v1/search", tags=["Search"])
app.include_router(market.router, prefix="/api/v1", tags=["Market"])
app.include_router(websocket.router, tags=["WebSocket"])


@app.get("/health")
async def health():
    return {"status": "ok", "service": "wallstreet-python"}
