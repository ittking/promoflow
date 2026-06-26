# PromoFlow

**Promo Flow** — 基于 Dify 二次开发的智能体定制化工作流平台，专为中小型企业私有化部署而设计。

## 产品定位

PromoFlow 面向需要私有化部署 AI 能力的中小企业，提供智能体定制化和工作流定制化服务。通过深度定制 Dify 核心功能，我们为客户构建专属的 AI 工作流平台。

## 项目架构

```
/api                    # Python Flask 后端 (领域驱动设计)
/web                    # Next.js 前端 (TypeScript + React)
/docker                 # Docker 容器化部署配置
/dify-agent             # Agent 后端服务
/packages               # 共享包:
  dify-ui              # 设计系统组件库
  iconify-collections  # SVG 图标集
  jotai-tanstack-form  # 表单状态管理
  contracts            # API 契约 (orpc)
/cli                   # 命令行工具
/e2e                    # 端到端测试 (Cucumber + Playwright)
/sdks                  # 多语言 SDK (Node.js)
```

### 核心模块

- **后端 API** (`/api`) — Flask 应用，遵循 DDD/Clean Architecture 分层架构
- **前端 Web** (`/web`) — Next.js 应用，提供可视化工作流编排界面
- **Docker 部署** (`/docker`) — 容器化部署配置，支持私有化环境

## 技术栈

### 后端
- Python 3.12+ / Flask
- PostgreSQL / Redis / Celery
- SQLAlchemy + Pydantic v2
- Ruff + MyPy + Pytest

### 前端
- Next.js 16 / React 19 / TypeScript 6
- TanStack Query + Jotai (状态管理)
- Tailwind CSS 4 / Vitest

## 快速开始

### 环境要求

- CPU >= 2 Core
- RAM >= 4 GiB
- Docker & Docker Compose

### 启动服务

```bash
cd docker
cp .env.example .env
docker compose up -d
```

访问 [http://localhost/install](http://localhost/install) 开始初始化。

### 开发环境

```bash
# 后端依赖
cd api && uv sync --dev

# 前端依赖
pnpm install
pnpm dev
```

## 许可证

基于 [Apache 2.0](LICENSE) 开源协议。