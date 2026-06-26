# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dify is an open-source LLM app development platform combining AI workflows, RAG pipelines, agent capabilities, and model management.

### Codebase Structure

```
/api                    # Python Flask backend (DDD/Clean Architecture)
/web                    # Next.js frontend (TypeScript, React)
/docker                 # Docker Compose configurations
/dify-agent             # Agent backend services
/packages               # Shared packages:
  dify-ui              # Design system components
  iconify-collections  # Custom SVG icon collections
  jotai-tanstack-form  # Form state management
  contracts            # API contracts (orpc)
/cli                   # CLI tools
/e2e                    # End-to-end tests (Cucumber + Playwright)
/sdks                  # Language SDKs (Node.js)
```

## Backend Development

**Run backend CLI commands via `uv run --project api <command>`**

### Key Commands
```bash
# Development setup
make dev-setup         # Full environment setup (Docker + web + api)
make prepare-docker    # Start Docker middleware (PostgreSQL, Redis, Weaviate)
make prepare-web       # Install frontend dependencies
make prepare-api       # Install Python deps, run migrations

# Code quality
make format            # Format with ruff
make lint              # Format + fix + lint (ruff, imports, dotenv)
make type-check        # Run pyrefly + mypy
make test              # Unit tests (or TARGET_TESTS=./api/tests/<path>)
make test-all          # Full test suite including Docker-backed integration tests

# Single test
uv run --project api --dev pytest api/tests/unit_tests/services/test_something.py -v
```

### Architecture (Backend)
- **Controllers** (`api/controllers/`) — HTTP entry points, parse input via Pydantic, return serialized responses
- **Services** (`api/services/`) — Business logic, coordinate repositories and background tasks
- **Core** (`api/core/`) — Domain entities, errors, and shared utilities
- **Repositories** (`api/repositories/`) — Data access abstraction for large/queried tables
- **Models** (`api/models/`) — SQLAlchemy models inheriting from `models.base.TypeBase`
- **Tasks** (`api/tasks/`) — Celery background tasks with explicit queue selection

### Backend Conventions
- Use `configs.dify_config` for configuration—never read environment variables directly
- Maintain tenant awareness end-to-end; `tenant_id` must flow through every layer
- Queue async work through `services/async_workflow_service`
- Storage access via `extensions.ext_storage.storage`
- HTTP outbound via `core.helper.ssrf_proxy`
- Keep files below ~800 lines; split when necessary

## Frontend Development

**Run from `/web` directory or prefix with `pnpm -C web`**

### Key Commands
```bash
# Development
pnpm dev               # Start dev server (http://localhost:3000)
pnpm dev:proxy         # Dev server with backend proxy
pnpm build             # Production build

# Code quality
pnpm lint:fix          # Auto-fix ESLint issues
pnpm lint:tss          # Type-aware linting (TSSLint)
pnpm type-check        # Full TypeScript check (tsgo)

# Testing
pnpm test              # Run Vitest tests
pnpm test path/file.spec.tsx   # Run specific test file
pnpm test --coverage   # With coverage report
pnpm analyze-component path    # Analyze component complexity
```

### Architecture (Frontend)
- **App routes** (`web/app/`) — Next.js App Router pages and layouts
- **Features** (`web/features/`) — Feature-scoped modules (e.g., `agent-v2`, `deployments`)
- **Components** (`web/app/components/`) — Shared UI components
  - `base/` — Base components
  - `workflow/` — Workflow canvas nodes and controls
- **Packages** (`/packages/dify-ui`) — Design system primitives (Button, Dialog, Select, etc.)

### Frontend Conventions
- User-facing strings must use `web/i18n/en-US/` keys, never hardcoded text
- New SVG icons: add to `packages/iconify-collections/assets/`, run `pnpm --filter @dify/iconify-collections generate`
- Use `@langgenius/dify-ui/*` primitives for overlays; see `web/docs/overlay.md`
- State management: local state → Jotai atoms (feature-level) → existing feature stores
- Agent V2 lives in `web/features/agent-v2` with `agent_node_kind: 'dify_agent'` discriminator

## Testing

### Backend
- Use `pytest` with Arrange-Act-Assert structure
- Unit tests: `api/tests/unit_tests/`
- Integration tests: `api/tests/integration_tests/` (CI-only, require Docker middleware)
- Run: `make test` or `make test-all` (includes Docker-backed tests)

### Frontend
- Vitest + React Testing Library
- File naming: `ComponentName.spec.tsx` in `__tests__/` sibling directory
- Use `pnpm analyze-component <path>` to guide testing strategy for complex components
- Follow `web/docs/test.md` for complete testing guidelines

## Important Project Conventions

1. **Docstrings required** — Before editing backend code, read module/class/function docstrings; treat them as spec
2. **No `Any` types** — Use explicit type annotations; prefer `TypedDict` over `dict` for structured data
3. **i18n for all UI text** — User-facing strings use `web/i18n/en-US/` keys
4. **Pydantic v2 for DTOs** — Use `ConfigDict(extra="forbid")`, validators for domain rules
5. **SQLAlchemy sessions** — Always use context managers: `with Session(db.engine, expire_on_commit=False) as session:`
6. **Logging** — Use `logger = logging.getLogger(__name__)`; never use `print`
7. **Error handling** — Raise domain exceptions in services, translate to HTTP in controllers

## Detailed Documentation

- Backend details: `api/AGENTS.md`
- Frontend details: `web/AGENTS.md`
- Testing guidelines: `web/docs/test.md`, `web/docs/lint.md`
- Design system: `packages/dify-ui/README.md`