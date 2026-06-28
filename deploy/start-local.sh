#!/bin/bash
# 本地测试启动脚本

set -e

echo "========================================"
echo "PromoFlow 本地测试部署"
echo "========================================"

# 检查 .env.example 是否存在
if [ ! -f ".env.example" ]; then
    echo "错误: .env.example 文件不存在"
    echo "请确保在 deploy 目录下运行此脚本"
    exit 1
fi

# 检查 .env 是否存在
if [ ! -f ".env" ]; then
    echo "错误: .env 文件不存在"
    echo "请先创建 .env 文件"
    exit 1
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
