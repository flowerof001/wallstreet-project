"""User routes: profile, password, watchlist, market pages."""
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from app.services.auth import get_current_user, hash_password, verify_password
from app.store import _store, MarketPage, StockCard
from app.schemas.user import (
    UserResponse, ChangePasswordRequest, WatchlistUpdate,
    MarketPageCreate, MarketPageResponse, StockCardSchema,
    CardAddRequest, CardUpdateRequest,
)

router = APIRouter()

def _user_response(u):
    return UserResponse(user_id=u.user_id, phone=u.phone, country_code=u.country_code,
        email=u.email, country=u.country, is_active=u.is_active, is_admin=u.is_admin,
        watchlist=u.watchlist, created_at=u.created_at, last_login_at=u.last_login_at)

@router.get("/me", response_model=UserResponse)
async def get_me(user = Depends(get_current_user)):
    return _user_response(user)

@router.post("/change-password")
async def change_password(req: ChangePasswordRequest, user = Depends(get_current_user)):
    if req.new_password != req.confirm_password:
        raise HTTPException(status_code=400, detail="两次密码不一致")
    if len(req.new_password) < 6 or len(req.new_password) > 32:
        raise HTTPException(status_code=400, detail="密码长度必须为6-32位")
    if user.hashed_password:
        if not req.old_password:
            raise HTTPException(status_code=400, detail="请输入原来的密码")
        if not verify_password(req.old_password, user.hashed_password):
            raise HTTPException(status_code=400, detail="原密码错误")
    user.hashed_password = hash_password(req.new_password)
    return {"success": True, "message": "密码修改成功"}

@router.delete("/me")
async def delete_account(user = Depends(get_current_user)):
    user.is_active = False
    user.deleted_at = datetime.now(timezone.utc)
    return {"success": True, "message": "帐号已注销"}

@router.put("/watchlist", response_model=UserResponse)
async def update_watchlist(req: WatchlistUpdate, user = Depends(get_current_user)):
    user.watchlist = req.codes
    return _user_response(user)

@router.get("/pages", response_model=list[MarketPageResponse])
async def list_pages(user = Depends(get_current_user)):
    pages = [p for p in _store.pages if p.user_id == user.id]
    pages.sort(key=lambda p: p.sort_order)
    return [MarketPageResponse(page_id=p.page_id, name=p.name, layout_columns=p.layout_columns,
        cards=[StockCardSchema(card_id=c.card_id, stock_code=c.stock_code, width=c.width,
            height=c.height, position=c.position, chart_type=c.chart_type) for c in p.cards]) for p in pages]

@router.post("/pages", response_model=MarketPageResponse)
async def create_page(req: MarketPageCreate, user = Depends(get_current_user)):
    if len([p for p in _store.pages if p.user_id == user.id]) >= 20:
        raise HTTPException(status_code=400, detail="最多创建20个行情页面")
    page = MarketPage(user_id=user.id, name=req.name)
    _store.pages.append(page)
    return MarketPageResponse(page_id=page.page_id, name=page.name, layout_columns=page.layout_columns)

@router.delete("/pages/{page_id}")
async def delete_page(page_id: str, user = Depends(get_current_user)):
    page = next((p for p in _store.pages if p.page_id == page_id and p.user_id == user.id), None)
    if not page:
        raise HTTPException(status_code=404, detail="页面不存在")
    _store.cards[:] = [c for c in _store.cards if c.page_id != page.id]
    _store.pages.remove(page)
    return {"success": True}

@router.post("/pages/{page_id}/cards")
async def add_card(page_id: str, req: CardAddRequest, user = Depends(get_current_user)):
    page = next((p for p in _store.pages if p.page_id == page_id and p.user_id == user.id), None)
    if not page:
        raise HTTPException(status_code=404, detail="页面不存在")
    if len(page.cards) >= 20:
        raise HTTPException(status_code=400, detail="每个页面最多20张走势图卡片")
    card = StockCard(page_id=page.id, stock_code=req.stock_code, stock_name=req.stock_name or "")
    card.position = len(page.cards)
    _store.cards.append(card)
    page.cards.append(card)
    return {"card_id": card.card_id, "success": True}

@router.delete("/pages/{page_id}/cards/{card_id}")
async def remove_card(page_id: str, card_id: str, user = Depends(get_current_user)):
    page = next((p for p in _store.pages if p.page_id == page_id and p.user_id == user.id), None)
    if not page:
        raise HTTPException(status_code=404, detail="页面不存在")
    card = next((c for c in page.cards if c.card_id == card_id), None)
    if not card:
        raise HTTPException(status_code=404, detail="卡片不存在")
    page.cards.remove(card)
    _store.cards[:] = [c for c in _store.cards if c.card_id != card_id]
    return {"success": True}

@router.put("/pages/{page_id}/cards/{card_id}")
async def update_card(page_id: str, card_id: str, req: CardUpdateRequest, user = Depends(get_current_user)):
    page = next((p for p in _store.pages if p.page_id == page_id and p.user_id == user.id), None)
    if not page:
        raise HTTPException(status_code=404, detail="页面不存在")
    card = next((c for c in page.cards if c.card_id == card_id), None)
    if not card:
        raise HTTPException(status_code=404, detail="卡片不存在")
    if req.width is not None: card.width = req.width
    if req.height is not None: card.height = req.height
    if req.position is not None: card.position = req.position
    if req.chart_type is not None: card.chart_type = req.chart_type
    return {"success": True}
