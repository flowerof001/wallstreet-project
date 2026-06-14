"""WebSocket real-time market data broadcast.
使用 FastAPI WebSocket 提供实时行情推送（替代 Go 服务）。
"""

import asyncio
import json
import logging
import time
from datetime import datetime, timezone

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.routes.market import _get_stock_list, _simulate_quote
from app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter()


class ConnectionManager:
    """管理所有活跃的 WebSocket 连接。"""

    def __init__(self):
        self.active_connections: dict[str, WebSocket] = {}  # conn_id -> WebSocket
        self.subscriptions: dict[str, set[str]] = {}  # conn_id -> set of codes
        self._conn_counter = 0

    async def connect(self, websocket: WebSocket) -> str:
        await websocket.accept()
        self._conn_counter += 1
        conn_id = f"ws_{self._conn_counter}_{int(time.time())}"
        self.active_connections[conn_id] = websocket
        self.subscriptions[conn_id] = set()
        logger.info(f"WebSocket connected: {conn_id} (total: {len(self.active_connections)})")
        return conn_id

    def disconnect(self, conn_id: str):
        self.active_connections.pop(conn_id, None)
        self.subscriptions.pop(conn_id, None)
        logger.info(f"WebSocket disconnected: {conn_id} (total: {len(self.active_connections)})")

    def subscribe(self, conn_id: str, codes: list[str]):
        if conn_id in self.subscriptions:
            self.subscriptions[conn_id].update(codes)

    def unsubscribe(self, conn_id: str, codes: list[str]):
        if conn_id in self.subscriptions:
            self.subscriptions[conn_id].difference_update(codes)

    async def broadcast(self, quote: dict):
        """广播行情到所有连接。"""
        message = json.dumps({
            "type": "quote",
            "data": quote,
            "ts": int(time.time() * 1000),
        }, ensure_ascii=False)
        disconnected = []
        for conn_id, ws in list(self.active_connections.items()):
            try:
                await ws.send_text(message)
            except Exception:
                disconnected.append(conn_id)
        for cid in disconnected:
            self.disconnect(cid)

    async def broadcast_batch(self, quotes: list[dict]):
        """批量广播。"""
        message = json.dumps({
            "type": "batch",
            "data": quotes,
            "ts": int(time.time() * 1000),
        }, ensure_ascii=False)
        disconnected = []
        for conn_id, ws in list(self.active_connections.items()):
            try:
                await ws.send_text(message)
            except Exception:
                disconnected.append(conn_id)
        for cid in disconnected:
            self.disconnect(cid)

    @property
    def client_count(self) -> int:
        return len(self.active_connections)


manager = ConnectionManager()


# ---- 行情采集任务 ----
_collector_task: asyncio.Task | None = None
_cached_quotes: dict[str, dict] = {}


async def _market_collector_loop():
    """每 3 秒采集一次市场数据并广播。"""
    global _cached_quotes

    # 默认跟踪的市场指数
    default_indices = [
        ("000001", "上证指数", "sh"),
        ("399001", "深证成指", "sz"),
        ("399006", "创业板指", "sz"),
        ("000688", "科创50", "sh"),
        ("899050", "北证50", "bj"),
    ]

    while True:
        try:
            updated = []
            for code, name, market in default_indices:
                try:
                    quote = _simulate_quote(code, name)
                    quote["market"] = market
                    _cached_quotes[code] = quote
                    updated.append(quote)
                except Exception as e:
                    logger.warning(f"Failed to fetch {code}: {e}")

            if updated and manager.active_connections:
                await manager.broadcast_batch(updated)
                logger.debug(f"Broadcast {len(updated)} quotes to {manager.client_count} clients")

        except Exception as e:
            logger.error(f"Collector error: {e}")

        await asyncio.sleep(3)


def start_collector():
    global _collector_task
    if _collector_task is None or _collector_task.done():
        _collector_task = asyncio.create_task(_market_collector_loop())
        logger.info("Market collector started")


def stop_collector():
    global _collector_task
    if _collector_task and not _collector_task.done():
        _collector_task.cancel()
        logger.info("Market collector stopped")


# ---- WebSocket 端点 ----

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    conn_id = await manager.connect(websocket)

    # 发送欢迎消息和当前缓存数据
    try:
        await websocket.send_text(json.dumps({
            "type": "connected",
            "message": "Connected to Wallstreet real-time feed",
            "conn_id": conn_id,
            "ts": int(time.time() * 1000),
        }))

        if _cached_quotes:
            await websocket.send_text(json.dumps({
                "type": "batch",
                "data": list(_cached_quotes.values()),
                "ts": int(time.time() * 1000),
            }, ensure_ascii=False))

        while True:
            data = await websocket.receive_text()
            try:
                msg = json.loads(data)
                action = msg.get("action", "")
                codes = msg.get("codes", [])

                if action == "subscribe" and codes:
                    manager.subscribe(conn_id, codes)
                elif action == "unsubscribe" and codes:
                    manager.unsubscribe(conn_id, codes)
            except json.JSONDecodeError:
                pass

    except WebSocketDisconnect:
        pass
    except Exception as e:
        logger.warning(f"WebSocket error {conn_id}: {e}")
    finally:
        manager.disconnect(conn_id)


# ---- REST 行情端点（替代 Go HTTP API） ----

@router.get("/quotes")
async def get_all_quotes():
    """获取所有缓存的行情快照。"""
    return {code: quote for code, quote in _cached_quotes.items()}


@router.get("/quotes/{code}")
async def get_quote(code: str):
    """获取单只股票行情快照。"""
    quote = _cached_quotes.get(code)
    if quote:
        return quote
    # 尝试实时获取
    try:
        new_quote = _simulate_quote(code, code)
        _cached_quotes[code] = new_quote
        return new_quote
    except Exception:
        return {"error": "stock not found"}
