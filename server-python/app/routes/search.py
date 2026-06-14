"""Stock search routes — real A-share data."""

from fastapi import APIRouter, Query

from app.schemas.user import StockSearchResult, StockSearchResponse
from app.routes.market import _get_stock_list

router = APIRouter()


@router.get("/stocks", response_model=StockSearchResponse)
async def search_stocks(
    q: str = Query(min_length=1, description="搜索关键字：股票代码、公司名称、拼音简写"),
):
    """搜索中国A股股票（支持英文、数字、中文、拼音简写）"""
    keyword = q.strip()
    stock_list = await _get_stock_list()

    results = []
    for stock in stock_list:
        code = stock["code"]
        name = stock["name"]

        # 代码精确匹配（最高优先级）
        if keyword.upper() == code:
            results.insert(0, StockSearchResult(
                code=code,
                name=name,
                market="sh" if code.startswith(("6", "68")) else "sz",
            ))
            continue

        # 代码部分匹配
        if keyword.upper() in code:
            results.append(StockSearchResult(
                code=code,
                name=name,
                market="sh" if code.startswith(("6", "68")) else "sz",
            ))
            continue

        # 名称匹配（中文/拼音）
        if keyword in name:
            results.append(StockSearchResult(
                code=code,
                name=name,
                market="sh" if code.startswith(("6", "68")) else "sz",
            ))
            continue

        # 拼音简写匹配（取每个汉字首字母）
        pinyin_abbr = _to_pinyin_abbr(name)
        if keyword.upper() in pinyin_abbr.upper():
            results.append(StockSearchResult(
                code=code,
                name=name,
                market="sh" if code.startswith(("6", "68")) else "sz",
            ))

    # 去重（按code），截断到20条
    seen = set()
    unique = []
    for r in results:
        if r.code not in seen:
            seen.add(r.code)
            unique.append(r)
            if len(unique) >= 20:
                break

    return StockSearchResponse(results=unique)


def _to_pinyin_abbr(name: str) -> str:
    """将中文字符串转为拼音首字母简写。

    使用简易映射表覆盖常见汉字。
    对于无法映射的字符，保留原字符。
    """
    # 简易拼音首字母映射（覆盖常用股票名称中的字）
    _PINYIN_MAP = {
        "平": "PA", "安": "A", "银": "Y", "行": "H", "万": "W", "科": "K",
        "中": "Z", "兴": "X", "通": "T", "讯": "X", "美": "M", "的": "D",
        "集": "J", "团": "T", "格": "G", "力": "L", "电": "D", "器": "Q",
        "五": "W", "粮": "L", "液": "Y", "茅": "M", "台": "T", "海": "H",
        "康": "K", "威": "W", "视": "S", "浦": "P", "发": "F", "机": "J",
        "场": "C", "石": "S", "化": "H", "招": "Z", "商": "S", "恒": "H",
        "瑞": "R", "医": "Y", "药": "Y", "贵": "G", "州": "Z", "螺": "L",
        "水": "S", "泥": "N", "伊": "Y", "利": "L", "股": "G", "份": "F",
        "工": "G", "国": "G", "石": "S", "油": "Y", "明": "M", "德": "D",
        "天": "T", "海": "H", "芯": "X", "际": "J", "东": "D", "方": "F",
        "爱": "A", "尔": "E", "眼": "Y", "宁": "N", "德": "D", "时": "S",
        "代": "D", "上": "S", "汽": "Q", "长": "C", "江": "J", "京": "J",
        "牧": "M", "原": "Y", "汾": "F", "金": "J", "山": "S", "办": "B",
        "公": "G", "汇": "H", "川": "C", "技": "J", "隆": "L", "基": "J",
        "绿": "L", "能": "N", "洋": "Y", "河": "H", "片": "P", "仔": "Z",
        "癀": "H", "泸": "L", "老": "L", "窖": "J", "三": "S", "一": "Y",
        "重": "Z", "免": "M", "顺": "S", "丰": "F", "建": "J", "筑": "Z",
        "信": "X", "券": "Q", "温": "W", "氏": "S", "立": "L", "密": "M",
        "神": "S", "兖": "Y", "矿": "K", "源": "Y", "广": "G", "波": "B",
        "保": "B", "发": "F", "展": "Z", "陕": "S", "西": "X", "煤": "M",
        "新": "X", "华": "H", "大": "D", "创": "C", "业": "Y", "板": "B",
        "指": "Z", "综": "Z", "合": "H", "成": "C", "红": "H", "筹": "C",
        "企": "Q", "波": "B", "幅": "F", "道": "D", "琼": "Q", "斯": "S",
        "纳": "N", "达": "D", "克": "K", "普": "P", "标": "B", "想": "X",
        "联": "L", "科": "K", "技": "J", "创": "C", "板": "B",
    }

    result = []
    for char in name:
        result.append(_PINYIN_MAP.get(char, char))
    return "".join(result)
