@echo off
echo 🚀 启动 DeepInfra API Proxy - Go版本优化版
echo ================================================
echo.
echo 📦 版本: 2.0.0
echo 🔧 主要改进: 解决流式响应截断问题
echo.

REM 设置环境变量
set PORT=8000
set PERFORMANCE_MODE=balanced
set MAX_RETRIES=3
set RETRY_DELAY=1000
set REQUEST_TIMEOUT=30000
set RANDOM_DELAY_MIN=100
set RANDOM_DELAY_MAX=500
set ENABLE_DETAILED_LOGGING=true
set VALID_API_KEYS=linux.do

echo 🌐 启动服务器在端口 %PORT%
echo ⚡ 性能模式: %PERFORMANCE_MODE%
echo.

REM 启动服务器
go run main.go

pause
