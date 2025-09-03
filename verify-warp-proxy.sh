#!/bin/bash

# WARP代理全面验证脚本
# 用于验证云服务器上WARP代理的完整工作状态

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

echo -e "${BLUE}${ROCKET} WARP代理全面验证工具${NC}"
echo "=================================="

# 获取服务器基本信息
echo -e "${CYAN}${INFO} 服务器基本信息${NC}"
echo "主机名: $(hostname)"
echo "内网IP: $(hostname -I | awk '{print $1}')"
echo "公网IP: $(curl -s ifconfig.me 2>/dev/null || echo '获取失败')"
echo "系统: $(uname -a | cut -d' ' -f1-3)"
echo "时间: $(date)"

echo ""
echo -e "${BLUE}==================== 1. Docker容器状态检查 ====================${NC}"

# 检查Docker服务状态
echo -e "${CYAN}${CHART} Docker服务状态${NC}"
if systemctl is-active --quiet docker; then
    echo -e "${SUCCESS} Docker服务运行正常"
else
    echo -e "${ERROR} Docker服务未运行"
fi

# 检查所有相关容器
echo -e "${CYAN}${CHART} 容器运行状态${NC}"
docker compose ps

echo ""
echo -e "${CYAN}${CHART} WARP容器详细状态${NC}"
if docker ps | grep -q "deepinfra-warp"; then
    echo -e "${SUCCESS} WARP容器正在运行"
    
    # 容器详细信息
    echo "容器ID: $(docker ps --filter name=deepinfra-warp --format '{{.ID}}')"
    echo "运行时间: $(docker ps --filter name=deepinfra-warp --format '{{.Status}}')"
    echo "容器IP: $(docker inspect deepinfra-warp --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')"
    
    # 容器资源使用情况
    echo -e "${CYAN}${CHART} WARP容器资源使用${NC}"
    docker stats deepinfra-warp --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    
else
    echo -e "${ERROR} WARP容器未运行"
    echo "请先启动WARP服务: docker compose --profile warp up -d"
    exit 1
fi

echo ""
echo -e "${CYAN}${CHART} 应用容器状态${NC}"
if docker ps | grep -q "deepinfra-proxy-go"; then
    APP_CONTAINER="deepinfra-proxy-go"
    APP_PORT="8001"
    APP_TYPE="Go"
    echo -e "${SUCCESS} Go应用容器正在运行"
elif docker ps | grep -q "deepinfra-proxy-deno"; then
    APP_CONTAINER="deepinfra-proxy-deno"
    APP_PORT="8000"
    APP_TYPE="Deno"
    echo -e "${SUCCESS} Deno应用容器正在运行"
else
    echo -e "${ERROR} 应用容器未运行"
    APP_CONTAINER=""
fi

if [ -n "$APP_CONTAINER" ]; then
    echo "应用类型: $APP_TYPE"
    echo "容器IP: $(docker inspect $APP_CONTAINER --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')"
    echo "端口映射: $APP_PORT"
fi

echo ""
echo -e "${BLUE}==================== 2. WARP代理连接验证 ====================${NC}"

echo -e "${CYAN}${TEST} WARP代理端口检查${NC}"
if docker exec deepinfra-warp netstat -tlnp 2>/dev/null | grep -q ":1080"; then
    echo -e "${SUCCESS} WARP代理端口1080正在监听"
    docker exec deepinfra-warp netstat -tlnp 2>/dev/null | grep ":1080"
else
    echo -e "${ERROR} WARP代理端口1080未监听"
fi

echo ""
echo -e "${CYAN}${TEST} WARP代理进程检查${NC}"
docker exec deepinfra-warp ps aux | grep -E "(warp|cloudflare)" | grep -v grep || echo "未找到WARP相关进程"

echo ""
echo -e "${CYAN}${TEST} WARP代理健康检查${NC}"
if docker exec deepinfra-warp curl -s --connect-timeout 10 --socks5-hostname 127.0.0.1:1080 https://cloudflare.com/cdn-cgi/trace 2>/dev/null | grep -q "warp=on"; then
    echo -e "${SUCCESS} WARP代理健康检查通过"
    echo "WARP状态详情:"
    docker exec deepinfra-warp curl -s --connect-timeout 10 --socks5-hostname 127.0.0.1:1080 https://cloudflare.com/cdn-cgi/trace 2>/dev/null | head -10
else
    echo -e "${ERROR} WARP代理健康检查失败"
fi

echo ""
echo -e "${CYAN}${TEST} Cloudflare网络连接测试${NC}"
echo "测试1: 直接连接Cloudflare"
if docker exec deepinfra-warp curl -s --connect-timeout 5 https://1.1.1.1 >/dev/null 2>&1; then
    echo -e "${SUCCESS} 直接连接Cloudflare成功"
else
    echo -e "${ERROR} 直接连接Cloudflare失败"
fi

echo "测试2: 通过WARP代理连接"
if docker exec deepinfra-warp curl -s --connect-timeout 10 --proxy socks5://localhost:1080 https://1.1.1.1 >/dev/null 2>&1; then
    echo -e "${SUCCESS} 通过WARP代理连接成功"
else
    echo -e "${ERROR} 通过WARP代理连接失败"
fi

echo "测试3: 获取WARP出口IP"
WARP_IP=$(docker exec deepinfra-warp curl -s --connect-timeout 10 --proxy socks5://localhost:1080 https://ifconfig.me 2>/dev/null)
if [ -n "$WARP_IP" ]; then
    echo -e "${SUCCESS} WARP出口IP: $WARP_IP"
else
    echo -e "${ERROR} 无法获取WARP出口IP"
fi

echo ""
echo -e "${BLUE}==================== 3. DeepInfra API访问测试 ====================${NC}"

echo -e "${CYAN}${TEST} 直接访问DeepInfra API（无代理）${NC}"
DIRECT_TEST=$(docker exec deepinfra-warp curl -s --connect-timeout 10 -w "%{http_code}" -o /dev/null https://api.deepinfra.com/v1/openai/models 2>/dev/null)
if [ "$DIRECT_TEST" = "200" ]; then
    echo -e "${SUCCESS} 直接访问DeepInfra API成功 (HTTP $DIRECT_TEST)"
else
    echo -e "${WARNING} 直接访问DeepInfra API失败 (HTTP $DIRECT_TEST)"
fi

echo ""
echo -e "${CYAN}${TEST} 通过WARP代理访问DeepInfra API${NC}"
PROXY_TEST=$(docker exec deepinfra-warp curl -s --connect-timeout 15 --proxy socks5://localhost:1080 -w "%{http_code}" -o /dev/null https://api.deepinfra.com/v1/openai/models 2>/dev/null)
if [ "$PROXY_TEST" = "200" ]; then
    echo -e "${SUCCESS} 通过WARP代理访问DeepInfra API成功 (HTTP $PROXY_TEST)"
else
    echo -e "${ERROR} 通过WARP代理访问DeepInfra API失败 (HTTP $PROXY_TEST)"
fi

echo ""
echo -e "${CYAN}${TEST} 获取DeepInfra模型列表（通过WARP代理）${NC}"
MODEL_LIST=$(docker exec deepinfra-warp curl -s --connect-timeout 15 --proxy socks5://localhost:1080 https://api.deepinfra.com/v1/openai/models 2>/dev/null)
if echo "$MODEL_LIST" | grep -q '"object": "list"'; then
    echo -e "${SUCCESS} 成功获取模型列表"
    MODEL_COUNT=$(echo "$MODEL_LIST" | grep -o '"id":' | wc -l)
    echo "模型数量: $MODEL_COUNT"
    echo "前5个模型:"
    echo "$MODEL_LIST" | jq -r '.data[0:5][].id' 2>/dev/null || echo "JSON解析失败，但数据已获取"
else
    echo -e "${ERROR} 获取模型列表失败"
fi

echo ""
echo -e "${BLUE}==================== 4. 应用服务代理使用验证 ====================${NC}"

if [ -n "$APP_CONTAINER" ]; then
    echo -e "${CYAN}${TEST} 应用容器环境变量检查${NC}"
    echo "代理相关环境变量:"
    docker exec $APP_CONTAINER env | grep -E "(HTTP_PROXY|HTTPS_PROXY|NO_PROXY)" || echo "未找到代理环境变量"
    
    echo ""
    echo -e "${CYAN}${TEST} 应用容器网络连接测试${NC}"
    echo "测试1: 应用容器访问外网"
    if docker exec $APP_CONTAINER curl -s --connect-timeout 5 http://www.google.com >/dev/null 2>&1; then
        echo -e "${SUCCESS} 应用容器可以访问外网"
    else
        echo -e "${WARNING} 应用容器无法直接访问外网（可能使用代理）"
    fi
    
    echo "测试2: 应用容器访问DeepInfra API"
    APP_API_TEST=$(docker exec $APP_CONTAINER curl -s --connect-timeout 15 -w "%{http_code}" -o /dev/null https://api.deepinfra.com/v1/openai/models 2>/dev/null)
    if [ "$APP_API_TEST" = "200" ]; then
        echo -e "${SUCCESS} 应用容器可以访问DeepInfra API (HTTP $APP_API_TEST)"
    else
        echo -e "${ERROR} 应用容器无法访问DeepInfra API (HTTP $APP_API_TEST)"
    fi
    
    echo ""
    echo -e "${CYAN}${TEST} 应用服务API功能测试${NC}"
    echo "测试1: 健康检查"
    if curl -s --connect-timeout 5 http://localhost:$APP_PORT/health >/dev/null 2>&1; then
        echo -e "${SUCCESS} 应用健康检查通过"
    else
        echo -e "${ERROR} 应用健康检查失败"
    fi
    
    echo "测试2: 模型列表API"
    if timeout 20 curl -s -H "Authorization: Bearer linux.do" http://localhost:$APP_PORT/v1/models >/dev/null 2>&1; then
        echo -e "${SUCCESS} 模型列表API正常"
    else
        echo -e "${ERROR} 模型列表API失败"
    fi
    
    echo "测试3: 聊天API测试"
    CHAT_TEST=$(timeout 30 curl -s -X POST http://localhost:$APP_PORT/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer linux.do" \
        -d '{"model":"deepseek-ai/DeepSeek-V3.1","messages":[{"role":"user","content":"Hello"}],"max_tokens":10}' 2>/dev/null)
    
    if echo "$CHAT_TEST" | grep -q '"choices"'; then
        echo -e "${SUCCESS} 聊天API测试成功"
    else
        echo -e "${ERROR} 聊天API测试失败"
    fi
fi

echo ""
echo -e "${BLUE}==================== 5. 代理效果对比测试 ====================${NC}"

echo -e "${CYAN}${TEST} IP地址对比测试${NC}"

# 获取服务器真实IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null)
echo "服务器真实IP: $SERVER_IP"

# 获取WARP代理IP
if [ -n "$WARP_IP" ]; then
    echo "WARP代理IP: $WARP_IP"
    
    if [ "$SERVER_IP" != "$WARP_IP" ]; then
        echo -e "${SUCCESS} IP地址已通过WARP代理改变"
    else
        echo -e "${WARNING} IP地址未改变，可能代理未生效"
    fi
else
    echo -e "${ERROR} 无法获取WARP代理IP"
fi

echo ""
echo -e "${CYAN}${TEST} 地理位置对比测试${NC}"
echo "服务器位置信息:"
curl -s "http://ip-api.com/json/$SERVER_IP" 2>/dev/null | jq -r '"\(.country) - \(.regionName) - \(.city)"' 2>/dev/null || echo "获取失败"

if [ -n "$WARP_IP" ]; then
    echo "WARP代理位置信息:"
    curl -s "http://ip-api.com/json/$WARP_IP" 2>/dev/null | jq -r '"\(.country) - \(.regionName) - \(.city)"' 2>/dev/null || echo "获取失败"
fi

echo ""
echo -e "${CYAN}${TEST} 网络延迟对比测试${NC}"
echo "直接访问延迟:"
docker exec deepinfra-warp curl -s -w "连接时间: %{time_connect}s, 总时间: %{time_total}s\n" -o /dev/null https://api.deepinfra.com/v1/openai/models 2>/dev/null

echo "WARP代理访问延迟:"
docker exec deepinfra-warp curl -s --proxy socks5://localhost:1080 -w "连接时间: %{time_connect}s, 总时间: %{time_total}s\n" -o /dev/null https://api.deepinfra.com/v1/openai/models 2>/dev/null

echo ""
echo -e "${BLUE}==================== 验证总结 ====================${NC}"

echo -e "${CYAN}${CHART} 验证结果汇总${NC}"
echo "1. WARP容器状态: $(docker ps | grep -q 'deepinfra-warp' && echo '✅ 运行中' || echo '❌ 未运行')"
echo "2. WARP代理端口: $(docker exec deepinfra-warp netstat -tlnp 2>/dev/null | grep -q ':1080' && echo '✅ 正常监听' || echo '❌ 未监听')"
echo "3. Cloudflare连接: $(docker exec deepinfra-warp curl -s --connect-timeout 5 --socks5-hostname 127.0.0.1:1080 https://cloudflare.com/cdn-cgi/trace 2>/dev/null | grep -q 'warp=on' && echo '✅ 连接正常' || echo '❌ 连接异常')"
echo "4. DeepInfra API: $([ "$PROXY_TEST" = "200" ] && echo '✅ 访问正常' || echo '❌ 访问异常')"
echo "5. 应用服务API: $(timeout 10 curl -s -H 'Authorization: Bearer linux.do' http://localhost:$APP_PORT/v1/models >/dev/null 2>&1 && echo '✅ 功能正常' || echo '❌ 功能异常')"
echo "6. IP地址变化: $([ -n "$WARP_IP" ] && [ "$SERVER_IP" != "$WARP_IP" ] && echo '✅ 已改变' || echo '❌ 未改变')"

echo ""
echo -e "${GREEN}${SUCCESS} WARP代理验证完成！${NC}"
echo ""
echo -e "${CYAN}💡 如果发现问题，请查看详细日志：${NC}"
echo "docker compose logs -f deepinfra-warp"
echo "docker compose logs -f $APP_CONTAINER"
