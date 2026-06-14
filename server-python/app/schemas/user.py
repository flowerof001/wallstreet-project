"""Pydantic schemas for request/response validation."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


# ============ Auth ============

class SendCodeRequest(BaseModel):
    country_code: str = Field(default="+86", max_length=10)
    phone: str = Field(max_length=20)

class SendCodeResponse(BaseModel):
    success: bool
    message: str = "验证码已发送"

class LoginRequest(BaseModel):
    country_code: str = Field(max_length=10)
    phone: str = Field(max_length=20)
    code: str = Field(max_length=6)

class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"

class AdminLoginRequest(BaseModel):
    username: str
    password: str

# ============ User ============

class UserResponse(BaseModel):
    user_id: str
    phone: str
    country_code: str
    email: Optional[str] = None
    country: Optional[str] = None
    is_active: bool
    is_admin: bool
    watchlist: list[str] = []
    created_at: datetime
    last_login_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class ChangePasswordRequest(BaseModel):
    old_password: Optional[str] = None  # None if never set
    new_password: str = Field(min_length=6, max_length=32)
    confirm_password: str = Field(min_length=6, max_length=32)

class UpdateUserRequest(BaseModel):
    phone: Optional[str] = None
    email: Optional[str] = None
    country: Optional[str] = None
    country_code: Optional[str] = None
    is_active: Optional[bool] = None

# ============ Watchlist ============

class WatchlistUpdate(BaseModel):
    codes: list[str]

# ============ Market Page ============

class StockCardSchema(BaseModel):
    card_id: str
    stock_code: str
    width: float = 400
    height: float = 300
    position: int = 0
    chart_type: str = "time_sharing"

class MarketPageCreate(BaseModel):
    name: str

class MarketPageResponse(BaseModel):
    page_id: str
    name: str
    layout_columns: int
    cards: list[StockCardSchema] = []

class CardAddRequest(BaseModel):
    stock_code: str
    stock_name: Optional[str] = None

class CardUpdateRequest(BaseModel):
    width: Optional[float] = None
    height: Optional[float] = None
    position: Optional[int] = None
    chart_type: Optional[str] = None

# ============ Stock Search ============

class StockSearchResult(BaseModel):
    code: str
    name: str
    market: str

class StockSearchResponse(BaseModel):
    results: list[StockSearchResult]

# ============ Admin ============

class AdminUserListResponse(BaseModel):
    total: int
    users: list[UserResponse]

# Forward references
LoginResponse.model_rebuild()
