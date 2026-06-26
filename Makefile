# 变量
DOCKER_REGISTRY=langgenius
WEB_IMAGE=$(DOCKER_REGISTRY)/dify-web
API_IMAGE=$(DOCKER_REGISTRY)/dify-api
VERSION=latest
DOCKER_DIR=docker
DOCKER_MIDDLEWARE_ENV=$(DOCKER_DIR)/middleware.env
DOCKER_MIDDLEWARE_ENV_EXAMPLE=$(DOCKER_DIR)/envs/middleware.env.example
DOCKER_MIDDLEWARE_PROJECT=dify-middlewares-dev

# 开发服务端口
DEV_API_PORT?=5001
DEV_PROXY_PORT?=3001

# 默认目标 - 显示帮助
.DEFAULT_GOAL := help

# 后端开发环境配置
.PHONY: dev-setup prepare-docker prepare-web prepare-api

# 开发环境配置目标
dev-setup: prepare-docker prepare-web prepare-api
	@echo "✅ 后端开发环境配置完成!"

# 步骤 1: 准备 Docker 中间件
prepare-docker:
	@echo "🐳 正在配置 Docker 中间件..."
	@if [ ! -f "$(DOCKER_MIDDLEWARE_ENV)" ]; then \
		cp "$(DOCKER_MIDDLEWARE_ENV_EXAMPLE)" "$(DOCKER_MIDDLEWARE_ENV)"; \
		echo "已创建 Docker middleware.env"; \
	else \
		echo "Docker middleware.env 已存在"; \
	fi
	@cd $(DOCKER_DIR) && docker compose -f docker-compose.middleware.yaml --env-file middleware.env -p $(DOCKER_MIDDLEWARE_PROJECT) up -d
	@echo "✅ Docker 中间件已启动"

# 步骤 2: 准备前端环境
prepare-web:
	@echo "🌐 正在配置前端环境..."
	@cp -n web/.env.example web/.env.local 2>/dev/null || echo "Web .env.local 已存在"
	@pnpm install
	@echo "✅ 前端环境已准备(未启动)"

# 步骤 3: 准备 API 环境
prepare-api:
	@echo "🔧 正在配置 API 环境..."
	@cp -n api/.env.example api/.env 2>/dev/null || echo "API .env 已存在"
	@cd api && uv sync --dev
	@cd api && uv run flask db upgrade
	@echo "✅ API 环境已准备(未启动)"

# 清理开发环境
dev-clean:
	@echo "⚠️  正在停止 Docker 容器..."
	@if [ -f "$(DOCKER_MIDDLEWARE_ENV)" ]; then \
		cd $(DOCKER_DIR) && docker compose -f docker-compose.middleware.yaml --env-file middleware.env -p $(DOCKER_MIDDLEWARE_PROJECT) down; \
	else \
		echo "Docker middleware.env 不存在,跳过 compose down"; \
	fi
	@echo "🗑️  正在删除数据卷..."
	@rm -rf docker/volumes/db
	@rm -rf docker/volumes/mysql
	@rm -rf docker/volumes/redis
	@rm -rf docker/volumes/plugin_daemon
	@rm -rf docker/volumes/weaviate
	@rm -rf docker/volumes/sandbox/dependencies
	@rm -rf api/storage
	@echo "✅ 清理完成"

# 后端代码质量命令
format:
	@echo "🎨 正在运行 ruff format..."
	@uv run --project api --dev ruff format ./api
	@echo "✅ 代码格式化完成"

check:
	@echo "🔍 正在运行 ruff check..."
	@uv run --project api --dev ruff check ./api
	@echo "✅ 代码检查完成"

lint:
	@echo "🔧 正在运行 ruff format、check with fixes、response contract lint、import linter 和 dotenv-linter..."
	@uv run --project api --dev ruff format ./api
	@uv run --project api --dev ruff check --fix ./api
	@$(MAKE) api-contract-lint
	@uv run --directory api --dev lint-imports
	@uv run --project api --dev dotenv-linter ./api/.env.example ./web/.env.example
	@echo "✅ 代码检查完成"

api-contract-lint:
	@echo "🔎 正在检查 Flask response contracts..."
	@uv run --project api --dev python api/dev/lint_response_contracts.py
	@echo "✅ Response contract 检查完成"

type-check:
	@echo "📝 正在运行类型检查 (pyrefly + mypy)..."
	@./dev/pyrefly-check-local $(PATH_TO_CHECK)
	@uv --directory api run mypy --exclude-gitignore --exclude '(^|/)conftest\.py$$' --exclude 'tests/' --exclude 'migrations/' --exclude 'dev/generate_swagger_specs.py' --exclude 'dev/generate_fastopenapi_specs.py' --check-untyped-defs --disable-error-code=import-untyped .
	@echo "✅ 类型检查完成"

type-check-core:
	@echo "📝 正在运行核心类型检查 (pyrefly + mypy)..."
	@./dev/pyrefly-check-local $(PATH_TO_CHECK)
	@uv --directory api run mypy --exclude-gitignore --exclude '(^|/)conftest\.py$$' --exclude 'tests/' --exclude 'migrations/' --exclude 'dev/generate_swagger_specs.py' --exclude 'dev/generate_fastopenapi_specs.py' --check-untyped-defs --disable-error-code=import-untyped .
	@echo "✅ 核心类型检查完成"

test:
	@echo "🧪 正在运行后端单元测试..."
	@if [ -n "$(TARGET_TESTS)" ]; then \
		echo "目标: $(TARGET_TESTS)"; \
		uv run --project api --dev pytest $(TARGET_TESTS); \
	else \
		echo "运行后端单元测试"; \
		uv run --project api --dev pytest -p no:benchmark --timeout "$${PYTEST_TIMEOUT:-20}" -n auto \
			api/tests/unit_tests \
			api/providers/vdb/*/tests/unit_tests \
			api/providers/trace/*/tests/unit_tests \
			--ignore=api/tests/unit_tests/controllers; \
		uv run --project api --dev pytest --timeout "$${PYTEST_TIMEOUT:-20}" --cov-append \
			api/tests/unit_tests/controllers; \
	fi
	@echo "✅ 单元测试完成"

test-all:
	@echo "🧪 正在运行完整后端测试套件..."
	@if [ -n "$(TARGET_TESTS)" ]; then \
		echo "目标: $(TARGET_TESTS)"; \
		uv run --project api --dev pytest $(TARGET_TESTS); \
	else \
		echo "运行后端单元测试"; \
		uv run --project api --dev pytest -p no:benchmark --timeout "$${PYTEST_TIMEOUT:-20}" -n auto \
			api/tests/unit_tests \
			api/providers/vdb/*/tests/unit_tests \
			api/providers/trace/*/tests/unit_tests \
			--ignore=api/tests/unit_tests/controllers; \
		uv run --project api --dev pytest --timeout "$${PYTEST_TIMEOUT:-20}" --cov-append \
			api/tests/unit_tests/controllers; \
		echo "运行后端集成测试"; \
		uv run --project api --dev pytest -p no:benchmark --start-middleware -n auto \
			--timeout "$${PYTEST_TIMEOUT:-180}" \
			--cov-append \
			api/tests/integration_tests/workflow \
			api/tests/integration_tests/tools \
			api/tests/test_containers_integration_tests; \
		echo "运行 VDB 冒烟测试"; \
		uv run --project api --dev pytest --start-vdb \
			--timeout "$${PYTEST_TIMEOUT:-180}" \
			--cov-append \
			api/providers/vdb/vdb-chroma/tests/integration_tests \
			api/providers/vdb/vdb-pgvector/tests/integration_tests \
			api/providers/vdb/vdb-qdrant/tests/integration_tests \
			api/providers/vdb/vdb-weaviate/tests/integration_tests; \
	fi
	@echo "✅ 测试完成"

# 构建 Docker 镜像
build-web:
	@echo "正在构建前端 Docker 镜像: $(WEB_IMAGE):$(VERSION)..."
	docker build -f web/Dockerfile -t $(WEB_IMAGE):$(VERSION) .
	@echo "前端 Docker 镜像构建成功: $(WEB_IMAGE):$(VERSION)"

build-api:
	@echo "正在构建 API Docker 镜像: $(API_IMAGE):$(VERSION)..."
	docker build -t $(API_IMAGE):$(VERSION) -f api/Dockerfile .
	@echo "API Docker 镜像构建成功: $(API_IMAGE):$(VERSION)"

# 推送 Docker 镜像
push-web:
	@echo "正在推送前端 Docker 镜像: $(WEB_IMAGE):$(VERSION)..."
	docker push $(WEB_IMAGE):$(VERSION)
	@echo "前端 Docker 镜像推送成功: $(WEB_IMAGE):$(VERSION)"

push-api:
	@echo "正在推送 API Docker 镜像: $(API_IMAGE):$(VERSION)..."
	docker push $(API_IMAGE):$(VERSION)
	@echo "API Docker 镜像推送成功: $(API_IMAGE):$(VERSION)"

# 构建所有镜像
build-all: build-web build-api

# 推送所有镜像
push-all: push-web push-api

build-push-api: build-api push-api
build-push-web: build-web push-web

# 构建并推送所有镜像
build-push-all: build-all push-all
	@echo "所有 Docker 镜像已构建并推送完成."

# 启动所有开发服务 (API + worker + dev-proxy + web)
# 使用方法: make dev
# 环境变量:
#   DEV_API_PORT    - API 服务端口 (默认: 5001)
#   DEV_PROXY_PORT  - dev-proxy 端口 (默认: 3001)
#   DEV_NO_WORKER   - 设置任意值跳过 worker 启动
.PHONY: dev
dev: prepare-docker
	@echo "🚀 正在启动 dify 开发环境..."
	@echo ""
	@# 关闭这些端口上已存在的开发服务
	@lsof -ti :$(DEV_API_PORT) | xargs kill -9 2>/dev/null || true
	@lsof -ti :$(DEV_PROXY_PORT) | xargs kill -9 2>/dev/null || true
	@lsof -ti :3000 | xargs kill -9 2>/dev/null || true
	@echo "✅ 已清理之前的开发服务"
	@echo ""
	@echo "🔧 正在启动 API 服务,端口 $(DEV_API_PORT) (支持 Socket.IO)..."
	@cd api && uv run python app.py &
	@sleep 2

	@echo "🔧 正在启动 Celery worker..."
	@if [ -z "$(DEV_NO_WORKER)" ]; then \
		cd api && uv run celery -A app.celery worker -P gevent -c 1 --loglevel INFO -Q dataset,dataset_summary,priority_dataset,priority_pipeline,pipeline,mail,ops_trace,app_deletion,plugin,workflow_storage,conversation,workflow,schedule_poller,schedule_executor,triggered_workflow_dispatcher,trigger_refresh_executor,retention,workflow_based_app_execution & \
	fi

	@echo "🔧 正在启动 dev-proxy,端口 $(DEV_PROXY_PORT)..."
	@cd web && DEV_PROXY_HOST=127.0.0.1 DEV_PROXY_PORT=$(DEV_PROXY_PORT) DEV_PROXY_TARGET=http://127.0.0.1:$(DEV_API_PORT) DEV_PROXY_CONSOLE_API_TARGET=http://127.0.0.1:$(DEV_API_PORT) DEV_PROXY_PUBLIC_API_TARGET=http://127.0.0.1:$(DEV_API_PORT) pnpm dev:proxy --config ./dev-proxy.config.ts --env-file ./.env.local &

	@echo "🌐 正在启动前端开发服务器,端口 3000..."
	@cd web && pnpm dev

.PHONY: dev-stop
dev-stop:
	@echo "🛑 正在停止开发服务..."
	@lsof -ti :$(DEV_API_PORT) | xargs kill -9 2>/dev/null && echo "✅ API 服务已停止" || echo "ℹ️  端口 $(DEV_API_PORT) 上没有 API 服务"
	@lsof -ti :$(DEV_PROXY_PORT) | xargs kill -9 2>/dev/null && echo "✅ dev-proxy 已停止" || echo "ℹ️  端口 $(DEV_PROXY_PORT) 上没有 dev-proxy"
	@lsof -ti :3000 | xargs kill -9 2>/dev/null && echo "✅ 前端开发服务器已停止" || echo "ℹ️  端口 3000 上没有前端服务"

# 帮助目标
help:
	@echo "开发环境配置目标:"
	@echo "  make dev            - 启动所有开发服务 (API + worker + dev-proxy + web)"
	@echo "  make dev-stop       - 停止所有开发服务"
	@echo "  make dev-setup      - 运行所有后端开发环境配置步骤"
	@echo "  make prepare-docker - 配置 Docker 中间件"
	@echo "  make prepare-web    - 配置前端环境"
	@echo "  make prepare-api    - 配置 API 环境"
	@echo "  make dev-clean      - 停止 Docker 中间件容器并清理开发数据"
	@echo ""
	@echo "后端代码质量:"
	@echo "  make format         - 使用 ruff 格式化代码"
	@echo "  make check          - 使用 ruff 检查代码"
	@echo "  make lint           - 格式化、修复、检查代码 (ruff, imports, dotenv)"
	@echo "  make api-contract-lint - 检查 Flask response 文档与返回 schema 是否匹配"
	@echo "  make type-check     - 运行类型检查 (pyrefly, mypy)"
	@echo "  make type-check-core - 运行核心类型检查 (pyrefly, mypy)"
	@echo "  make test           - 运行后端单元测试 (或 TARGET_TESTS=./api/tests/<target_tests>)"
	@echo "  make test-all       - 运行完整后端测试,包括 Docker 支持的测试套件"
	@echo ""
	@echo "Docker 构建目标:"
	@echo "  make build-web      - 构建前端 Docker 镜像"
	@echo "  make build-api      - 构建 API Docker 镜像"
	@echo "  make build-all      - 构建所有 Docker 镜像"
	@echo "  make push-all       - 推送所有 Docker 镜像"
	@echo "  make build-push-all - 构建并推送所有 Docker 镜像"

# 伪目标声明
.PHONY: build-web build-api push-web push-api build-all push-all build-push-all dev dev-stop dev-setup prepare-docker prepare-web prepare-api dev-clean help format check lint api-contract-lint type-check test test-all
