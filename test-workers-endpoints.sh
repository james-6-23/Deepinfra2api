#!/bin/bash

# Cloudflare Workers 端点测试脚本
# 专门测试您的 Workers 代理端点

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🚀 Cloudflare Workers 端点测试${NC}"
echo "=================================="

# 您的 Workers 端点
WORKERS_ENDPOINTS=(
    "https://api.deepinfra.com/v1/openai/chat/completions"
    "https://deepinfra2apipoint.1163476949.workers.dev/v1/openai/chat/completions"
    "https://deepinfra22.kyxjames23.workers.dev/v1/openai/chat/completions"
)

# 对应的模型端点
MODEL_ENDPOINTS=(
    "https://api.deepinfra.com/v1/models"
    "https://deepinfra2apipoint.1163476949.workers.dev/v1/models"
    "https://deepinfra22.kyxjames23.workers.dev/v1/models"
)

echo -e "${CYAN}📊 端点连通性测试${NC}"

working_endpoints=0
total_endpoints=${#WORKERS_ENDPOINTS[@]}

for i in "${!WORKERS_ENDPOINTS[@]}"; do
    endpoint="${WORKERS_ENDPOINTS[$i]}"
    model_endpoint="${MODEL_ENDPOINTS[$i]}"
    
    if [[ "$endpoint" == *"workers.dev"* ]]; then
        endpoint_name="Workers $(echo $endpoint | cut -d'.' -f1 | cut -d'/' -f3)"
    else
        endpoint_name="官方 API"
    fi
    
    echo -n "测试 $endpoint_name ... "
    
    # 测试模型端点
    response=$(curl -s -w "%{http_code}" -o /tmp/test_response.json --connect-timeout 10 "$model_endpoint" 2>/dev/null)
    http_code="${response: -3}"
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ 可用 (HTTP $http_code)${NC}"
        working_endpoints=$((working_endpoints + 1))
        
        # 检查响应内容
        if [ -f /tmp/test_response.json ]; then
            model_count=$(cat /tmp/test_response.json | grep -o '"id"' | wc -l 2>/dev/null || echo "0")
            if [ "$model_count" -gt 0 ]; then
                echo "    📋 返回 $model_count 个模型"
            fi
        fi
    else
        echo -e "${RED}❌ 不可用 (HTTP $http_code)${NC}"
        
        # 尝试直接测试域名连通性
        domain=$(echo "$endpoint" | sed 's|https\?://||' | cut -d'/' -f1)
        if ping -c 1 -W 3 "$domain" >/dev/null 2>&1; then
            echo "    🌐 域名可达，可能是路径或配置问题"
        else
            echo "    🌐 域名不可达"
        fi
    fi
    
    # 清理临时文件
    rm -f /tmp/test_response.json
done

echo ""
echo -e "${CYAN}📊 连通性统计${NC}"
echo "可用端点: $working_endpoints/$total_endpoints"

if [ $working_endpoints -eq 0 ]; then
    echo -e "${RED}❌ 所有端点都不可用${NC}"
elif [ $working_endpoints -eq $total_endpoints ]; then
    echo -e "${GREEN}✅ 所有端点都可用${NC}"
else
    echo -e "${YELLOW}⚠️ 部分端点可用${NC}"
fi

echo ""
echo -e "${CYAN}🧪 API 功能测试${NC}"

if [ $working_endpoints -gt 0 ]; then
    # 测试聊天 API
    echo "测试聊天 API 功能..."
    
    test_payload='{
        "model": "deepseek-ai/DeepSeek-V3.1",
        "messages": [{"role": "user", "content": "Hello, respond with just OK"}],
        "max_tokens": 5
    }'
    
    for i in "${!WORKERS_ENDPOINTS[@]}"; do
        endpoint="${WORKERS_ENDPOINTS[$i]}"
        
        if [[ "$endpoint" == *"workers.dev"* ]]; then
            endpoint_name="Workers $(echo $endpoint | cut -d'.' -f1 | cut -d'/' -f3)"
        else
            endpoint_name="官方 API"
        fi
        
        echo -n "测试 $endpoint_name 聊天功能 ... "
        
        response=$(curl -s -w "%{http_code}" -o /tmp/chat_response.json \
            -X POST "$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer linux.do" \
            -d "$test_payload" \
            --connect-timeout 15 \
            2>/dev/null)
        
        http_code="${response: -3}"
        
        if [ "$http_code" = "200" ]; then
            echo -e "${GREEN}✅ 成功${NC}"
            
            # 检查响应内容
            if [ -f /tmp/chat_response.json ]; then
                if grep -q '"choices"' /tmp/chat_response.json; then
                    content=$(cat /tmp/chat_response.json | grep -o '"content":"[^"]*"' | head -1 | cut -d'"' -f4)
                    if [ -n "$content" ]; then
                        echo "    💬 响应: $content"
                    fi
                fi
            fi
        else
            echo -e "${RED}❌ 失败 (HTTP $http_code)${NC}"
            
            # 显示错误信息
            if [ -f /tmp/chat_response.json ]; then
                error_msg=$(cat /tmp/chat_response.json | head -c 200)
                if [ -n "$error_msg" ]; then
                    echo "    ❌ 错误: $error_msg"
                fi
            fi
        fi
        
        rm -f /tmp/chat_response.json
    done
else
    echo -e "${YELLOW}⚠️ 跳过 API 功能测试（无可用端点）${NC}"
fi

echo ""
echo -e "${CYAN}🔧 Workers 配置检查${NC}"

# 检查 Workers 代码配置
echo "检查 Workers 代码配置:"
if [ -f workers.js ]; then
    echo "✅ 找到 workers.js 文件"
    
    # 检查目标主机配置
    if grep -q "TARGET_HOST.*api.deepinfra.com" workers.js; then
        echo "✅ 目标主机配置正确"
    else
        echo "⚠️ 目标主机配置可能有问题"
    fi
    
    # 检查路径配置
    if grep -q "SUPPORTED_PATHS.*v1" workers.js; then
        echo "✅ 支持的路径配置正确"
    else
        echo "⚠️ 路径配置可能有问题"
    fi
    
    # 检查 CORS 配置
    if grep -q "ENABLE_CORS.*true" workers.js; then
        echo "✅ CORS 已启用"
    else
        echo "⚠️ CORS 可能未启用"
    fi
else
    echo "❌ 未找到 workers.js 文件"
fi

echo ""
echo -e "${CYAN}💡 优化建议${NC}"

if [ $working_endpoints -lt $total_endpoints ]; then
    echo "端点优化建议:"
    echo "1. 检查不可用的 Workers 部署状态"
    echo "2. 验证 Workers 域名绑定"
    echo "3. 检查 Workers 代码是否正确部署"
    echo "4. 考虑只使用可用的端点"
    echo ""
fi

echo "配置建议:"
echo "1. 在 .env 文件中只配置可用的端点"
echo "2. 定期测试端点可用性"
echo "3. 考虑添加更多备用端点"

echo ""
echo -e "${BLUE}📋 推荐配置${NC}"

if [ $working_endpoints -gt 0 ]; then
    echo "基于测试结果，推荐以下配置:"
    echo ""
    echo "# 只使用可用端点的配置"
    echo -n "DEEPINFRA_MIRRORS="
    
    first=true
    for i in "${!WORKERS_ENDPOINTS[@]}"; do
        endpoint="${WORKERS_ENDPOINTS[$i]}"
        model_endpoint="${MODEL_ENDPOINTS[$i]}"
        
        # 简单测试端点是否可用
        if curl -s --connect-timeout 5 "$model_endpoint" >/dev/null 2>&1; then
            if [ "$first" = true ]; then
                echo -n "$endpoint"
                first=false
            else
                echo -n ",$endpoint"
            fi
        fi
    done
    echo ""
else
    echo "所有端点都不可用，建议使用单端点配置:"
    echo "DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions"
fi

echo ""
echo -e "${GREEN}✨ Workers 端点测试完成！${NC}"
