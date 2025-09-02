#!/bin/bash

# DeepInfra API 代理部署脚本

set -e

echo "🚀 开始部署 DeepInfra API 代理..."

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

# 检查 Docker Compose 是否安装
if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose 未安装或版本过低，请安装 Docker 最新版本"
    exit 1
fi

# 检查环境变量文件
if [ ! -f ".env" ]; then
    echo "⚠️  未找到 .env 文件，从示例文件创建..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "📁 已创建 .env 文件，请根据需要修改配置"
        echo "📝 主要配置项："
        echo "   - DOMAIN: 你的域名"
        echo "   - PORT: 后端服务端口"
        echo "   - NGINX_PORT: Nginx 端口"
        echo "   - VALID_API_KEYS: API 密钥"
        echo ""
        read -p "是否继续部署？(y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ 部署已取消"
            exit 1
        fi
    else
        echo "❌ 未找到 .env.example 文件"
        exit 1
    fi
fi

# 加载环境变量
export $(grep -v '^#' .env | xargs)

# 生成 Nginx 配置
echo "🔧 生成 Nginx 配置文件..."
chmod +x generate-nginx-config.sh
./generate-nginx-config.sh

# 决定部署模式
echo "📋 选择部署模式："
echo "   1) 完整模式 (包含 WARP 代理)"
echo "   2) 基础模式 (仅 API 代理)"
read -p "请选择 (1/2) [默认: 2]: " choice
choice=${choice:-2}

if [ "$choice" = "1" ]; then
    PROFILES="--profile warp --profile app"
    echo "🛡️  启用 WARP 代理模式"
else
    PROFILES="--profile app"
    echo "⚡ 启用基础代理模式"
fi

# 停止并删除现有容器
echo "🛑 停止现有服务..."
docker compose down --remove-orphans

# 构建并启动服务
echo "🔨 构建并启动服务..."
docker compose $PROFILES up -d --build

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 15

# 检查服务状态
echo "✅ 检查服务状态..."
docker compose ps

# 测试健康检查
echo "🔍 测试服务健康状态..."
HEALTH_URL="http://localhost:${NGINX_PORT:-80}/health"

if curl -f "$HEALTH_URL" &> /dev/null; then
    echo "✅ 服务启动成功！"
    echo ""
    echo "🌐 访问地址:"
    echo "   - HTTP: http://${DOMAIN:-deepinfra.kyx03.de}:${NGINX_PORT:-80}"
    echo "   - HTTPS: https://${DOMAIN:-deepinfra.kyx03.de} (通过 Cloudflare)"
    echo ""
    echo "📋 API 接口:"
    echo "   - 健康检查: http://${DOMAIN:-deepinfra.kyx03.de}:${NGINX_PORT:-80}/health"
    echo "   - 模型列表: http://${DOMAIN:-deepinfra.kyx03.de}:${NGINX_PORT:-80}/v1/models"
    echo "   - 聊天接口: http://${DOMAIN:-deepinfra.kyx03.de}:${NGINX_PORT:-80}/v1/chat/completions"
    echo ""
    echo "📊 管理命令:"
    echo "   - 查看日志: docker compose logs -f"
    echo "   - 重启服务: docker compose restart"
    echo "   - 停止服务: docker compose down"
    echo ""
    echo "💡 注意: SSL 证书由 Cloudflare 自动处理"
    
    # 如果启用了 WARP，测试连接
    if [ "$choice" = "1" ]; then
        echo ""
        echo "🔍 测试 WARP 连接..."
        if docker exec deepinfra-warp curl --socks5-hostname 127.0.0.1:1080 https://cloudflare.com/cdn-cgi/trace 2>/dev/null | grep -q "warp=on\|warp=plus"; then
            echo "✅ WARP 代理工作正常"
        else
            echo "⚠️  WARP 代理可能未正常工作，请检查日志"
        fi
    fi
else
    echo "❌ 服务启动失败，请检查日志:"
    docker compose logs
    exit 1
fi