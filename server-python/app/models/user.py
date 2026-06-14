"""SQLAlchemy models for Wallstreet."""

import uuid
import secrets
from datetime import datetime, timezone

from sqlalchemy import (
    Column, String, DateTime, Boolean, Text, Integer, Float, ForeignKey,
)
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import ARRAY

from app.database import Base


def generate_user_id() -> str:
    """Generate a unique 64-char userID from uppercase, lowercase, digits."""
    alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return "".join(secrets.choice(alphabet) for _ in range(64))


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(64), unique=True, nullable=False, default=generate_user_id, index=True)
    phone = Column(String(20), nullable=False)
    country_code = Column(String(10), nullable=False, default="+86")
    email = Column(String(255), nullable=True)
    hashed_password = Column(String(255), nullable=True)
    country = Column(String(10), nullable=True)
    ip_address = Column(String(45), nullable=True)
    is_active = Column(Boolean, default=True)
    is_admin = Column(Boolean, default=False)
    # 自选股票列表
    watchlist = Column(ARRAY(String), default=list)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    last_login_at = Column(DateTime(timezone=True), nullable=True)
    # 已注销的帐号保留 user_id 但标记为不活跃
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    # 关联：行情页面布局
    pages = relationship("MarketPage", back_populates="user", cascade="all, delete-orphan")


class MarketPage(Base):
    """用户创建的行情页面（最多20个）"""
    __tablename__ = "market_pages"

    id = Column(Integer, primary_key=True, autoincrement=True)
    page_id = Column(String(64), unique=True, nullable=False, default=lambda: uuid.uuid4().hex)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(100), nullable=False)
    layout_columns = Column(Integer, default=3)
    sort_order = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="pages")
    cards = relationship("StockCard", back_populates="page", cascade="all, delete-orphan")


class StockCard(Base):
    """走势图卡片（每个页面最多20张）"""
    __tablename__ = "stock_cards"

    id = Column(Integer, primary_key=True, autoincrement=True)
    card_id = Column(String(64), unique=True, nullable=False, default=lambda: uuid.uuid4().hex)
    page_id = Column(Integer, ForeignKey("market_pages.id"), nullable=False)
    stock_code = Column(String(20), nullable=False)
    stock_name = Column(String(100), nullable=True)
    width = Column(Float, default=400)
    height = Column(Float, default=300)
    position = Column(Integer, default=0)
    chart_type = Column(String(20), default="time_sharing")  # time_sharing, daily_k, monthly_k, yearly_k
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    page = relationship("MarketPage", back_populates="cards")
