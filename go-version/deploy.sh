#!/bin/bash

echo "🚀 部署 DeepInfra API Proxy - Go 版本优化版"
echo "============================================="

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

# 停止现有容器
echo "🛑 停止现有容器..."
docker-compose down

# 构建并启动服务
echo "🔨 构建并启动服务..."
docker-compose up --build -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "🔍 检查服务状态..."
if curl -f http://localhost:8001/health > /dev/null 2>&1; then
    echo "✅ Go 版本优化版部署成功！"
    echo "🌐 服务地址: http://localhost:8001"
    echo "📊 健康检查: http://localhost:8001/health"
    echo "📋 模型列表: http://localhost:8001/v1/models"
    echo "🔧 版本: 2.0.0 (已优化流式响应处理)"
else
    echo "❌ 服务启动失败，请检查日志:"
    docker-compose logs
    exit 1
fi

echo ""
echo "📝 使用说明:"
echo "  • API 端点: http://localhost:8001/v1/chat/completions"
echo "  • API Key: linux.do"
echo "  • 查看日志: docker-compose logs -f"
echo "  • 停止服务: docker-compose down"
echo ""
echo "✨ 优化特性:"
echo "  • 解决流式响应截断问题"
echo "  • 增强错误恢复机制"
echo "  • 动态缓冲区优化"
echo "  • 连接状态检测"
