#!/bin/bash

# 快速测试修复效果
echo "🧪 测试 Go 版本修复效果..."

# 检查服务状态
if ! curl -s -f "http://localhost:8001/health" > /dev/null; then
    echo "❌ Go 版本服务未运行，请先启动服务"
    exit 1
fi

echo "✅ Go 版本服务运行正常"
echo "🚀 开始流式响应测试..."

# 发送测试请求
curl -X POST "http://localhost:8001/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [{"role": "user", "content": "请详细介绍人工智能的发展历史，包括重要的里程碑事件、关键技术突破和未来发展趋势。请写得详细一些，至少1000字。"}],
    "stream": true,
    "max_tokens": 2000
  }' \
  --no-buffer | head -50

echo ""
echo "🔍 检查服务日志中是否还有超时错误..."
echo "请查看 docker-compose logs deepinfra-proxy-go 的最新输出"
