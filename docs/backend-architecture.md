# 后端项目架构文档

## 项目概述

后端基于 Python Flask 构建，采用领域驱动设计（DDD）和分层架构。

## 目录结构

```
api/
├── controllers/            # HTTP 控制器层
│   ├── console/           # 控制台 API
│   ├── service_api/       # 服务 API（外部调用）
│   ├── openapi/           # OpenAPI 规范接口
│   ├── files/             # 文件处理
│   └── ...
├── services/               # 业务逻辑层
│   ├── app/               # 应用服务
│   ├── workflow/          # 工作流服务
│   ├── dataset/           # 数据集服务
│   └── ...
├── core/                   # 核心领域层
│   ├── entities/          # 领域实体
│   ├── errors/            # 领域异常
│   ├── workflow/          # 工作流核心
│   ├── agent/             # Agent 核心
│   └── ...
├── repositories/           # 数据访问层
├── models/                 # SQLAlchemy 模型
├── tasks/                  # Celery 异步任务
├── extensions/             # Flask 扩展
├── libs/                   # 内部库
├── providers/              # LLM/Vector DB 提供商
├── fields/                 # Pydantic 字段定义
├── enums/                  # 枚举类型
├── constants/              # 常量定义
├── events/                 # 事件定义
├── configs/                # 配置管理
└── commands/               # CLI 命令
```

## 分层架构

```
HTTP Request
    ↓
controllers/           # 解析请求参数，参数校验
    ↓
services/              # 业务逻辑编排，事务管理
    ↓
core/                  # 领域实体，业务规则
    ↓
repositories/          # 数据持久化抽象
    ↓
models/                # SQLAlchemy 模型
    ↓
Database
```

## 核心模块

### 控制器层 (`controllers/`)

处理 HTTP 请求，解析输入并返回响应。

| 模块 | 说明 |
|------|------|
| `console/` | 控制台 API（需认证） |
| `service_api/` | 服务 API（外部应用调用） |
| `openapi/` | OpenAPI 规范接口 |
| `inner_api/` | 内部 API |

### 服务层 (`services/`)

核心业务逻辑所在，协调多个领域实体和仓库。

```
services/
├── app/                # 应用生命周期管理
├── workflow/           # 工作流执行引擎
├── dataset/            # RAG 数据集管理
├── account/            # 账户管理
├── tools/              # 工具管理
└── ...
```

### 核心层 (`core/`)

领域模型和业务规则，是系统最核心的代码。

```
core/
├── entities/           # 领域实体
├── errors/             # 领域异常
├── workflow/           # 工作流图结构、执行引擎
├── agent/              # Agent 推理逻辑
├── rag/                # RAG 检索逻辑
└── ...
```

### 任务系统 (`tasks/`)

基于 Celery 的异步任务处理。

```
tasks/
├── workflow.py         # 工作流异步任务
├── dataset.py          # 数据集任务（索引、导入）
└── ...
```

## 数据模型

SQLAlchemy 模型统一继承 `models.base.TypeBase`：

```python
from models.base import TypeBase

class Workflow(TypeBase):
    id: Mapped[str]
    name: Mapped[str]
    tenant_id: Mapped[str]
    # ...
```

## API 接口规范

使用 Pydantic 进行请求/响应 DTO 定义：

```python
from pydantic import BaseModel

class WorkflowCreateRequest(BaseModel):
    name: str
    graph: dict

    model_config = ConfigDict(extra="forbid")
```

## 配置管理

所有配置通过 `configs.dify_config` 访问，不直接读取环境变量：

```python
from configs import dify_config

api_key = dify_config.CONSOLE_API_KEY
```

## 异步任务

后台任务通过 Celery 执行，Redis 作为消息队列：

```python
from services.async_workflow_service import AsyncWorkflowService

AsyncWorkflowService.run(workflow_id, tenant_id)
```

## 测试

Pytest 测试框架

```bash
make test                           # 单元测试
make test TARGET_TESTS=./api/tests/xxx  # 指定测试
make test-all                       # 包含集成测试
```

## 代码质量

```bash
make format     # Ruff 代码格式化
make lint       # 完整 lint（格式化 + 检查 + 导入排序）
make type-check # MyPy 类型检查
```