# 前端项目架构文档

## 项目概述

前端基于 Next.js 16 + React 19 + TypeScript 6 构建，提供可视化工作流编排界面。

## 目录结构

```
web/
├── app/                    # Next.js App Router 页面
│   ├── (commonLayout)/    # 通用布局（带侧边栏）
│   ├── (shareLayout)/     # 分享页布局
│   ├── account/           # 账户相关页面
│   ├── auth/              # 认证相关（登录、注册、OAuth）
│   ├── components/        # 共享组件
│   │   ├── base/          # 基础 UI 组件
│   │   └── workflow/      # 工作流画布组件
│   ├── install/           # 初始化安装页面
│   └── layout.tsx         # 根布局
├── features/              # 功能模块
│   ├── agent-v2/          # Agent V2 功能
│   ├── deployments/       # 部署管理
│   └── ...
├── service/               # API 服务层
│   ├── client.ts          # API 客户端配置
│   └── *(服务模块)        # 各业务域 API
├── hooks/                 # React Hooks
├── context/               # React Context
├── components/            # 共享组件库
├── utils/                 # 工具函数
├── types/                 # TypeScript 类型定义
├── models/                # 数据模型
├── i18n/                  # 国际化
│   └── en-US/            # 默认英文翻译
├── themes/                # 主题配置
└── public/                # 静态资源
```

## 核心模块

### App Router (`app/`)

基于 Next.js App Router 的文件路由系统，每个目录对应一个路由。

| 目录 | 说明 |
|------|------|
| `(commonLayout)/` | 通用布局，包含侧边栏导航 |
| `(shareLayout)/` | 分享页布局 |
| `account/` | 账户设置、成员管理 |
| `auth/` | 登录、注册、OAuth 回调 |
| `components/` | 共享 UI 组件 |
| `install/` | 首次安装初始化向导 |

### 组件系统 (`app/components/`)

```
components/
├── base/                  # 基础组件
│   ├── button/
│   ├── input/
│   ├── dialog/
│   └── ...
└── workflow/              # 工作流专用组件
    ├── nodes/             # 节点类型
    ├── canvas/            # 画布组件
    └── controls/          # 控制面板
```

### 服务层 (`service/`)

API 调用统一入口，使用 TanStack Query 进行数据获取和缓存。

```typescript
// 服务调用示例
import { useApps } from '@/service/use-apps'

function MyComponent() {
  const { data } = useApps()
  // ...
}
```

### 功能模块 (`features/`)

独立功能模块封装，如 Agent V2、部署管理等。

### 状态管理

- **组件级状态**: React `useState`
- **功能级状态**: Jotai atoms（同一功能内跨组件共享）
- **服务端状态**: TanStack Query（服务端数据缓存）

## 国际化

用户可见文本统一使用 `i18n/en-US/` 下的 key，不允许硬编码。

```typescript
// ✅ 正确
<t>workflow.nodes.agent.name</t>

// ❌ 错误
<span>Agent</span>
```

## 设计系统

UI 组件基于 `@langgenius/dify-ui` 包，图标使用 `packages/iconify-collections`。

### 覆盖层组件

使用 `@langgenius/dify-ui/*` 中的覆盖层组件（Dialog、Popover、Tooltip 等），遵循 `web/docs/overlay.md` 规范。

## 测试

Vitest + React Testing Library

```bash
pnpm test                              # 运行所有测试
pnpm test path/to/file.spec.tsx       # 运行单个测试文件
pnpm analyze-component <path>         # 分析组件复杂度
```

## 代码质量

```bash
pnpm lint:fix     # ESLint 自动修复
pnpm lint:tss     # 类型感知 lint
pnpm type-check   # TypeScript 类型检查
```