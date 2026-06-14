# Python 服务 Dockerfile
FROM python:3.12-slim

WORKDIR /app

# 核心依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --break-system-packages

# 可选依赖（akshare/asyncpg 较大，失败不影响）
COPY requirements-optional.txt .
RUN pip install --no-cache-dir -r requirements-optional.txt --break-system-packages || echo "Optional deps skipped"

COPY . .

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
