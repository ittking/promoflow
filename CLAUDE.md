# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

PromoFlow 是基于 Dify 二次开发的智能体定制化工作流平台，面向中小型企业私有化部署。

核心模块：
- `/api` — Python Flask 后端，DDD/Clean Architecture 分层架构
- `/web` — Next.js 前端，TypeScript + React
- `/docker` — Docker 容器化部署配置
- `/dify-agent` — Agent 后端服务
- `/packages` — 共享包（dify-ui 设计系统、iconify-collections 图标集、contracts API 契约）

## 常用命令

### 后端开发
```bash
# 格式化
make format

# 检查
make check

# Lint（格式化 + 修复 + 契约检查 + 导入检查 + dotenv 检查）
make lint

# 类型检查（pyrefly + mypy）
make type-check

# 运行单元测试
make test

# 运行完整测试（包括 Docker 支持的集成测试）
make test-all

# 指定测试目标
make test TARGET_TESTS=./api/tests/unit_tests/some_test.py

# 开发环境准备
make dev-setup
make dev-clean
```

### 前端开发
```bash
cd web
pnpm install
pnpm dev          # 开发服务器
pnpm build        # 构建
pnpm lint:fix     # ESLint 自动修复
pnpm type-check   # 类型检查
```

### Docker
```bash
cd docker
docker compose up -d
```

## 后端架构要点

- **分层架构**：controller → service → core/domain
- **配置**：通过 `configs.dify_config` 访问配置，禁止直接读取环境变量
- **数据库**：使用 SQLAlchemy，Models 继承 `models.base.TypeBase`，通过 context manager 管理 session
- **异步任务**：通过 Celery + Redis 处理，`services/async_workflow_service` 调度，`tasks/` 目录实现具体任务
- **错误处理**：领域特定异常放在 `services/errors`、`core/errors`，controller 层统一转换
- **日志**：使用 `logger = logging.getLogger(__name__)`，重试事件用 warning，最终失败用 error
- **类型**：Python 3.12+，使用 `TypedDict` 代替 `dict`，避免 `Any`，所有公开 API 必须有类型注解

详细规范见 `api/AGENTS.md`。

## 前端架构要点

- **状态管理**：TanStack Query 作服务端状态源，Jotai 作客户端状态
- **组件**：使用 `@langgenius/dify-ui/*` 组件库
- **i18n**：用户可见字符串必须使用 `web/i18n/en-US/` 键值，禁止硬编码
- **图标**：自定义 SVG 图标放在 `packages/iconify-collections/assets/`，通过 `pnpm --filter @dify/iconify-collections generate` 生成
- **Agent V2**：与 legacy workflow Agent 分离，放在 `web/features/agent-v2`

详细规范见 `web/AGENTS.md`。

## 代码审查

- 后端：使用 `backend-code-review` skill
- 前端：使用 `frontend-code-review` skill
- PR 提交前必须运行：`make lint && make type-check && make test`