# WallstreetProject 部署流程 — 分步指南

## 注册 → 构建 → 部署（全部免费）

本指南将带你一步一步完成 WallstreetProject 的部署。每个步骤都标注了在你自己电脑上终端（Terminal）中执行的命令。

---

## 前置条件检查

在开始之前，确保你的电脑已安装以下工具：

```bash
# 检查版本（每个工具都需要安装）
flutter --version    # Flutter 3.x+
go version           # Go 1.22+
python3 --version    # Python 3.12+
node --version       # Node.js 20+
```

如果缺少某个工具，安装链接：
- Flutter: https://docs.flutter.dev/get-started/install
- Go: https://go.dev/dl/
- Python: https://www.python.org/downloads/
- Node.js: https://nodejs.org/

---

## 第一步：注册 Supabase（PostgreSQL）

这是完全免费的托管数据库服务。

1. 浏览器打开：**https://supabase.com**
2. 点击「Start your project」注册（可用 GitHub 登录）
3. 注册后创建新项目：
   - **Name**: `wallstreet`
   - **Database Password**: 点击「Generate a password」，**务必复制保存**
   - **Region**: **Northeast Asia (Tokyo)** — 对中国用户访问最快
   - **Pricing Plan**: Free（免费层）
4. 点击「Create project」，等待约 2 分钟初始化
5. 进入 **Project Settings → Database → Connection String**
6. 选择 **URI** 标签，复制整个连接字符串
7. 看起来类似: `postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres`

> 📝 **保存这个字符串，后面要用**

---

## 第二步：注册 Upstash（Redis 缓存）

1. 浏览器打开：**https://console.upstash.com**
2. 用 GitHub/Google 注册登录
3. 点击「Create Database」
4. 选择 **Redis**
5. **Region**: 选择 Asia Pacific 区域
6. **Plan**: Free（256MB）
7. 创建后，复制 **Redis URL**（格式: `redis://default:password@xxx.upstash.io:6379`）

> 📝 **保存这个 URL，后面要用**

---

## 第三步：注册 Cloudflare

1. 浏览器打开：**https://dash.cloudflare.com/sign-up**
2. 注册免费帐号，完成邮箱验证
3. 进入 Dashboard 首页

---

## 第四步：安装 Wrangler CLI + Cloudflare Pages

在终端执行：

```bash
# 安装 Wrangler（Cloudflare CLI）
npm install -g wrangler

# 登录 Cloudflare
wrangler login
# 会弹出浏览器，完成授权
```

---

## 第五步：部署 Flutter Web 客户端到 Cloudflare Pages

```bash
# 进入 Flutter 客户端目录
cd /Users/Leslie/Documents/260613_ClaudeCodeProject/260613_WallstreetProject/client

# 获取依赖
flutter pub get

# 构建 Web 版本（Canvaskit 渲染，性能最优）
flutter build web --release --web-renderer canvaskit

# 部署到 Cloudflare Pages
wrangler pages deploy build/web --project-name wallstreet --commit-dirty=true

# 🎉 部署完成！访问:
# https://wallstreet.pages.dev
```

---

## 第六步：部署管理后台到 Cloudflare Pages

```bash
cd /Users/Leslie/Documents/260613_ClaudeCodeProject/260613_WallstreetProject/admin

# 安装依赖 + 构建
npm install
npm run build

# 部署
wrangler pages deploy dist --project-name wallstreet-admin --commit-dirty=true

# 🎉 访问: https://wallstreet-admin.pages.dev
```

---

## 第七步：安装 Fly.io CLI

```bash
# macOS / Linux
curl -L https://fly.io/install.sh | sh

# 登录（会打开浏览器注册，需要信用卡验证但免费层不收费）
flyctl auth signup
# 或如果已有帐号:
flyctl auth login
```

---

## 第八步：部署 Python 服务到 Fly.io

```bash
cd /Users/Leslie/Documents/260613_ClaudeCodeProject/260613_WallstreetProject/server-python

# 首次部署 — 创建 App
flyctl launch --name wallstreet-python --region nrt

# 交互提示：
#   ? Choose a region for deployment: Tokyo, Japan (nrt) ← 选这个
#   ? Would you like to set up a Postgresql database now? No
#   ? Would you like to set up an Upstash Redis database now? No
#   ? Would you like to deploy now? Yes
#   ? Do you want to tweak these settings before deploying? No

# 设置密文（替换为你的实际值）
flyctl secrets set \
  DATABASE_URL="postgresql://postgres:[你的Supabase密码]@db.xxxxx.supabase.co:5432/postgres" \
  REDIS_URL="redis://default:[你的Upstash密码]@xxx.upstash.io:6379" \
  JWT_SECRET="$(openssl rand -hex 32)" \
  --app wallstreet-python

# 部署
flyctl deploy

# 等待完成后验证:
curl https://wallstreet-python.fly.dev/health
# 应该返回: {"status":"ok","service":"wallstreet-python"}
```

---

## 第九步：部署 Go 服务到 Fly.io

```bash
cd /Users/Leslie/Documents/260613_ClaudeCodeProject/260613_WallstreetProject/server-go

# 首次部署 — 创建 App
flyctl launch --name wallstreet-go --region nrt

# 交互提示选 No to DB/Redis 问题

# 设置环境变量
flyctl secrets set \
  REDIS_ADDR="redis://default:[你的Upstash密码]@xxx.upstash.io:6379" \
  --app wallstreet-go

# 部署
flyctl deploy

# 验证:
curl https://wallstreet-go.fly.dev/health
# 应该返回: {"status":"ok","service":"wallstreet-go"}
```

---

## 第十步：连接服务

告诉 Flutter Web 客户端后端 API 地址。在 Cloudflare Pages Dashboard 设置环境变量：

1. 打开 https://dash.cloudflare.com/
2. Workers & Pages → wallstreet
3. Settings → Environment variables
4. 添加变量：
   - `PYTHON_API_URL` = `https://wallstreet-python.fly.dev`
   - `GO_WS_URL` = `wss://wallstreet-go.fly.dev/ws`
5. 点击 Save → 触发重新部署

---

## 第十一步：验证全链路

```bash
# 1. Python API 正常
curl https://wallstreet-python.fly.dev/health

# 2. Go WebSocket 正常
curl https://wallstreet-go.fly.dev/health

# 3. 股票搜索正常
curl "https://wallstreet-python.fly.dev/api/v1/search/stocks?q=茅台"

# 4. 打开浏览器访问
open https://wallstreet.pages.dev
open https://wallstreet-admin.pages.dev
```

## 管理后台默认帐号

- **用户名**: admin
- **密码**: admin123（首次登录后请在设置中修改）

---

## 常见问题排查

### Flutter build web 失败
```bash
flutter clean && flutter pub get && flutter build web --release
```

### Wrangler 部署返回 401/403
```bash
wrangler login   # 重新登录
wrangler whoami  # 检查登录状态
```

### Fly.io 部署失败
```bash
flyctl logs --app wallstreet-python  # 查看日志
flyctl deploy --app wallstreet-python  # 重新部署
```

### Supabase 连接失败
检查 DATABASE_URL 是否正确，密码中特殊字符需要 URL 编码：
```bash
# 用 Python 编码特殊密码
python3 -c "from urllib.parse import quote; print(quote('你的密码', safe=''))"
```

### Cloudflare Pages 构建环境没有 Flutter
Cloudflare Pages 的 CI 环境不自带 Flutter SDK。所以推荐**本地构建 + 上传**方式：
```bash
cd client && flutter build web --release
wrangler pages deploy build/web --project-name wallstreet --commit-dirty=true
```

---

## 费用总结

| 服务 | 用途 | 状态 | 费用 |
|---|---|---|---|
| Cloudflare Pages | 前端 + 后台 | ✅ | ¥0/月 |
| Fly.io (Go) | 行情推送 | ✅ | $0/月 |
| Fly.io (Python) | 用户API | ✅ | $0/月 |
| Supabase | PostgreSQL | ✅ | ¥0/月 |
| Upstash | Redis 缓存 | ✅ | ¥0/月 |
| **总计** | | | **¥0/月** |

## 你的域名

- **C端**: `https://wallstreet.pages.dev`
- **管理后台**: `https://wallstreet-admin.pages.dev`

将来如果购买了 `wallstreet.cc` 之类的域名（约 ¥35/年），可以在 Cloudflare Pages → Custom Domains 中绑定。
