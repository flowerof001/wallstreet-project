#!/bin/bash
# ============================================================
# 全栈一键启动脚本 — WallstreetProject 本地开发
# ============================================================
# 用法: bash scripts/start-dev.sh
# 启动 PostgreSQL + Redis + Go服务 + Python服务 + Admin
# ============================================================

set -e

echo "🐘 Starting PostgreSQL + Redis..."
docker compose up -d postgres redis
sleep 3

echo "🐍 Starting Python FastAPI..."
cd "$(dirname "$0")/../server-python"
pip install -r requirements.txt --break-system-packages > /dev/null 2>&1
uvicorn app.main:app --reload --port 8000 &
PYTHON_PID=$!

echo "🔵 Starting Go WebSocket Server..."
cd "$(dirname "$0")/../server-go"
go run cmd/server/main.go &
GO_PID=$!

echo "🔷 Starting Admin Dashboard..."
cd "$(dirname "$0")/../admin"
npm install --silent
npm run dev &
ADMIN_PID=$!

echo ""
echo "✅ All services running:"
echo "  Python API:  http://localhost:8000"
echo "  Go WS:       ws://localhost:8080/ws"
echo "  Admin:       http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop all services"

# 捕获退出信号，清理进程
trap "kill $PYTHON_PID $GO_PID $ADMIN_PID 2>/dev/null; docker compose stop; exit 0" SIGINT SIGTERM
wait
