#!/bin/bash
# ============================================================
# 在你的终端中执行此脚本
# ============================================================

set -e

export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PATH="$HOME/Desktop/260526_MyMacComputer/005SoftWare/002NetworkSoftware/260612_Flutter_macOS_3.44.2-Stable/flutter/bin:$PATH"

PROJECT_ROOT="$HOME/Documents/260613_ClaudeCodeProject/260613_WallstreetProject"
CLIENT_DIR="$PROJECT_ROOT/client"
ADMIN_DIR="$PROJECT_ROOT/admin"

echo "============================================"
echo "  WallstreetProject 一键部署脚本"
echo "============================================"

# Step 1: Flutter Web 构建
echo ""
echo "[1/3] 构建 Flutter Web..."
cd "$CLIENT_DIR"
rm -rf .dart_tool build
flutter pub get
flutter build web --release
echo "✅ Flutter Web 构建完成"

# Step 2: Admin 构建
echo ""
echo "[2/3] 构建管理后台..."
cd "$ADMIN_DIR"
npm install --silent
npm run build
echo "✅ 管理后台构建完成"

# Step 3: 部署到 Cloudflare Pages
echo ""
echo "[3/3] 部署到 Cloudflare Pages..."
cd "$CLIENT_DIR"
wrangler pages deploy build/web --project-name wallstreet --commit-dirty=true

cd "$ADMIN_DIR"
wrangler pages deploy dist --project-name wallstreet-admin --commit-dirty=true

echo ""
echo "============================================"
echo "  🎉 部署完成！"
echo "  C端:      https://wallstreet.pages.dev"
echo "  管理后台:  https://wallstreet-admin.pages.dev"
echo "============================================"
