#!/bin/bash
# ============================================================
# Cloudflare Pages 一键部署脚本 — WallstreetProject
# ============================================================
# 用法: bash scripts/deploy-cloudflare.sh
# 前提: Flutter SDK 已安装，flutter 命令可用

set -e

echo "🔨 Building Flutter Web..."
cd "$(dirname "$0")/../client"

# 清理旧构建
rm -rf build/web

# Web 构建（CanvasKit 渲染器，性能最好）
flutter build web --release --web-renderer canvaskit

echo "✅ Build complete: client/build/web"

echo ""
echo "📦 部署方式选一："
echo ""
echo "方式一：通过 Cloudflare Dashboard 手动部署"
echo "  1. 打开 https://dash.cloudflare.com/"
echo "  2. 点击 Workers & Pages → Create → Pages"
echo "  3. 选择 'Upload assets'"
echo "  4. 项目名: wallstreet"
echo "  5. 将 client/build/web 文件夹拖入上传区域"
echo "  6. 点击 Deploy"
echo "  7. 你的网站: https://wallstreet.pages.dev"
echo ""
echo "方式二：通过 wrangler CLI 部署（推荐）"
echo "  1. npm install -g wrangler"
echo "  2. wrangler login"
echo "  3. wrangler pages deploy client/build/web --project-name=wallstreet"
echo "  4. 你的网站: https://wallstreet.pages.dev"
echo ""
echo "方式三：GitHub + Cloudflare Pages 自动部署"
echo "  1. 将项目推送到 GitHub"
echo "  2. Cloudflare Pages → Create a project → Connect to Git"
echo "  3. Build command: cd client && flutter build web --release"
echo "  4. Build output directory: client/build/web"
echo "  5. 每次 git push 自动部署"
echo ""

echo "🚀 Flutter Web 已构建完成，准备部署！"
