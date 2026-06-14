"""Market data routes — real-time quotes and K-line history.

Uses AKShare for real Chinese A-share market data.
"""

import logging
from datetime import datetime, timezone, timedelta
from typing import Optional

from fastapi import APIRouter, Query, HTTPException

logger = logging.getLogger(__name__)

router = APIRouter()

# ---- In-memory cache for stock list ----
_stock_list_cache: list[dict] = []
_stock_list_updated: Optional[datetime] = None
_STOCK_LIST_TTL = timedelta(hours=24)


async def _get_stock_list() -> list[dict]:
    """获取 A 股股票列表（缓存 24 小时）。"""
    global _stock_list_cache, _stock_list_updated
    now = datetime.now(timezone.utc)
    if _stock_list_cache and _stock_list_updated and (now - _stock_list_updated) < _STOCK_LIST_TTL:
        return _stock_list_cache

    try:
        import akshare as ak
        df = ak.stock_zh_a_spot_em()
        _stock_list_cache = []
        for _, row in df.iterrows():
            _stock_list_cache.append({
                "code": str(row["代码"]),
                "name": str(row["名称"]),
            })
        _stock_list_updated = now
        logger.info(f"Loaded {len(_stock_list_cache)} A-share stocks from AKShare")
    except Exception as e:
        logger.warning(f"Failed to load stock list from AKShare: {e}. Using fallback.")
        if not _stock_list_cache:
            _stock_list_cache = _build_fallback_stock_list()

    return _stock_list_cache


def _build_fallback_stock_list() -> list[dict]:
    """构建降级股票列表（硬编码常见的 50 只股票）。"""
    stocks = [
        ("000001", "平安银行"), ("000002", "万科A"), ("000063", "中兴通讯"),
        ("000333", "美的集团"), ("000651", "格力电器"), ("000858", "五粮液"),
        ("002415", "海康威视"), ("300750", "宁德时代"), ("600000", "浦发银行"),
        ("600009", "上海机场"), ("600028", "中国石化"), ("600036", "招商银行"),
        ("600276", "恒瑞医药"), ("600519", "贵州茅台"), ("600585", "海螺水泥"),
        ("600887", "伊利股份"), ("601318", "中国平安"), ("601398", "工商银行"),
        ("601857", "中国石油"), ("603259", "药明康德"), ("603288", "海天味业"),
        ("688981", "中芯国际"), ("300059", "东方财富"), ("300015", "爱尔眼科"),
        ("600104", "上汽集团"), ("601166", "兴业银行"), ("600900", "长江电力"),
        ("000725", "京东方A"), ("002714", "牧原股份"), ("600809", "山西汾酒"),
        ("688111", "金山办公"), ("300124", "汇川技术"), ("601012", "隆基绿能"),
        ("600690", "海尔智家"), ("002304", "洋河股份"), ("600436", "片仔癀"),
        ("000568", "泸州老窖"), ("600031", "三一重工"), ("601888", "中国中免"),
        ("002352", "顺丰控股"), ("601668", "中国建筑"), ("600030", "中信证券"),
        ("300498", "温氏股份"), ("002475", "立讯精密"), ("601088", "中国神华"),
        ("600188", "兖矿能源"), ("000776", "广发证券"), ("002142", "宁波银行"),
        ("600048", "保利发展"), ("601225", "陕西煤业"),
    ]
    return [{"code": c, "name": n} for c, n in stocks]


@router.get("/stocks")
async def list_all_stocks():
    """获取全部 A 股列表（供内部使用）。"""
    stocks = await _get_stock_list()
    return {"stocks": stocks, "total": len(stocks)}


@router.get("/quote/{code}")
async def get_quote(code: str):
    """获取单只股票实时行情。

    使用 AKShare stock_zh_a_spot_em 获取 A 股行情数据。
    """
    try:
        import akshare as ak
        df = ak.stock_zh_a_spot_em()
        row = df[df["代码"] == code]
        if row.empty:
            raise HTTPException(status_code=404, detail=f"股票 {code} 未找到")

        r = row.iloc[0]
        change = float(r["涨跌额"]) if "涨跌额" in r and r["涨跌额"] != "-" else 0
        change_pct_str = str(r["涨跌幅"]) if "涨跌幅" in r else "0"
        change_pct = float(change_pct_str.replace("%", "")) if change_pct_str != "-" else 0

        return {
            "code": code,
            "name": str(r["名称"]),
            "market": "sh" if code.startswith(("6", "68")) else "sz",
            "current_price": float(r["最新价"]) if r["最新价"] != "-" else 0,
            "change": change,
            "change_percent": change_pct,
            "high": float(r["最高"]) if r["最高"] != "-" else 0,
            "low": float(r["最低"]) if r["最低"] != "-" else 0,
            "open": float(r["今开"]) if r["今开"] != "-" else 0,
            "pre_close": float(r["昨收"]) if r["昨收"] != "-" else 0,
            "volume": int(r["成交量"]) if "成交量" in r and r["成交量"] != "-" else 0,
            "amount": float(r["成交额"]) if "成交额" in r and r["成交额"] != "-" else 0,
            "update_time": datetime.now(timezone.utc).isoformat(),
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching quote for {code}: {e}")
        # 降级返回模拟数据
        return _simulate_quote(code)


@router.get("/quote/{code}/history")
async def get_history(
    code: str,
    period: str = Query("daily", description="daily | weekly | monthly"),
    count: int = Query(100, ge=1, le=365, description="返回 K 线数量"),
):
    """获取股票历史 K 线数据。

    使用 AKShare stock_zh_a_hist 获取日/周/月 K 线。
    """
    try:
        import akshare as ak
        period_map = {"daily": "daily", "weekly": "weekly", "monthly": "monthly"}
        ak_period = period_map.get(period, "daily")

        df = ak.stock_zh_a_hist(symbol=code, period=ak_period, adjust="qfq")
        if df is None or df.empty:
            return {"code": code, "period": period, "k_lines": []}

        records = []
        for _, row in df.tail(count).iterrows():
            records.append({
                "date": str(row["日期"]),
                "open": float(row["开盘"]),
                "close": float(row["收盘"]),
                "high": float(row["最高"]),
                "low": float(row["最低"]),
                "volume": int(row["成交量"]),
                "amount": float(row["成交额"]) if "成交额" in row else 0,
                "change_pct": float(row["涨跌幅"]) if "涨跌幅" in row else 0,
            })
        return {"code": code, "period": period, "k_lines": records}
    except Exception as e:
        logger.error(f"Error fetching history for {code}: {e}")
        return {"code": code, "period": period, "k_lines": _simulate_k_lines(count)}


@router.get("/indices")
async def get_market_indices():
    """获取所有市场指数行情。"""
    # 使用 AKShare 获取指数行情
    indices_config = {
        "000001": "上证指数",
        "399001": "深证成指",
        "399006": "创业板指",
        "000688": "科创50",
        "899050": "北证50",
    }

    results = []
    try:
        import akshare as ak
        df = ak.stock_zh_index_spot_em()
        for code, name in indices_config.items():
            row = df[df["代码"] == code]
            if not row.empty:
                r = row.iloc[0]
                results.append({
                    "code": code,
                    "name": str(r["名称"]) if "名称" in r else name,
                    "market": "sh" if code.startswith(("0", "68")) else "sz",
                    "current_price": float(r["最新价"]) if r["最新价"] != "-" else 0,
                    "change": float(r["涨跌额"]) if "涨跌额" in r and r["涨跌额"] != "-" else 0,
                    "change_percent": float(str(r["涨跌幅"]).replace("%", "")) if "涨跌幅" in r and str(r["涨跌幅"]) != "-" else 0,
                    "high": float(r["最高"]) if "最高" in r and r["最高"] != "-" else 0,
                    "low": float(r["最低"]) if "最低" in r and r["最低"] != "-" else 0,
                    "open": float(r["今开"]) if "今开" in r and r["今开"] != "-" else 0,
                    "pre_close": float(r["昨收"]) if "昨收" in r and r["昨收"] != "-" else 0,
                    "volume": int(r["成交量"]) if "成交量" in r and r["成交量"] != "-" else 0,
                    "amount": float(r["成交额"]) if "成交额" in r and r["成交额"] != "-" else 0,
                    "update_time": datetime.now(timezone.utc).isoformat(),
                })
            else:
                results.append(_simulate_quote(code, name))
    except Exception as e:
        logger.error(f"Error fetching indices: {e}")
        for code, name in indices_config.items():
            results.append(_simulate_quote(code, name))

    return {"indices": results}


# ---- Simulation helpers (for development without AKShare) ----

def _simulate_quote(code: str, name: str = "") -> dict:
    """生成模拟行情数据。"""
    import random
    base = 3500.0 if code.startswith("0") else 50.0
    jitter = random.uniform(-2, 2)
    price = base + jitter

    return {
        "code": code,
        "name": name or code,
        "market": "sh" if code.startswith(("6", "68", "0")) else "sz",
        "current_price": round(price, 2),
        "change": round(jitter, 2),
        "change_percent": round(jitter / (price - jitter) * 100, 2),
        "high": round(price + random.uniform(0, 1), 2),
        "low": round(price - random.uniform(0, 1), 2),
        "open": round(base + random.uniform(-1, 1), 2),
        "pre_close": base,
        "volume": random.randint(100000, 10000000),
        "amount": round(price * random.randint(100000, 10000000), 2),
        "update_time": datetime.now(timezone.utc).isoformat(),
    }


def _simulate_k_lines(count: int) -> list[dict]:
    """生成模拟 K 线数据。"""
    import random
    from datetime import timedelta

    k_lines = []
    base_price = 50.0
    date = datetime.now(timezone.utc).date()

    for i in range(count):
        open_p = round(base_price + random.uniform(-2, 3), 2)
        close_p = round(open_p + random.uniform(-2, 2), 2)
        high_p = round(max(open_p, close_p) + random.uniform(0, 1.5), 2)
        low_p = round(min(open_p, close_p) - random.uniform(0, 1.5), 2)
        base_price = close_p

        k_lines.append({
            "date": str(date - timedelta(days=count - i)),
            "open": open_p,
            "close": close_p,
            "high": high_p,
            "low": low_p,
            "volume": random.randint(50000, 500000),
            "amount": round(close_p * random.randint(50000, 500000), 2),
            "change_pct": round((close_p - open_p) / open_p * 100, 2),
        })

    return k_lines
