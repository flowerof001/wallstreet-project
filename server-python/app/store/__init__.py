"""In-memory store — no database required. Data lost on restart."""
import secrets
import uuid
from datetime import datetime, timezone
from typing import Optional

def _gen_uid() -> str:
    alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return "".join(secrets.choice(alphabet) for _ in range(64))

class User:
    def __init__(self, phone: str, country_code: str = "+86"):
        self.id = len(_store.users) + 1
        self.user_id = _gen_uid()
        self.phone = phone
        self.country_code = country_code
        self.email: Optional[str] = None
        self.hashed_password: Optional[str] = None
        self.country: str = "CN"
        self.ip_address: Optional[str] = None
        self.is_active: bool = True
        self.is_admin: bool = False
        self.watchlist: list = []
        self.created_at = datetime.now(timezone.utc)
        self.last_login_at: Optional[datetime] = None
        self.deleted_at: Optional[datetime] = None

class MarketPage:
    def __init__(self, user_id: int, name: str):
        self.id = len(_store.pages) + 1
        self.page_id = uuid.uuid4().hex
        self.user_id = user_id
        self.name = name
        self.layout_columns = 3
        self.sort_order = 0
        self.created_at = datetime.now(timezone.utc)
        self.cards: list = []

class StockCard:
    def __init__(self, page_id: int, stock_code: str, stock_name: str = ""):
        self.id = len(_store.cards) + 1
        self.card_id = uuid.uuid4().hex
        self.page_id = page_id
        self.stock_code = stock_code
        self.stock_name = stock_name
        self.width = 400.0
        self.height = 300.0
        self.position = 0
        self.chart_type = "time_sharing"
        self.created_at = datetime.now(timezone.utc)

class _Store:
    def __init__(self):
        self.users: list[User] = []
        self.pages: list[MarketPage] = []
        self.cards: list[StockCard] = []

_store = _Store()
