#!/bin/bash

# 高并发版本测试脚本
# 用于验证高并发配置是否正常工作

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 图标定义
SUCCESS="✅"
ERROR="❌"
WARNING="⚠️"
INFO="ℹ️"
ROCKET="🚀"
GEAR="⚙️"
TEST="🧪"
CHART="📊"

echo -e "${BLUE}${ROCKET} Go 高并发版本测试脚本${NC}"
echo "=================================="

# 检查服务状态
check_service() {
    local port=$1
    
    echo -e "${INFO} 检查 Go 高并发版本服务状态..."
    
    if curl -s -f "http://localhost:${port}/health" > /dev/null; then
        echo -e "${SUCCESS} Go 高并发版本服务运行正常 (端口 ${port})"
        return 0
    else
        echo -e "${ERROR} Go 高并发版本服务未运行或不可访问 (端口 ${port})"
        return 1
    fi
}

# 检查系统状态
check_system_status() {
    local port=$1
    
    echo -e "${CHART} 检查系统状态..."
    
    local status_response=$(curl -s "http://localhost:${port}/status" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$status_response" ]; then
        echo -e "${SUCCESS} 系统状态监控正常"
        echo -e "${INFO} 系统状态信息:"
        echo "$status_response" | python3 -m json.tool 2>/dev/null || echo "$status_response"
        return 0
    else
        echo -e "${ERROR} 系统状态监控不可用"
        return 1
    fi
}

# 并发测试
test_concurrency() {
    local port=$1
    local concurrent_requests=$2
    
    echo -e "${TEST} 测试并发能力 (${concurrent_requests} 并发请求)..."
    
    # 创建测试负载
    local test_payload='{
        "model": "deepseek-ai/DeepSeek-V3.1",
        "messages": [
            {
                "role": "user", 
                "content": "请简单介绍一下人工智能。"
            }
        ],
        "stream": false,
        "max_tokens": 100
    }'
    
    # 创建临时文件存储测试结果
    local temp_dir=$(mktemp -d)
    local success_count=0
    local error_count=0
    
    echo -e "${GEAR} 发送 ${concurrent_requests} 个并发请求..."
    
    # 并发发送请求
    for i in $(seq 1 $concurrent_requests); do
        {
            local response=$(curl -s -w "%{http_code}" -X POST "http://localhost:${port}/v1/chat/completions" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer linux.do" \
                -d "$test_payload" \
                -o "${temp_dir}/response_${i}.json" 2>/dev/null)
            
            if [ "$response" = "200" ]; then
                echo "SUCCESS" > "${temp_dir}/result_${i}.txt"
            else
                echo "ERROR_${response}" > "${temp_dir}/result_${i}.txt"
            fi
        } &
    done
    
    # 等待所有请求完成
    wait
    
    # 统计结果
    for i in $(seq 1 $concurrent_requests); do
        if [ -f "${temp_dir}/result_${i}.txt" ]; then
            local result=$(cat "${temp_dir}/result_${i}.txt")
            if [ "$result" = "SUCCESS" ]; then
                ((success_count++))
            else
                ((error_count++))
            fi
        else
            ((error_count++))
        fi
    done
    
    # 显示结果
    echo -e "${INFO} 并发测试结果:"
    echo -e "  • 成功请求: ${success_count}/${concurrent_requests}"
    echo -e "  • 失败请求: ${error_count}/${concurrent_requests}"
    echo -e "  • 成功率: $(( success_count * 100 / concurrent_requests ))%"
    
    # 清理临时文件
    rm -rf "$temp_dir"
    
    if [ $success_count -gt $(( concurrent_requests * 8 / 10 )) ]; then
        echo -e "${SUCCESS} 并发测试通过 (成功率 > 80%)"
        return 0
    else
        echo -e "${ERROR} 并发测试失败 (成功率 < 80%)"
        return 1
    fi
}

# 压力测试
stress_test() {
    local port=$1
    
    echo -e "${TEST} 执行压力测试..."
    
    # 检查是否安装了 ab (Apache Bench)
    if ! command -v ab &> /dev/null; then
        echo -e "${WARNING} Apache Bench (ab) 未安装，跳过压力测试"
        echo -e "${INFO} 安装方法: sudo apt-get install apache2-utils"
        return 0
    fi
    
    # 创建测试文件
    local test_file=$(mktemp)
    cat > "$test_file" << 'EOF'
{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": false,
    "max_tokens": 50
}
EOF
    
    echo -e "${GEAR} 执行 100 个请求，10 个并发..."
    
    # 执行压力测试
    local ab_result=$(ab -n 100 -c 10 -k \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer linux.do" \
        -p "$test_file" \
        "http://localhost:${port}/v1/chat/completions" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS} 压力测试完成"
        echo -e "${INFO} 测试结果摘要:"
        echo "$ab_result" | grep -E "(Requests per second|Time per request|Transfer rate)" || true
    else
        echo -e "${ERROR} 压力测试失败"
    fi
    
    # 清理测试文件
    rm -f "$test_file"
}

# 主测试流程
main() {
    local port=8001
    
    echo -e "${INFO} 开始高并发版本测试..."
    
    # 检查服务状态
    if ! check_service $port; then
        echo -e "${ERROR} 服务未运行，请先启动 Go 高并发版本"
        echo -e "${INFO} 启动方法: ./quick-start.sh 选择选项 9-12"
        exit 1
    fi
    
    echo ""
    
    # 检查系统状态监控
    check_system_status $port
    
    echo ""
    
    # 并发测试
    echo -e "${BLUE}=== 并发能力测试 ===${NC}"
    test_concurrency $port 50
    
    echo ""
    
    # 压力测试
    echo -e "${BLUE}=== 压力测试 ===${NC}"
    stress_test $port
    
    echo ""
    
    # 最终检查系统状态
    echo -e "${BLUE}=== 测试后系统状态 ===${NC}"
    check_system_status $port
    
    echo ""
    echo -e "${BLUE}${SUCCESS} 高并发版本测试完成！${NC}"
    echo -e "${INFO} 建议:"
    echo -e "  1. 持续监控系统状态: curl http://localhost:${port}/status"
    echo -e "  2. 查看详细日志: docker compose logs -f deepinfra-proxy-go"
    echo -e "  3. 根据实际负载调整并发配置"
}

# 运行主函数
main "$@"
