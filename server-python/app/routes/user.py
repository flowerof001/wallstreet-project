"""User routes: profile, password, watchlist, market pages."""

from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User, MarketPage, StockCard
from app.schemas.user import (
    UserResponse, ChangePasswordRequest, WatchlistUpdate,
    MarketPageCreate, MarketPageResponse, StockCardSchema,
    CardAddRequest, CardUpdateRequest, UpdateUserRequest,
)
from app.services.auth import get_current_user, hash_password, verify_password
import uuid

router = APIRouter()


@router.get("/me", response_model=UserResponse)
async def get_me(user: User = Depends(get_current_user)):
    """获取当前用户信息"""
    return UserResponse.model_validate(user)


@router.post("/change-password")
async def change_password(
    req: ChangePasswordRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """修改登录密码"""
    if req.new_password != req.confirm_password:
        raise HTTPException(status_code=400, detail="两次密码不一致")

    if len(req.new_password) < 6 or len(req.new_password) > 32:
        raise HTTPException(status_code=400, detail="密码长度必须为6-32位")

    if user.hashed_password:
        # 之前设置过密码：需要旧密码
        if not req.old_password:
            raise HTTPException(status_code=400, detail="请输入原来的密码")
        if not verify_password(req.old_password, user.hashed_password):
            raise HTTPException(status_code=400, detail="原密码错误")
    # 否则是首次设置密码

    user.hashed_password = hash_password(req.new_password)
    await db.commit()
    return {"success": True, "message": "密码修改成功"}


@router.delete("/me")
async def delete_account(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """注销帐号：标记为不活跃，保留 user_id"""
    user.is_active = False
    user.deleted_at = datetime.now(timezone.utc)
    await db.commit()
    return {"success": True, "message": "帐号已注销"}


@router.put("/watchlist", response_model=UserResponse)
async def update_watchlist(
    req: WatchlistUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """更新自选股票列表"""
    user.watchlist = req.codes
    await db.commit()
    await db.refresh(user)
    return UserResponse.model_validate(user)


# ============ Market Pages ============

@router.get("/pages", response_model=list[MarketPageResponse])
async def list_pages(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(MarketPage).where(MarketPage.user_id == user.id).order_by(MarketPage.sort_order)
    )
    pages = result.scalars().all()
    return [
        MarketPageResponse(
            page_id=p.page_id,
            name=p.name,
            layout_columns=p.layout_columns,
            cards=[
                StockCardSchema(
                    card_id=c.card_id,
                    stock_code=c.stock_code,
                    width=c.width,
                    height=c.height,
                    position=c.position,
                    chart_type=c.chart_type,
                )
                for c in p.cards
            ],
        )
        for p in pages
    ]


@router.post("/pages", response_model=MarketPageResponse)
async def create_page(
    req: MarketPageCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # 检查上限
    result = await db.execute(
        select(MarketPage).where(MarketPage.user_id == user.id)
    )
    if len(result.scalars().all()) >= 20:
        raise HTTPException(status_code=400, detail="最多创建20个行情页面")

    page = MarketPage(
        user_id=user.id,
        name=req.name,
    )
    db.add(page)
    await db.commit()
    await db.refresh(page)
    return MarketPageResponse(page_id=page.page_id, name=page.name, layout_columns=page.layout_columns)


@router.delete("/pages/{page_id}")
async def delete_page(
    page_id: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(MarketPage).where(MarketPage.page_id == page_id, MarketPage.user_id == user.id)
    )
    page = result.scalar_one_or_none()
    if not page:
        raise HTTPException(status_code=404, detail="页面不存在")
    await db.delete(page)
    await db.commit()
    return {"success": True}


@router.post("/pages/{page_id}/cards")
async def add_card(
    page_id: str,
    req: CardAddRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(MarketPage).where(MarketPage.page_id == page_id, MarketPage.user_id == user.id)
    )
    page = result.scalar_one_or_none()
    if not page:
        raise HTTPException(status_code=404, detail="页面不存在")

    # 检查卡片上限
    if len(page.cards) >= 20:
        raise HTTPException(status_code=400, detail="每个页面最多20张走势图卡片")

    card = StockCard(
        page_id=page.id,
        stock_code=req.stock_code,
        stock_name=req.stock_name,
        position=len(page.cards),
    )
    db.add(card)
    await db.commit()
    await db.refresh(card)
    return {"card_id": card.card_id, "success": True}


@router.delete("/pages/{page_id}/cards/{card_id}")
async def remove_card(
    page_id: str,
    card_id: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(StockCard).join(MarketPage).where(
            StockCard.card_id == card_id,
            MarketPage.page_id == page_id,
            MarketPage.user_id == user.id,
        )
    )
    card = result.scalar_one_or_none()
    if not card:
        raise HTTPException(status_code=404, detail="卡片不存在")
    await db.delete(card)
    await db.commit()
    return {"success": True}


@router.put("/pages/{page_id}/cards/{card_id}")
async def update_card(
    page_id: str,
    card_id: str,
    req: CardUpdateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(StockCard).join(MarketPage).where(
            StockCard.card_id == card_id,
            MarketPage.page_id == page_id,
            MarketPage.user_id == user.id,
        )
    )
    card = result.scalar_one_or_none()
    if not card:
        raise HTTPException(status_code=404, detail="卡片不存在")

    if req.width is not None:
        card.width = req.width
    if req.height is not None:
        card.height = req.height
    if req.position is not None:
        card.position = req.position
    if req.chart_type is not None:
        card.chart_type = req.chart_type

    await db.commit()
    return {"success": True}
