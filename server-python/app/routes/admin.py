"""Admin routes: manage users."""
from fastapi import APIRouter, Depends, HTTPException
from app.services.auth import get_current_admin
from app.store import _store
from app.schemas.user import UserResponse, UpdateUserRequest, AdminUserListResponse

router = APIRouter()

def _ur(u):
    return UserResponse(user_id=u.user_id, phone=u.phone, country_code=u.country_code,
        email=u.email, country=u.country, is_active=u.is_active, is_admin=u.is_admin,
        watchlist=u.watchlist, created_at=u.created_at, last_login_at=u.last_login_at)

@router.get("/users", response_model=AdminUserListResponse)
async def list_users(page: int = 1, size: int = 20, admin = Depends(get_current_admin)):
    users = sorted(_store.users, key=lambda u: u.created_at, reverse=True)
    start = (page - 1) * size
    return AdminUserListResponse(total=len(users), users=[_ur(u) for u in users[start:start+size]])

@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: str, admin = Depends(get_current_admin)):
    user = next((u for u in _store.users if u.user_id == user_id), None)
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    return _ur(user)

@router.put("/users/{user_id}")
async def update_user(user_id: str, req: UpdateUserRequest, admin = Depends(get_current_admin)):
    user = next((u for u in _store.users if u.user_id == user_id), None)
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    if req.phone is not None: user.phone = req.phone
    if req.email is not None: user.email = req.email
    if req.country is not None: user.country = req.country
    if req.country_code is not None: user.country_code = req.country_code
    if req.is_active is not None: user.is_active = req.is_active
    return {"success": True}

@router.delete("/users/{user_id}")
async def delete_user(user_id: str, admin = Depends(get_current_admin)):
    user = next((u for u in _store.users if u.user_id == user_id), None)
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    _store.users.remove(user)
    return {"success": True}
