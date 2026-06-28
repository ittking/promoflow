# PromoFlow 部署指南

本文档介绍如何将 PromoFlow（基于 Dify）构建为 Docker 镜像并部署到甲方服务器。

## 目录

- [架构概述](#架构概述)
- [镜像仓库配置](#镜像仓库配置)
- [本地构建镜像](#本地构建镜像)
- [推送到阿里云](#推送到阿里云)
- [甲方部署指南](#甲方部署指南)
- [DSL 文件导入](#dsl-文件导入)
- [常见问题](#常见问题)

---

## 架构概述

### 服务组件

PromoFlow 由多个 Docker 容器组成：

| 服务 | 镜像 | 说明 |
|------|------|------|
| `api` | `dify-api` | 后端 API 服务 |
| `worker` | `dify-api` | 异步任务 Worker |
| `worker_beat` | `dify-api` | 定时任务调度 |
| `web` | `dify-web` | 前端 Web 应用 |
| `db_postgres` | `postgres:15-alpine` | PostgreSQL 数据库 |
| `redis` | `redis:6-alpine` | Redis 缓存/消息队列 |
| `nginx` | `nginx:latest` | 反向代理 |
| `sandbox` | `dify-sandbox:0.2.15` | 代码执行沙箱 |
| `plugin_daemon` | `dify-plugin-daemon:0.6.3-local` | 插件服务 |
| `ssrf_proxy` | `ubuntu/squid` | SSRF 防护代理 |
| `init_permissions` | `busybox:latest` | 权限初始化 |

### 部署流程

```
┌──────────────────┐      push       ┌──────────────────┐      pull       ┌──────────────────┐
│  本地开发机器    │ ────────────→   │  阿里云镜像仓库   │ ────────────→   │  甲方服务器      │
│  make build      │                 │                  │                 │  docker compose  │
└──────────────────┘                 └──────────────────┘                 └──────────────────┘
```

---

## 镜像仓库配置

### 阿里云容器镜像服务

本项目使用阿里云容器镜像服务作为私有镜像仓库。

**仓库信息：**
- 仓库地址：`crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com`
- 命名空间：`mnwm`

### 首次登录

```bash
docker login --username=17602235676 crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com
```

根据提示输入密码（需要在阿里云控制台设置访问密码）。

---

## 本地构建镜像

### Makefile 命令说明

项目提供了完整的 Makefile 命令来构建和推送镜像：

```bash
# 构建命令
make build-aliyun-web       # 构建 Web 镜像
make build-aliyun-api       # 构建 API 镜像
make build-aliyun-base      # 构建基础镜像 (postgres, redis, nginx 等)
make build-aliyun-all       # 构建所有阿里云镜像

# 推送命令
make push-aliyun-web        # 推送 Web 镜像
make push-aliyun-api        # 推送 API 镜像
make push-aliyun-base       # 推送基础镜像
make push-aliyun-all        # 推送所有镜像

# 构建并推送（一条命令搞定）
make build-push-aliyun-all  # 构建并推送所有镜像到阿里云
```

### 构建所有镜像

```bash
# 先登录阿里云（只需一次）
docker login --username=17602235676 crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com

# 构建并推送所有镜像到阿里云
make build-push-aliyun-all
```

### 镜像清单

执行 `make build-push-aliyun-all` 会处理以下镜像：

| 镜像 | 标签 | 用途 |
|------|------|------|
| `dify-api` | latest | 后端 API + Worker + Beat |
| `dify-web` | latest | 前端 Web |
| `postgres` | 15-alpine | 数据库 |
| `redis` | 6-alpine | 缓存 |
| `nginx` | latest | 反向代理 |
| `ubuntu-squid` | latest | SSRF 防护 |
| `busybox` | latest | 初始化 |
| `dify-sandbox` | 0.2.15 | 代码沙箱 |
| `dify-plugin-daemon` | 0.6.3-local | 插件服务 |

---

## 推送到阿里云

### 推送单个镜像

```bash
# 登录后，给镜像打标签并推送
docker tag langgenius/dify-api:latest crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com/mnwm/dify-api:latest
docker push crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com/mnwm/dify-api:latest
```

### 验证推送

在阿里云容器镜像控制台查看已推送的镜像：
https://cr.console.aliyun.com

---

## 甲方部署指南

### 部署包清单

甲方部署需要提供以下文件：

```
部署包/
├── docker-compose.yaml      # 编排文件（已修改为阿里云镜像地址）
├── .env                     # 环境变量配置
├── volumes/                 # 目录结构（空目录，用于数据挂载）
│   ├── app/storage/         # API 存储目录
│   ├── db/data/             # 数据库数据目录
│   ├── redis/data/          # Redis 数据目录
│   ├── sandbox/             # 沙箱相关目录
│   └── ...
└── DSL文件/                 # 导出的应用配置（可选）
    └── *.yaml
```

### 部署步骤

#### 1. 拷贝部署文件

将部署包拷贝到甲方服务器的指定目录，例如 `/opt/promoflow`：

```bash
scp -r ./部署包 user@甲方服务器:/opt/promoflow
```

#### 2. 登录镜像仓库

```bash
cd /opt/promoflow
docker login --username=17602235676 crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com
```

#### 3. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，修改以下关键配置：
```

**必须修改的配置：**

```bash
# 域名配置
CONSOLE_API_URL=https://your-domain.com
CONSOLE_WEB_URL=https://your-domain.com
SERVICE_API_URL=https://your-domain.com
APP_API_URL=https://your-domain.com
APP_WEB_URL=https://your-domain.com

# 数据库密码（建议修改）
DB_PASSWORD=your_secure_password
REDIS_PASSWORD=your_secure_password

# 密钥（建议修改）
SECRET_KEY=your_secret_key

# Nginx 配置
NGINX_SERVER_NAME=your-domain.com
```

#### 4. 启动服务

```bash
# 启动所有服务
docker compose up -d

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f
```

#### 5. 执行数据库迁移

首次部署或更新数据库结构后，需要执行数据库迁移：

```bash
docker compose exec api flask db upgrade
```

#### 6. 验证部署

访问 `http://甲方服务器IP` 或配置的域名，确认 Web 界面正常显示。

### 停止服务

```bash
# 停止服务（保留数据）
docker compose stop

# 停止并删除容器（保留数据）
docker compose down

# 停止并删除容器和数据卷（慎用！）
docker compose down -v
```

---

## DSL 文件导入

### 导出 DSL 文件

在本地开发环境中：

1. 登录 PromoFlow Web 管理界面
2. 进入目标应用
3. 点击「...」→「导出 DSL」

### 导入 DSL 文件

在甲方部署环境中：

1. 登录 PromoFlow Web 管理界面
2. 点击「创建应用」→「导入 DSL」
3. 上传 `.yaml` 文件

### API 导入（可选）

```bash
curl -X POST "http://localhost:5001/v1/workflows/import" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@workflow.yaml"
```

---

## 常见问题

### 1. 镜像拉取失败

**问题：** `Error response from daemon: pull access denied`

**解决：** 检查阿里云登录状态，重新登录：
```bash
docker logout crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com
docker login --username=17602235676 crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com
```

### 2. 端口被占用

**问题：** `port is already allocated`

**解决：** 检查 80、443、5001 等端口是否被占用，或修改 `.env` 中的端口配置：
```bash
EXPOSE_NGINX_PORT=8080
EXPOSE_NGINX_SSL_PORT=8443
```

### 3. 数据库连接失败

**问题：** `could not connect to server`

**解决：** 确保 PostgreSQL 和 Redis 已正常启动：
```bash
docker compose up -d db_postgres redis
sleep 10  # 等待数据库启动
docker compose up -d
```

### 4. 内存不足

**问题：** `cannot allocate memory`

**解决：** 增加 Docker 分配内存，建议至少 8GB。

### 5. 域名访问异常

**问题：** 页面显示不正常或资源加载失败

**解决：** 检查 `.env` 中的 URL 配置是否正确，包括协议（http/https）和端口。

### 6. 页面报错或接口 400 错误

**问题：** 部署后页面报错，部分接口返回 400 错误

**解决：** 可能是数据库未迁移导致，执行：

```bash
docker compose exec api flask db upgrade
```

---

## 附录：完整命令参考

### 本地开发环境

```bash
make dev-setup      # 初始化开发环境
make dev-clean      # 清理开发环境
make test           # 运行单元测试
make lint           # 代码检查
```

### Docker 镜像构建

```bash
# 构建推送到阿里云（完整）
make build-push-aliyun-all

# 单独构建
make build-aliyun-web
make build-aliyun-api
make build-aliyun-base

# 单独推送
make push-aliyun-web
make push-aliyun-api
make push-aliyun-base
```

### 甲方服务器操作

```bash
# 启动
docker compose up -d

# 查看状态
docker compose ps

# 查看日志
docker compose logs -f api
docker compose logs -f web

# 重启
docker compose restart

# 停止
docker compose down
```