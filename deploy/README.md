# PromoFlow 部署包

本目录包含 PromoFlow 在甲方服务器上部署所需的所有文件。

## 镜像说明

### 自定义镜像（从阿里云拉取）

这些镜像需要本地构建后推送到阿里云仓库：

| 镜像 | 说明 |
|------|------|
| `dify-api` | 后端 API 服务（本地代码构建） |
| `dify-web` | 前端 Web 应用（本地代码构建） |
| `dify-sandbox` | 代码执行沙箱 |
| `dify-plugin-daemon` | 插件服务 |

### 公共镜像（从 Docker Hub 拉取）

部署时会自动从 Docker Hub 拉取，无需手动处理：

| 镜像 | 说明 |
|------|------|
| `postgres:15-alpine` | PostgreSQL 数据库 |
| `redis:6-alpine` | Redis 缓存 |
| `nginx:latest` | 反向代理 |
| `ubuntu/squid` | SSRF 防护代理 |
| `busybox:latest` | 初始化工具 |
| `semitechnologies/weaviate:1.27.0` | 向量数据库 |

## 目录结构

```
deploy/
├── docker-compose.yaml    # Docker 编排文件
├── .env                   # 主环境变量配置
├── .env.local             # 本地测试环境配置
├── .envs/                 # 细分环境变量
│   ├── shared.env
│   ├── api.env
│   ├── worker.env
│   ├── worker-beat.env
│   ├── security.env
│   ├── db-postgres.env
│   ├── redis.env
│   └── weaviate.env
├── nginx/                 # Nginx 配置
│   ├── nginx.conf
│   └── conf.d/
│       └── default.conf
├── ssrf_proxy/            # SSRF 代理配置
│   └── squid.conf
├── volumes/               # 数据卷目录（空目录）
│   ├── app/storage/
│   ├── db/data/
│   ├── redis/data/
│   ├── sandbox/
│   ├── plugin_daemon/
│   ├── weaviate/
│   └── certbot/
├── start-local.sh         # 本地测试启动脚本
└── README.md              # 本文件
```

## 快速部署

### 前提条件

- 服务器已安装 Docker 和 Docker Compose
- 服务器能够访问 Docker Hub 和阿里云镜像仓库

### 部署步骤

#### 1. 登录阿里云镜像仓库（只需一次）

```bash
docker login --username=17602235676 crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com
```

#### 2. 修改环境配置

编辑 `.env` 文件，修改以下配置：

```bash
# 域名配置（必填）
CONSOLE_API_URL=http://你的服务器IP或域名
CONSOLE_WEB_URL=http://你的服务器IP或域名
SERVICE_API_URL=http://你的服务器IP或域名
APP_API_URL=http://你的服务器IP或域名
APP_WEB_URL=http://你的服务器IP或域名
NEXT_PUBLIC_SOCKET_URL=ws://你的服务器IP或域名

# Nginx 域名
NGINX_SERVER_NAME=你的服务器IP或域名
```

#### 3. 启动服务

```bash
docker compose up -d
```

#### 4. 执行数据库迁移

首次部署或更新数据库结构后，需要执行数据库迁移：

```bash
docker compose exec api flask db upgrade
```

#### 5. 验证部署

```bash
# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f
```

访问 `http://服务器IP或域名` 应该能看到 PromoFlow 界面。

## 本地测试

```bash
# 使用本地测试配置启动
./start-local.sh
```

## 本地构建并推送镜像

```bash
# 登录阿里云
docker login --username=17602235676 crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com

# 构建并推送所有自定义镜像到阿里云
make build-push-aliyun-all
```

这会构建并推送以下自定义镜像：
- `dify-api:latest`
- `dify-web:latest`
- `dify-sandbox:0.2.15`
- `dify-plugin-daemon:0.6.3-local`

公共镜像无需推送，部署时会自动从 Docker Hub 拉取。

## 常用命令

```bash
# 启动服务
docker compose up -d

# 停止服务（保留数据）
docker compose stop

# 停止并删除容器（保留数据）
docker compose down

# 停止并删除容器和数据卷（慎用！会删除所有数据）
docker compose down -v

# 重启服务
docker compose restart

# 查看日志
docker compose logs -f api
docker compose logs -f web

# 进入容器
docker compose exec api sh
docker compose exec web sh
```

## 导入 DSL 文件

1. 登录 PromoFlow Web 界面
2. 点击「创建应用」→「导入 DSL」
3. 上传 `.yaml` 文件

## 故障排查

### 服务无法启动

```bash
# 查看详细日志
docker compose logs

# 检查端口占用
netstat -tlnp | grep -E '80|443|5001'
```

### 数据库连接失败

```bash
# 等待数据库就绪后重试
docker compose up -d db_postgres
sleep 10
docker compose up -d
```

### 页面报错或接口 400 错误

可能是数据库未迁移导致，检查并执行：

```bash
docker compose exec api flask db upgrade
```

### 自定义镜像拉取失败

```bash
# 重新登录阿里云
docker logout crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com
docker login --username=17602235676 crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com

# 手动拉取镜像测试
docker pull crpi-ey5cq37q6clixvfc.cn-shanghai.personal.cr.aliyuncs.com/mnwm/dify-api:latest
```

### 公共镜像拉取失败

如果 Docker Hub 访问缓慢或失败，可以配置国内镜像加速器：

```bash
# 编辑 /etc/docker/daemon.json
{
  "registry-mirrors": ["https://docker.1ms.run"]
}

# 重启 Docker
sudo systemctl restart docker
```

## 数据备份

数据存储在 `volumes/` 目录下，定期备份该目录可防止数据丢失。

```bash
# 备份
tar -czvf promoflow-backup-$(date +%Y%m%d).tar.gz volumes/

# 恢复
tar -xzvf promoflow-backup-20240101.tar.gz
```