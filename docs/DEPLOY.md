# ============================================================
# WallstreetProject 部署指南
# 完全免费方案：Cloudflare Pages + Fly.io + Supabase + Upstash
# ============================================================

## 架构图

```
用户浏览器
    │
    ├── Flutter Web (Cloudflare Pages) ── wallstreet.pages.dev
    │       │
    │       ├── HTTP API ──► Python FastAPI (Fly.io) ─── wallstreet-python.fly.dev
    │       │                       │
    │       │                       ├── PostgreSQL (Supabase Free 500MB)
    │       │                       └── Redis (Upstash Free 256MB)
    │       │
    │       └── WebSocket ──► Go Gin WS (Fly.io) ─── wallstreet-go.fly.dev
    │                               │
    │                               └── AKShare (行情数据源)
    │
    └── Admin (Cloudflare Pages) ─── admin.wallstreet.pages.dev
                                        │
                                        └── HTTP API ──► Python FastAPI
```

## 前置条件

1. GitHub 帐号
2. Cloudflare 帐号（注册免费: https://dash.cloudflare.com/sign-up）
3. Fly.io 帐号（注册: https://fly.io，需要信用卡验证但免费层不收费）
4. Supabase 帐号（注册免费: https://supabase.com）
5. Upstash 帐号（注册免费: https://upstash.com）

## 第一步：Supabase 数据库（PostgreSQL）

1. 打开 https://supabase.com → New Project
2. 项目名: wallstreet
3. 密码: 自己设置一个随机强密码
4. Region: Northeast Asia (Tokyo) — 对中国访问最快
5. 创建后，在 Project Settings → Database → Connection String
6. 复制 URI 格式的连接字符串
7. 记下来，后续配置要用

## 第二步：Upstash Redis（缓存）

1. 打开 https://console.upstash.com → Create Database
2. Region: 选择 Asia Pacific 节点
3. 创建后复制 Redis URL（redis://...）和 Token
4. 记下来

## 第三步：Fly.io 部署 Go 服务

```bash
# 安装 Fly.io CLI
curl -L https://fly.io/install.sh | sh

# 登录
flyctl auth signup

# 创建 Go 应用
cd server-go
flyctl launch --config ../fly-go.toml

# 设置环境变量
flyctl secrets set REDIS_ADDR="你的Upstash Redis地址"

# 部署
flyctl deploy

# 查看状态
flyctl status
```

部署成功后 Go 服务的 URL: `https://wallstreet-go.fly.dev`

## 第四步：Fly.io 部署 Python 服务

```bash
cd server-python

# 修改 fly-python.toml 中的环境变量
# 或者用命令行设置密文

flyctl launch --config ../fly-python.toml

# 设置数据库和 JWT 密文
flyctl secrets set DATABASE_URL="你的Supabase连接字符串"
flyctl secrets set REDIS_URL="你的Upstash Redis URL"
flyctl secrets set JWT_SECRET="随机生成一个长字符串"

# 部署
flyctl deploy
```

部署成功后 Python 服务的 URL: `https://wallstreet-python.fly.dev`

## 第五步：Cloudflare Pages 部署 Flutter Web（C端）

### 方式一：通过 Dashboard（最简单）

1. 打开 https://dash.cloudflare.com/
2. Workers & Pages → Create → Pages
3. 选择「Upload assets」
4. 项目名称输入: `wallstreet`
5. 运行本地构建:
   ```bash
   cd client
   flutter build web --release
   ```
6. 将 `client/build/web` 整个文件夹拖入 Cloudflare 上传区域
7. 点击「Deploy site」
8. 🎉 你的网站: `https://wallstreet.pages.dev`

### 方式二：关联 GitHub 自动部署（推荐）

1. 将整个项目推送到 GitHub
2. Cloudflare Pages → Create a project → Connect to Git
3. 选择你的仓库
4. 构建设置:
   - **Framework preset**: None（手动设置）
   - **Build command**: `cd client && flutter pub get && flutter build web --release`
   - **Build output directory**: `client/build/web`
   - **Root directory**: /
5. 添加环境变量:
   - `PYTHON_API_URL` = `https://wallstreet-python.fly.dev`
   - `GO_WS_URL` = `wss://wallstreet-go.fly.dev/ws`
6. 点击「Save and Deploy」
7. 之后每次 `git push` 会自动构建部署

⚠️ **注意**: Cloudflare Pages 的构建环境需要 Flutter SDK。如果自动构建失败，改用本地构建 + 手动上传的方式。

### 方式三：使用 Wrangler CLI

```bash
npm install -g wrangler
wrangler login
cd client && flutter build web --release
wrangler pages deploy build/web --project-name=wallstreet
```

## 第六步：Cloudflare Pages 部署管理后台

同上，项目名设为 `wallstreet-admin`:
```bash
cd admin && npm run build
wrangler pages deploy dist --project-name=wallstreet-admin
```
管理后台 URL: `https://wallstreet-admin.pages.dev`

## 第七步：配置域名

如果将来有预算购买域名（如 `wallstreet.cc` 等便宜域名），可以：
1. 将域名 DNS 托管到 Cloudflare
2. 在 Cloudflare Pages → Custom domains 中添加
3. Cloudflare 免费提供 SSL 证书

在购买域名前，直接使用 Cloudflare 提供的 `*.pages.dev` 子域名完全够用。

## 费用总结

| 服务 | 用途 | 免费额度 |
|---|---|---|
| Cloudflare Pages | Flutter Web + Admin | 无限带宽，500次构建/月 |
| Fly.io | Go + Python 服务 | 3台共享VM（256MB RAM each） |
| Supabase | PostgreSQL | 500MB 存储，2GB 传输/月 |
| Upstash | Redis 缓存 | 256MB 存储，10K 命令/天 |

**总计: ¥0 / 月**

## 验证部署

```bash
# 检查 Go 服务
curl https://wallstreet-go.fly.dev/health
# → {"status": "ok", "service": "wallstreet-go"}

# 检查 Python 服务
curl https://wallstreet-python.fly.dev/health
# → {"status": "ok", "service": "wallstreet-python"}

# 测试搜索
curl "https://wallstreet-python.fly.dev/api/v1/search/stocks?q=茅台"
# → {"results": [{"code": "600519", "name": "贵州茅台", "market": "sh"}]}

# 在浏览器打开
open https://wallstreet.pages.dev
```

## 限制和扩容路径

这些免费方案适合 **开发验证和少量用户初期使用**。当用户增长时：

- Cloudflare Pages → 直接扩容，仍然免费
- Fly.io → 升级到 $1.94/月的 micro VM
- Supabase → 升级到 $25/月的 Pro 计划
- 行情数据源 → 对接万得 / 同花顺 iFinD 商业 API

在验证阶段（初期 < 100 用户），这些免费方案完全够用。
