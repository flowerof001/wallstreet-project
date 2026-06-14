"""Admin routes: manage users."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.schemas.user import UserResponse, UpdateUserRequest, AdminUserListResponse
from app.services.auth import get_current_admin

router = APIRouter()


@router.get("/users", response_model=AdminUserListResponse)
async def list_users(
    page: int = 1,
    size: int = 20,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """管理员：获取用户列表"""
    offset = (page - 1) * size
    result = await db.execute(
        select(User).limit(size).offset(offset).order_by(User.created_at.desc())
    )
    users = result.scalars().all()
    total_result = await db.execute(select(User))
    total = len(total_result.scalars().all())

    return AdminUserListResponse(
        total=total,
        users=[UserResponse.model_validate(u) for u in users],
    )


@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: str,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """管理员：查看单个用户"""
    result = await db.execute(select(User).where(User.user_id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    return UserResponse.model_validate(user)


@router.put("/users/{user_id}")
async def update_user(
    user_id: str,
    req: UpdateUserRequest,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """管理员：修改用户信息"""
    result = await db.execute(select(User).where(User.user_id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")

    if req.phone is not None:
        user.phone = req.phone
    if req.email is not None:
        user.email = req.email
    if req.country is not None:
        user.country = req.country
    if req.country_code is not None:
        user.country_code = req.country_code
    if req.is_active is not None:
        user.is_active = req.is_active

    await db.commit()
    return {"success": True}


@router.delete("/users/{user_id}")
async def delete_user(
    user_id: str,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """管理员：删除用户"""
    result = await db.execute(select(User).where(User.user_id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")

    await db.delete(user)
    await db.commit()
    return {"success": True}
