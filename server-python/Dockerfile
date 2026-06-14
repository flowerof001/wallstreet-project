# Python 服务 Dockerfile
FROM python:3.12-slim

WORKDIR /app

# 安装系统依赖（psycopg2 编译需要）
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# 核心依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --break-system-packages

# 可选依赖（akshare 较大，失败了不影响服务）
COPY requirements-optional.txt .
RUN pip install --no-cache-dir -r requirements-optional.txt --break-system-packages || echo "Optional deps skipped"

COPY . .

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
