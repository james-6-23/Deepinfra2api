#!/bin/bash

echo "🚀 启动 DeepInfra API Proxy - Go版本优化版"
echo "================================================"
echo ""
echo "📦 版本: 2.0.0"
echo "🔧 主要改进: 解决流式响应截断问题"
echo ""

# 设置环境变量
export PORT=8000
export PERFORMANCE_MODE=balanced
export MAX_RETRIES=3
export RETRY_DELAY=1000
export REQUEST_TIMEOUT=30000
export RANDOM_DELAY_MIN=100
export RANDOM_DELAY_MAX=500
export ENABLE_DETAILED_LOGGING=true
export VALID_API_KEYS=linux.do

echo "🌐 启动服务器在端口 $PORT"
echo "⚡ 性能模式: $PERFORMANCE_MODE"
echo ""

# 启动服务器
go run main.go
