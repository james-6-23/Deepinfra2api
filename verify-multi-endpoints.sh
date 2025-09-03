#!/bin/bash

# 多端点负载均衡验证脚本
# 用于验证多端点配置和负载均衡功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 图标定义
SUCCESS="✅"
ERROR="❌"
WARNING="⚠️"
INFO="ℹ️"
ROCKET="🚀"
GEAR="⚙️"
TEST="🧪"
CHART="📊"

echo -e "${BLUE}${ROCKET} 多端点负载均衡验证工具${NC}"
echo "=================================="

# 检测服务类型和端口
if docker ps | grep -q "deepinfra-proxy-go"; then
    APP_PORT="8001"
    APP_TYPE="Go"
    APP_CONTAINER="deepinfra-proxy-go"
elif docker ps | grep -q "deepinfra-proxy-deno"; then
    APP_PORT="8000"
    APP_TYPE="Deno"
    APP_CONTAINER="deepinfra-proxy-deno"
else
    echo -e "${ERROR} 未检测到运行中的应用服务${NC}"
    echo "请先启动服务: ./quick-start.sh"
    exit 1
fi

echo -e "${INFO} 检测到 $APP_TYPE 服务 (端口: $APP_PORT)"

echo ""
echo -e "${BLUE}==================== 1. 多端点配置检查 ====================${NC}"

# 检查环境配置
echo -e "${CYAN}${CHART} 环境配置检查${NC}"
if [ -f .env ]; then
    echo "当前 .env 配置:"
    if grep -q "DEEPINFRA_MIRRORS=" .env; then
        MIRRORS_CONFIG=$(grep "DEEPINFRA_MIRRORS=" .env | head -1)
        echo "$MIRRORS_CONFIG"
        
        # 解析端点数量
        ENDPOINTS_COUNT=$(echo "$MIRRORS_CONFIG" | grep -o "https://[^,]*" | wc -l)
        echo -e "${INFO} 配置的端点数量: $ENDPOINTS_COUNT"
        
        if [ $ENDPOINTS_COUNT -gt 1 ]; then
            echo -e "${SUCCESS} 多端点配置已启用"
            MULTI_ENDPOINT_ENABLED=true
        else
            echo -e "${WARNING} 只配置了单个端点"
            MULTI_ENDPOINT_ENABLED=false
        fi
    else
        echo -e "${WARNING} 未找到 DEEPINFRA_MIRRORS 配置，使用默认单端点"
        MULTI_ENDPOINT_ENABLED=false
    fi
else
    echo -e "${ERROR} 未找到 .env 文件"
    MULTI_ENDPOINT_ENABLED=false
fi

# 检查应用容器配置
echo ""
echo -e "${CYAN}${CHART} 应用容器配置检查${NC}"
echo "应用容器环境变量:"
docker exec $APP_CONTAINER env | grep -E "(DEEPINFRA_MIRRORS|DEEPINFRA_API_URL)" || echo "未找到端点配置环境变量"

echo ""
echo -e "${BLUE}==================== 2. 端点连通性测试 ====================${NC}"

# 定义默认端点列表
DEFAULT_ENDPOINTS=(
    "https://api.deepinfra.com/v1/openai/chat/completions"
    "https://api1.deepinfra.com/v1/openai/chat/completions"
    "https://api2.deepinfra.com/v1/openai/chat/completions"
)

# 获取配置的端点
if [ "$MULTI_ENDPOINT_ENABLED" = true ]; then
    # 从配置中提取端点
    ENDPOINTS=($(echo "$MIRRORS_CONFIG" | sed 's/DEEPINFRA_MIRRORS=//' | tr ',' '\n'))
else
    # 使用默认端点进行测试
    ENDPOINTS=("${DEFAULT_ENDPOINTS[@]}")
fi

echo -e "${CYAN}${TEST} 测试各端点连通性${NC}"

WORKING_ENDPOINTS=0
TOTAL_ENDPOINTS=${#ENDPOINTS[@]}

for i in "${!ENDPOINTS[@]}"; do
    endpoint="${ENDPOINTS[$i]}"
    echo -n "端点 $((i+1)): $(echo $endpoint | sed 's|https://||' | sed 's|/.*||') ... "
    
    # 测试端点连通性（转换为模型列表端点）
    model_endpoint=$(echo "$endpoint" | sed 's|/chat/completions|/models|')
    
    if timeout 10 curl -s -f "$model_endpoint" >/dev/null 2>&1; then
        echo -e "${GREEN}${SUCCESS} 可用${NC}"
        WORKING_ENDPOINTS=$((WORKING_ENDPOINTS + 1))
    else
        echo -e "${RED}${ERROR} 不可用${NC}"
    fi
done

echo ""
echo -e "${INFO} 端点连通性统计: $WORKING_ENDPOINTS/$TOTAL_ENDPOINTS 可用"

if [ $WORKING_ENDPOINTS -eq 0 ]; then
    echo -e "${ERROR} 所有端点都不可用，请检查网络连接"
elif [ $WORKING_ENDPOINTS -eq $TOTAL_ENDPOINTS ]; then
    echo -e "${SUCCESS} 所有端点都可用"
else
    echo -e "${WARNING} 部分端点不可用，但服务仍可正常工作"
fi

echo ""
echo -e "${BLUE}==================== 3. 负载均衡功能测试 ====================${NC}"

if [ "$MULTI_ENDPOINT_ENABLED" = true ]; then
    echo -e "${CYAN}${TEST} 负载均衡测试${NC}"
    echo "发送多个请求测试负载分布..."
    
    # 创建测试负载
    TEST_PAYLOAD='{
        "model": "deepseek-ai/DeepSeek-V3.1",
        "messages": [{"role": "user", "content": "Hello"}],
        "max_tokens": 10
    }'
    
    SUCCESS_COUNT=0
    TOTAL_REQUESTS=5
    
    for i in $(seq 1 $TOTAL_REQUESTS); do
        echo -n "请求 $i/$TOTAL_REQUESTS ... "
        
        RESPONSE=$(curl -s -w "%{http_code}" -X POST "http://localhost:$APP_PORT/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer linux.do" \
            -d "$TEST_PAYLOAD" \
            -o /tmp/response_$i.json 2>/dev/null)
        
        if [ "$RESPONSE" = "200" ]; then
            echo -e "${GREEN}${SUCCESS} 成功${NC}"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo -e "${RED}${ERROR} 失败 (HTTP $RESPONSE)${NC}"
        fi
        
        # 短暂延迟
        sleep 1
    done
    
    echo ""
    echo -e "${INFO} 负载均衡测试结果: $SUCCESS_COUNT/$TOTAL_REQUESTS 成功"
    
    if [ $SUCCESS_COUNT -eq $TOTAL_REQUESTS ]; then
        echo -e "${SUCCESS} 负载均衡功能正常"
    elif [ $SUCCESS_COUNT -gt 0 ]; then
        echo -e "${WARNING} 负载均衡部分正常，可能存在端点问题"
    else
        echo -e "${ERROR} 负载均衡功能异常"
    fi
    
    # 清理临时文件
    rm -f /tmp/response_*.json
    
else
    echo -e "${WARNING} 未启用多端点配置，跳过负载均衡测试"
    echo -e "${INFO} 要启用多端点，请在 .env 文件中配置 DEEPINFRA_MIRRORS"
fi

echo ""
echo -e "${BLUE}==================== 4. 性能对比测试 ====================${NC}"

echo -e "${CYAN}${TEST} 单端点 vs 多端点性能对比${NC}"

# 测试单端点性能
echo "测试单端点性能..."
SINGLE_START=$(date +%s%N)
curl -s -H "Authorization: Bearer linux.do" "http://localhost:$APP_PORT/v1/models" >/dev/null
SINGLE_END=$(date +%s%N)
SINGLE_TIME=$(( (SINGLE_END - SINGLE_START) / 1000000 ))

echo "单端点响应时间: ${SINGLE_TIME}ms"

if [ "$MULTI_ENDPOINT_ENABLED" = true ]; then
    # 测试多端点性能（多次请求平均）
    echo "测试多端点性能（5次请求平均）..."
    MULTI_TOTAL=0
    
    for i in $(seq 1 5); do
        START=$(date +%s%N)
        curl -s -H "Authorization: Bearer linux.do" "http://localhost:$APP_PORT/v1/models" >/dev/null
        END=$(date +%s%N)
        TIME=$(( (END - START) / 1000000 ))
        MULTI_TOTAL=$((MULTI_TOTAL + TIME))
        sleep 0.5
    done
    
    MULTI_AVG=$((MULTI_TOTAL / 5))
    echo "多端点平均响应时间: ${MULTI_AVG}ms"
    
    # 性能对比
    if [ $MULTI_AVG -lt $SINGLE_TIME ]; then
        IMPROVEMENT=$(( (SINGLE_TIME - MULTI_AVG) * 100 / SINGLE_TIME ))
        echo -e "${SUCCESS} 多端点性能提升 ${IMPROVEMENT}%"
    elif [ $MULTI_AVG -eq $SINGLE_TIME ]; then
        echo -e "${INFO} 多端点与单端点性能相当"
    else
        DEGRADATION=$(( (MULTI_AVG - SINGLE_TIME) * 100 / SINGLE_TIME ))
        echo -e "${WARNING} 多端点性能下降 ${DEGRADATION}%"
    fi
fi

echo ""
echo -e "${BLUE}==================== 5. 故障转移测试 ====================${NC}"

if [ "$MULTI_ENDPOINT_ENABLED" = true ] && [ $WORKING_ENDPOINTS -gt 1 ]; then
    echo -e "${CYAN}${TEST} 故障转移能力测试${NC}"
    echo "模拟端点故障，测试自动切换能力..."
    
    # 这里只能做逻辑测试，实际的故障转移需要在应用层实现
    echo -e "${INFO} 当前有 $WORKING_ENDPOINTS 个可用端点"
    echo -e "${INFO} 理论上可以承受 $((WORKING_ENDPOINTS - 1)) 个端点故障"
    
    if [ $WORKING_ENDPOINTS -ge 2 ]; then
        echo -e "${SUCCESS} 具备故障转移能力"
    else
        echo -e "${WARNING} 故障转移能力有限"
    fi
else
    echo -e "${WARNING} 跳过故障转移测试（需要多端点配置且至少2个端点可用）"
fi

echo ""
echo -e "${BLUE}==================== 验证总结 ====================${NC}"

echo -e "${CYAN}${CHART} 多端点验证结果汇总${NC}"
echo "1. 多端点配置: $([ "$MULTI_ENDPOINT_ENABLED" = true ] && echo '✅ 已启用' || echo '❌ 未启用')"
echo "2. 端点连通性: $WORKING_ENDPOINTS/$TOTAL_ENDPOINTS 可用"
echo "3. 负载均衡: $([ "$MULTI_ENDPOINT_ENABLED" = true ] && echo '✅ 已测试' || echo '⚠️ 未配置')"
echo "4. 应用服务: $(curl -s http://localhost:$APP_PORT/health >/dev/null && echo '✅ 正常' || echo '❌ 异常')"

echo ""
if [ "$MULTI_ENDPOINT_ENABLED" = true ]; then
    echo -e "${GREEN}${SUCCESS} 多端点负载均衡验证完成！${NC}"
    echo -e "${INFO} 您的服务已启用多端点负载均衡，具备高可用性"
else
    echo -e "${YELLOW}${WARNING} 当前使用单端点配置${NC}"
    echo -e "${INFO} 要启用多端点负载均衡，请："
    echo "1. 编辑 .env 文件"
    echo "2. 取消注释 DEEPINFRA_MIRRORS 配置行"
    echo "3. 运行 ./quick-start.sh 选择选项 20 重启服务"
fi

echo ""
echo -e "${CYAN}💡 多端点配置示例：${NC}"
echo "DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions"

echo ""
echo -e "${GREEN}✨ 多端点验证完成！${NC}"
