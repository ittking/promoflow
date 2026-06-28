# 变量
DOCKER_REGISTRY=langgenius
WEB_IMAGE=$(DOCKER_REGISTRY)/dify-web
API_IMAGE=$(DOCKER_REGISTRY)/dify-api
VERSION=latest
DOCKER_DIR=docker
DOCKER_MIDDLEWARE_ENV=$(DOCKER_DIR)/middleware.env
DOCKER_MIDDLEWARE_ENV_EXAMPLE=$(DOCKER_DIR)/envs/middleware.env.example
DOCKER_MIDDLEWARE_PROJECT=dify-middlewares-dev

# 阿里云镜像仓库配置
ALIYUN_REGISTRY=crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com
ALIYUN_NAMESPACE=mnwm
ALIYUN_WEB_IMAGE=$(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/dify-web
ALIYUN_API_IMAGE=$(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/dify-api

# 默认目标 - 显示帮助信息
.DEFAULT_GOAL := help

# 后端开发环境配置
.PHONY: dev-setup prepare-docker prepare-web prepare-api

# 开发环境配置目标
dev-setup: prepare-docker prepare-web prepare-api
	@echo "✅ 后端开发环境配置完成！"

# 步骤1：准备Docker中间件
prepare-docker:
	@echo "🐳 正在设置Docker中间件..."
	@if [ ! -f "$(DOCKER_MIDDLEWARE_ENV)" ]; then \
		cp "$(DOCKER_MIDDLEWARE_ENV_EXAMPLE)" "$(DOCKER_MIDDLEWARE_ENV)"; \
		echo "Docker middleware.env 已创建"; \
	else \
		echo "Docker middleware.env 已存在"; \
	fi
	@cd $(DOCKER_DIR) && docker compose -f docker-compose.middleware.yaml --env-file middleware.env -p $(DOCKER_MIDDLEWARE_PROJECT) up -d
	@echo "✅ Docker中间件已启动"

# 步骤2：准备Web环境
prepare-web:
	@echo "🌐 正在设置Web环境..."
	@cp -n web/.env.example web/.env.local 2>/dev/null || echo "Web .env.local 已存在"
	@pnpm install
	@echo "✅ Web环境已准备（未启动）"

# 步骤3：准备API环境
prepare-api:
	@echo "🔧 正在设置API环境..."
	@cp -n api/.env.example api/.env 2>/dev/null || echo "API .env 已存在"
	@cd api && uv sync --dev
	@cd api && uv run flask db upgrade
	@echo "✅ API环境已准备（未启动）"

# 清理开发环境
dev-clean:
	@echo "⚠️  正在停止Docker容器..."
	@if [ -f "$(DOCKER_MIDDLEWARE_ENV)" ]; then \
		cd $(DOCKER_DIR) && docker compose -f docker-compose.middleware.yaml --env-file middleware.env -p $(DOCKER_MIDDLEWARE_PROJECT) down; \
	else \
		echo "Docker middleware.env 不存在，跳过compose down"; \
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
	@echo "🎨 正在运行ruff格式化..."
	@uv run --project api --dev ruff format ./api
	@echo "✅ 代码格式化完成"

check:
	@echo "🔍 正在运行ruff检查..."
	@uv run --project api --dev ruff check ./api
	@echo "✅ 代码检查完成"

lint:
	@echo "🔧 正在运行ruff格式化、检查修复、响应契约lint、导入检查和dotenv-linter..."
	@uv run --project api --dev ruff format ./api
	@uv run --project api --dev ruff check --fix ./api
	@$(MAKE) api-contract-lint
	@uv run --directory api --dev lint-imports
	@uv run --project api --dev dotenv-linter ./api/.env.example ./web/.env.example
	@echo "✅ Linting完成"

api-contract-lint:
	@echo "🔎 正在检查Flask响应契约..."
	@uv run --project api --dev python api/dev/lint_response_contracts.py
	@echo "✅ 响应契约检查完成"

type-check:
	@echo "📝 正在运行类型检查（pyrefly + mypy）..."
	@./dev/pyrefly-check-local $(PATH_TO_CHECK)
	@uv --directory api run mypy --exclude-gitignore --exclude '(^|/)conftest\.py$$' --exclude 'tests/' --exclude 'migrations/' --exclude 'dev/generate_swagger_specs.py' --exclude 'dev/generate_fastopenapi_specs.py' --check-untyped-defs --disable-error-code=import-untyped .
	@echo "✅ 类型检查完成"

type-check-core:
	@echo "📝 正在运行核心类型检查（pyrefly + mypy）..."
	@./dev/pyrefly-check-local $(PATH_TO_CHECK)
	@uv --directory api run mypy --exclude-gitignore --exclude '(^|/)conftest\.py$$' --exclude 'tests/' --exclude 'migrations/' --exclude 'dev/generate_swagger_specs.py' --exclude 'dev/generate_fastopenapi_specs.py' --check-untyped-defs --disable-error-code=import-untyped .
	@echo "✅ 核心类型检查完成"

test:
	@echo "🧪 正在运行后端单元测试..."
	@if [ -n "$(TARGET_TESTS)" ]; then \
		echo "目标: $(TARGET_TESTS)"; \
		uv run --project api --dev pytest $(TARGET_TESTS); \
	else \
		echo "正在运行后端单元测试"; \
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
		echo "正在运行后端单元测试"; \
		uv run --project api --dev pytest -p no:benchmark --timeout "$${PYTEST_TIMEOUT:-20}" -n auto \
			api/tests/unit_tests \
			api/providers/vdb/*/tests/unit_tests \
			api/providers/trace/*/tests/unit_tests \
			--ignore=api/tests/unit_tests/controllers; \
		uv run --project api --dev pytest --timeout "$${PYTEST_TIMEOUT:-20}" --cov-append \
			api/tests/unit_tests/controllers; \
		echo "正在运行后端集成测试"; \
		uv run --project api --dev pytest -p no:benchmark --start-middleware -n auto \
			--timeout "$${PYTEST_TIMEOUT:-180}" \
			--cov-append \
			api/tests/integration_tests/workflow \
			api/tests/integration_tests/tools \
			api/tests/test_containers_integration_tests; \
		echo "正在运行VDB冒烟测试"; \
		uv run --project api --dev pytest --start-vdb \
			--timeout "$${PYTEST_TIMEOUT:-180}" \
			--cov-append \
			api/providers/vdb/vdb-chroma/tests/integration_tests \
			api/providers/vdb/vdb-pgvector/tests/integration_tests \
			api/providers/vdb/vdb-qdrant/tests/integration_tests \
			api/providers/vdb/vdb-weaviate/tests/integration_tests; \
	fi
	@echo "✅ 测试完成"

# 构建Docker镜像
build-web:
	@echo "正在构建Web Docker镜像: $(WEB_IMAGE):$(VERSION)..."
	docker build -f web/Dockerfile -t $(WEB_IMAGE):$(VERSION) .
	@echo "Web Docker镜像构建成功: $(WEB_IMAGE):$(VERSION)"

build-api:
	@echo "正在构建API Docker镜像: $(API_IMAGE):$(VERSION)..."
	docker build -t $(API_IMAGE):$(VERSION) -f api/Dockerfile .
	@echo "API Docker镜像构建成功: $(API_IMAGE):$(VERSION)"

# 推送Docker镜像
push-web:
	@echo "正在推送Web Docker镜像: $(WEB_IMAGE):$(VERSION)..."
	docker push $(WEB_IMAGE):$(VERSION)
	@echo "Web Docker镜像推送成功: $(WEB_IMAGE):$(VERSION)"

push-api:
	@echo "正在推送API Docker镜像: $(API_IMAGE):$(VERSION)..."
	docker push $(API_IMAGE):$(VERSION)
	@echo "API Docker镜像推送成功: $(API_IMAGE):$(VERSION)"

# 构建所有镜像
build-all: build-web build-api

# 推送所有镜像
push-all: push-web push-api

build-push-api: build-api push-api
build-push-web: build-web push-web

# 构建并推送所有镜像
build-push-all: build-all push-all
	@echo "所有Docker镜像已构建并推送完成。"

# ==================== 阿里云镜像相关 ====================

# 构建阿里云 Web 镜像
build-aliyun-web:
	@echo "正在构建阿里云Web Docker镜像: $(ALIYUN_WEB_IMAGE):$(VERSION)..."
	docker build -f web/Dockerfile -t $(ALIYUN_WEB_IMAGE):$(VERSION) .
	@echo "阿里云Web Docker镜像构建成功: $(ALIYUN_WEB_IMAGE):$(VERSION)"

# 构建阿里云 API 镜像
build-aliyun-api:
	@echo "正在构建阿里云API Docker镜像: $(ALIYUN_API_IMAGE):$(VERSION)..."
	docker build -t $(ALIYUN_API_IMAGE):$(VERSION) -f api/Dockerfile .
	@echo "阿里云API Docker镜像构建成功: $(ALIYUN_API_IMAGE):$(VERSION)"

# 推送阿里云 Web 镜像
push-aliyun-web:
	@echo "正在推送阿里云Web Docker镜像: $(ALIYUN_WEB_IMAGE):$(VERSION)..."
	docker push $(ALIYUN_WEB_IMAGE):$(VERSION)
	@echo "阿里云Web Docker镜像推送成功: $(ALIYUN_WEB_IMAGE):$(VERSION)"

# 推送阿里云 API 镜像
push-aliyun-api:
	@echo "正在推送阿里云API Docker镜像: $(ALIYUN_API_IMAGE):$(VERSION)..."
	docker push $(ALIYUN_API_IMAGE):$(VERSION)
	@echo "阿里云API Docker镜像推送成功: $(ALIYUN_API_IMAGE):$(VERSION)"

# 构建所有阿里云镜像（包含所有基础镜像）
build-aliyun-all: build-aliyun-web build-aliyun-api build-aliyun-base

# 构建阿里云基础镜像
build-aliyun-base:
	@echo "正在构建/拉取阿里云基础镜像..."
	@docker pull postgres:15-alpine && docker tag postgres:15-alpine $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/postgres:15-alpine
	@docker pull redis:6-alpine && docker tag redis:6-alpine $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/redis:6-alpine
	@docker pull nginx:latest && docker tag nginx:latest $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/nginx:latest
	@docker pull ubuntu/squid:latest && docker tag ubuntu/squid:latest $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/ubuntu-squid:latest
	@docker pull busybox:latest && docker tag busybox:latest $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/busybox:latest
	@docker pull langgenius/dify-sandbox:0.2.15 && docker tag langgenius/dify-sandbox:0.2.15 $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/dify-sandbox:0.2.15
	@docker pull langgenius/dify-plugin-daemon:0.6.3-local && docker tag langgenius/dify-plugin-daemon:0.6.3-local $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/dify-plugin-daemon:0.6.3-local
	@echo "阿里云基础镜像构建完成"

# 推送所有阿里云镜像（包含所有基础镜像）
push-aliyun-all: push-aliyun-web push-aliyun-api push-aliyun-base

# 推送阿里云基础镜像（postgres, redis, nginx, squid, busybox, sandbox, plugin-daemon）
push-aliyun-base:
	@echo "正在推送阿里云基础镜像..."
	@docker tag postgres:15-alpine $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/postgres:15-alpine && docker push $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/postgres:15-alpine
	@docker tag redis:6-alpine $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/redis:6-alpine && docker push $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/redis:6-alpine
	@docker tag nginx:latest $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/nginx:latest && docker push $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/nginx:latest
	@docker tag ubuntu/squid:latest $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/ubuntu-squid:latest && docker push $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/ubuntu-squid:latest
	@docker tag busybox:latest $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/busybox:latest && docker push $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/busybox:latest
	@docker tag langgenius/dify-sandbox:0.2.15 $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/dify-sandbox:0.2.15 && docker push $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/dify-sandbox:0.2.15
	@docker tag langgenius/dify-plugin-daemon:0.6.3-local $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/dify-plugin-daemon:0.6.3-local && docker push $(ALIYUN_REGISTRY)/$(ALIYUN_NAMESPACE)/dify-plugin-daemon:0.6.3-local
	@echo "阿里云基础镜像推送成功"

# 构建并推送阿里云所有镜像
build-push-aliyun-all: build-aliyun-all push-aliyun-all
	@echo "所有阿里云Docker镜像已构建并推送完成。"

# ==================== 帮助目标 ====================

# 帮助目标
help:
	@echo "开发环境配置目标："
	@echo "  make dev-setup      - 运行后端开发环境的所有配置步骤"
	@echo "  make prepare-docker - 设置Docker中间件"
	@echo "  make prepare-web    - 设置Web环境"
	@echo "  make prepare-api    - 设置API环境"
	@echo "  make dev-clean      - 停止Docker中间件容器并删除开发数据"
	@echo ""
	@echo "后端代码质量："
	@echo "  make format         - 使用ruff格式化代码"
	@echo "  make check          - 使用ruff检查代码"
	@echo "  make lint           - 格式化、修复并lint代码（ruff、imports、dotenv）"
	@echo "  make api-contract-lint - 检查Flask响应文档与返回模式的一致性"
	@echo "  make type-check     - 运行类型检查（pyrefly、mypy）"
	@echo "  make type-check-core - 运行核心类型检查（pyrefly、mypy）"
	@echo "  make test           - 运行后端单元测试（或 TARGET_TESTS=./api/tests/<目标测试>）"
	@echo "  make test-all       - 运行完整后端测试，包括Docker支持套件"
	@echo ""
	@echo "Docker构建目标："
	@echo "  make build-web      - 构建Web Docker镜像"
	@echo "  make build-api      - 构建API Docker镜像"
	@echo "  make build-all      - 构建所有Docker镜像"
	@echo "  make push-all       - 推送所有Docker镜像"
	@echo "  make build-push-all - 构建并推送所有Docker镜像"
	@echo ""
	@echo "阿里云镜像构建目标："
	@echo "  make build-aliyun-web       - 构建阿里云Web镜像"
	@echo "  make build-aliyun-api       - 构建阿里云API镜像"
	@echo "  make build-aliyun-base      - 构建阿里云基础镜像(postgres,redis,nginx等)"
	@echo "  make build-aliyun-all       - 构建所有阿里云镜像(含基础镜像)"
	@echo "  make push-aliyun-web        - 推送阿里云Web镜像"
	@echo "  make push-aliyun-api        - 推送阿里云API镜像"
	@echo "  make push-aliyun-base       - 推送阿里云基础镜像"
	@echo "  make push-aliyun-all        - 推送所有阿里云镜像(含基础镜像)"
	@echo "  make build-push-aliyun-all  - 构建并推送所有阿里云镜像(完整部署镜像)"

# 伪目标
.PHONY: build-web build-api push-web push-api build-all push-all build-push-all dev-setup prepare-docker prepare-web prepare-api dev-clean help format check lint api-contract-lint type-check test test-all