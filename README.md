# WallstreetProject

全平台实时股票行情系统 — 支持 Android / iOS / macOS / Linux / Windows / Web

## 架构概览

```
WallstreetProject/
├── client/               # Flutter 客户端（C端用户 + Web版）
├── server-go/            # Go 服务：实时行情 WebSocket 推送
├── server-python/        # Python FastAPI 服务：用户系统 + 管理后台API
├── admin/                # 管理后台前端（React）
├── scripts/              # 部署脚本、数据初始化
└── docs/                 # 项目文档
```

## 技术栈

| 层 | 技术 | 说明 |
|---|---|---|
| 跨平台客户端 | Flutter 3.x | 一套代码 6 个平台 |
| 管理后台 | React + TypeScript | 管理员专用 |
| 行情推送 | Go (Gin + WebSocket) | 高并发实时推送 |
| 业务 API | Python (FastAPI) | 用户系统/权限/数据 |
| 数据库 | PostgreSQL | Supabase 免费层 |
| 缓存 | Redis | Upstash 免费层 |
| 行情数据 | AKShare（验证阶段） | 聚合公开财经数据 |

## 色彩系统

```css
背景色: #182738, #0A2740
主色:   #0A2E67, #003EA5, #5DA3F3, #BADBFF
绿色系: #207700, #2FAC00 (A股跌)
红色系: #C13636, #FF5757 (A股涨)
警告色: #D57800, #FCB300
```

## 快速开始

```bash
# 安装依赖
make install

# 启动开发环境
make dev

# 运行测试
make test
```

## 免费部署方案

| 服务 | 平台 | 限制 |
|---|---|---|
| Flutter Web (C端) | Cloudflare Pages | 无限带宽 |
| 管理后台 | Cloudflare Pages | 无限带宽 |
| Go 服务 | Fly.io Free | 3台共享VM |
| Python 服务 | Fly.io Free | 3台共享VM |
| PostgreSQL | Supabase Free | 500MB |
| Redis | Upstash Free | 256MB |

**部署域名**: `https://wallstreet.pages.dev`（C端） / `https://wallstreet-admin.pages.dev`（管理后台）

详细部署步骤：见 [docs/DEPLOY.md](docs/DEPLOY.md)
