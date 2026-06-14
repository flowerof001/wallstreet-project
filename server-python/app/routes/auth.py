"""Auth routes: login, register, send code."""

import secrets
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User, generate_user_id
from app.schemas.user import (
    SendCodeRequest, SendCodeResponse,
    LoginRequest, LoginResponse, UserResponse,
    AdminLoginRequest,
)
from app.services.auth import create_access_token, verify_password, hash_password
from app.services.sms import get_sms_provider, generate_code
from app.config import settings

router = APIRouter()

# 验证码存储（内存；生产应切换为 Redis）
_verification_codes: dict[str, str] = {}


@router.post("/send-code", response_model=SendCodeResponse)
async def send_code(req: SendCodeRequest):
    """发送手机短信验证码"""
    code = generate_code()
    key = f"{req.country_code}:{req.phone}"
    _verification_codes[key] = code

    # 通过 SMS provider 发送验证码
    provider = get_sms_provider()
    await provider.send_code(req.country_code, req.phone, code)

    return SendCodeResponse(success=True)


@router.post("/login", response_model=LoginResponse)
async def login(req: LoginRequest, db: AsyncSession = Depends(get_db)):
    """手机验证码登录/注册"""
    key = f"{req.country_code}:{req.phone}"
    expected = _verification_codes.get(key)
    if not expected or req.code != expected:
        raise HTTPException(status_code=400, detail="验证码错误")

    # 验证成功后清理验证码
    _verification_codes.pop(key, None)

    # 查找用户
    result = await db.execute(
        select(User).where(
            User.country_code == req.country_code,
            User.phone == req.phone,
        )
    )
    user = result.scalar_one_or_none()

    from datetime import datetime, timezone
    if not user:
        # 新用户注册
        user = User(
            user_id=generate_user_id(),
            phone=req.phone,
            country_code=req.country_code,
            created_at=datetime.now(timezone.utc),
        )
        db.add(user)
        await db.flush()

    user.last_login_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(user)

    token = create_access_token(data={"sub": user.user_id, "admin": user.is_admin})

    return LoginResponse(
        access_token=token,
        user=UserResponse.model_validate(user),
    )


@router.post("/admin/login", response_model=LoginResponse)
async def admin_login(req: AdminLoginRequest, db: AsyncSession = Depends(get_db)):
    """管理员登录"""
    if req.username != settings.ADMIN_USERNAME or req.password != settings.ADMIN_PASSWORD:
        raise HTTPException(status_code=401, detail="帐号或密码错误")

    # 查找或创建管理员用户
    result = await db.execute(
        select(User).where(User.is_admin == True)
    )
    user = result.scalar_one_or_none()
    if not user:
        user = User(
            user_id=generate_user_id(),
            phone="admin",
            country_code="+86",
            is_admin=True,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    token = create_access_token(data={"sub": user.user_id, "admin": True})
    return LoginResponse(
        access_token=token,
        user=UserResponse.model_validate(user),
    )
