#!/bin/bash
# 本地测试启动脚本

set -e

echo "========================================"
echo "PromoFlow 本地测试部署"
echo "========================================"

# 检查 .env.local 是否存在（优先使用）
if [ -f ".env.local" ]; then
    echo "使用 .env.local 配置"
    cp .env.local .env
elif [ ! -f ".env" ]; then
    echo "错误: .env 文件不存在"
    echo "请先创建 .env 或 .env.local"
    exit 1
else
    echo "使用 .env 配置"
fi

echo ""
echo "正在启动服务..."
docker compose up -d

echo ""
echo "========================================"
echo "服务已启动！"
echo "========================================"
echo ""
echo "访问地址: http://localhost"
echo ""
echo "常用命令:"
echo "  查看状态: docker compose ps"
echo "  查看日志: docker compose logs -f"
echo "  停止服务: docker compose down"
echo ""
