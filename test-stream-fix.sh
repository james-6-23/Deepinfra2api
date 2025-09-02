#!/bin/bash

# Go 版本流式响应修复测试脚本
# 用于验证长响应是否还会被截断

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

echo -e "${BLUE}${ROCKET} Go 版本流式响应修复测试${NC}"
echo "=================================="

# 检查服务状态
check_service() {
    local port=$1
    local service_name=$2
    
    echo -e "${INFO} 检查 ${service_name} 服务状态..."
    
    if curl -s -f "http://localhost:${port}/health" > /dev/null; then
        echo -e "${SUCCESS} ${service_name} 服务运行正常 (端口 ${port})"
        return 0
    else
        echo -e "${ERROR} ${service_name} 服务未运行或不可访问 (端口 ${port})"
        return 1
    fi
}

# 测试长响应
test_long_response() {
    local port=$1
    local service_name=$2
    local output_file="test_${service_name}_$(date +%s).log"
    
    echo -e "${TEST} 测试 ${service_name} 长响应处理..."
    echo -e "${INFO} 输出将保存到: ${output_file}"
    
    # 构建测试请求
    local test_payload='{
        "model": "meta-llama/Meta-Llama-3.1-70B-Instruct",
        "messages": [
            {
                "role": "user", 
                "content": "请写一篇关于人工智能发展历史的详细文章，包含以下内容：1. AI的起源和早期发展 2. 机器学习的兴起 3. 深度学习革命 4. 大语言模型时代 5. 未来展望。每个部分都要详细说明，包含具体的时间节点、重要人物、技术突破等。文章应该至少2000字。"
            }
        ],
        "stream": true,
        "max_tokens": 4000,
        "temperature": 0.7
    }'
    
    echo -e "${GEAR} 开始流式请求..."
    echo -e "${WARNING} 这可能需要几分钟时间，请耐心等待..."
    
    # 记录开始时间
    start_time=$(date +%s)
    
    # 发送请求并记录响应
    if curl -X POST "http://localhost:${port}/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer linux.do" \
        -d "$test_payload" \
        --no-buffer \
        -w "\n\n=== 请求统计 ===\nHTTP状态码: %{http_code}\n总时间: %{time_total}s\n连接时间: %{time_connect}s\n传输时间: %{time_starttransfer}s\n下载大小: %{size_download} bytes\n" \
        > "$output_file" 2>&1; then
        
        # 记录结束时间
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        # 分析结果
        echo -e "${SUCCESS} 请求完成！用时: ${duration} 秒"
        
        # 检查是否有截断
        if grep -q "data: \[DONE\]" "$output_file"; then
            echo -e "${SUCCESS} 响应正常结束，未发现截断"
        else
            echo -e "${ERROR} 响应可能被截断，未找到结束标记"
        fi
        
        # 统计响应数据
        local line_count=$(grep -c "data: " "$output_file" || echo "0")
        local content_lines=$(grep -c '"content":' "$output_file" || echo "0")
        local file_size=$(wc -c < "$output_file")
        
        echo -e "${INFO} 响应统计:"
        echo -e "  • 数据行数: ${line_count}"
        echo -e "  • 内容行数: ${content_lines}"
        echo -e "  • 文件大小: ${file_size} bytes"
        echo -e "  • 日志文件: ${output_file}"
        
        return 0
    else
        echo -e "${ERROR} 请求失败"
        return 1
    fi
}

# 主测试流程
main() {
    echo -e "${INFO} 开始测试流程..."
    
    # 检查 Go 版本服务
    if check_service 8001 "Go版本"; then
        test_long_response 8001 "go"
    else
        echo -e "${WARNING} Go 版本服务未运行，跳过测试"
        echo -e "${INFO} 请先启动 Go 版本服务："
        echo -e "  cd go-version && docker-compose up -d"
    fi
    
    echo ""
    
    # 检查 Deno 版本服务（对比测试）
    if check_service 8000 "Deno版本"; then
        echo -e "${INFO} 发现 Deno 版本服务，进行对比测试..."
        test_long_response 8000 "deno"
    else
        echo -e "${INFO} Deno 版本服务未运行，跳过对比测试"
    fi
    
    echo ""
    echo -e "${BLUE}${SUCCESS} 测试完成！${NC}"
    echo -e "${INFO} 请检查生成的日志文件来分析结果"
    echo -e "${INFO} 如果 Go 版本仍然出现截断，请检查："
    echo -e "  1. 环境变量配置是否正确"
    echo -e "  2. Docker 容器是否使用了新的配置"
    echo -e "  3. 网络连接是否稳定"
}

# 运行主函数
main "$@"
