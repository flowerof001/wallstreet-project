"""Auth routes: login, register, send code."""
import secrets
from fastapi import APIRouter, HTTPException
from app.schemas.user import SendCodeRequest, SendCodeResponse, LoginRequest, LoginResponse, UserResponse, AdminLoginRequest
from app.services.auth import create_access_token
from app.services.sms import get_sms_provider, generate_code
from app.config import settings
from app.store import _store, User

router = APIRouter()
_verification_codes: dict[str, str] = {}

@router.post("/send-code", response_model=SendCodeResponse)
async def send_code(req: SendCodeRequest):
    code = generate_code()
    _verification_codes[f"{req.country_code}:{req.phone}"] = code
    provider = get_sms_provider()
    await provider.send_code(req.country_code, req.phone, code)
    return SendCodeResponse(success=True)

@router.post("/login", response_model=LoginResponse)
async def login(req: LoginRequest):
    key = f"{req.country_code}:{req.phone}"
    expected = _verification_codes.get(key)
    if not expected or req.code != expected:
        raise HTTPException(status_code=400, detail="验证码错误")
    _verification_codes.pop(key, None)

    # Find or create user
    user = next((u for u in _store.users if u.country_code == req.country_code and u.phone == req.phone), None)
    from datetime import datetime, timezone
    if not user:
        user = User(phone=req.phone, country_code=req.country_code)
        _store.users.append(user)
    user.last_login_at = datetime.now(timezone.utc)
    token = create_access_token(data={"sub": user.user_id, "admin": user.is_admin})
    return LoginResponse(access_token=token, user=_user_response(user))

@router.post("/admin/login", response_model=LoginResponse)
async def admin_login(req: AdminLoginRequest):
    if req.username != settings.ADMIN_USERNAME or req.password != settings.ADMIN_PASSWORD:
        raise HTTPException(status_code=401, detail="帐号或密码错误")
    user = next((u for u in _store.users if u.is_admin), None)
    if not user:
        user = User(phone="admin", country_code="+86")
        user.is_admin = True
        _store.users.append(user)
    token = create_access_token(data={"sub": user.user_id, "admin": True})
    return LoginResponse(access_token=token, user=_user_response(user))

def _user_response(u: User) -> UserResponse:
    return UserResponse(user_id=u.user_id, phone=u.phone, country_code=u.country_code,
        email=u.email, country=u.country, is_active=u.is_active, is_admin=u.is_admin,
        watchlist=u.watchlist, created_at=u.created_at, last_login_at=u.last_login_at)
