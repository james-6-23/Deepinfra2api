#!/bin/bash

# 多端点配置恢复脚本
# 用于恢复丢失的多端点配置

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔧 多端点配置恢复工具${NC}"
echo "=================================="

# 检查当前配置状态
echo -e "${CYAN}📊 检查当前配置状态${NC}"

if [ -f .env ]; then
    echo "当前 .env 文件内容:"
    cat .env
    echo ""
    
    if grep -q "^DEEPINFRA_MIRRORS=" .env; then
        echo -e "${GREEN}✅ 检测到多端点配置${NC}"
        current_mirrors=$(grep "^DEEPINFRA_MIRRORS=" .env | cut -d'=' -f2-)
        echo "当前配置: $current_mirrors"
    else
        echo -e "${YELLOW}⚠️ 未检测到多端点配置${NC}"
    fi
else
    echo -e "${RED}❌ 未找到 .env 文件${NC}"
fi

echo ""

# 检查容器配置
echo -e "${CYAN}📊 检查容器配置状态${NC}"

if docker ps | grep -q "deepinfra-proxy"; then
    echo "检查容器内环境变量:"
    
    if docker ps | grep -q "deepinfra-proxy-go"; then
        echo "Go 容器配置:"
        docker exec deepinfra-proxy-go env | grep -E "(DEEPINFRA_MIRRORS|HTTP_PROXY)" || echo "未找到相关配置"
    fi
    
    if docker ps | grep -q "deepinfra-proxy-deno"; then
        echo "Deno 容器配置:"
        docker exec deepinfra-proxy-deno env | grep -E "(DEEPINFRA_MIRRORS|HTTP_PROXY)" || echo "未找到相关配置"
    fi
else
    echo -e "${YELLOW}⚠️ 未检测到运行中的应用容器${NC}"
fi

echo ""

# 提供配置选项
echo -e "${CYAN}🛠️ 配置恢复选项${NC}"
echo "1) 恢复标准多端点配置"
echo "2) 恢复自定义多端点配置"
echo "3) 恢复单端点配置"
echo "4) 从容器配置恢复"
echo "5) 查看配置建议"
echo "0) 退出"
echo ""

read -p "请选择 (0-5): " choice

case $choice in
    1)
        echo -e "${BLUE}恢复标准多端点配置...${NC}"
        
        # 确保 .env 文件存在
        if [ ! -f .env ]; then
            if [ -f .env.example ]; then
                cp .env.example .env
                echo "从 .env.example 创建 .env 文件"
            else
                touch .env
                echo "创建新的 .env 文件"
            fi
        fi
        
        # 添加标准多端点配置
        STANDARD_MIRRORS="https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions"
        
        if grep -q "^DEEPINFRA_MIRRORS=" .env; then
            sed -i "s|^DEEPINFRA_MIRRORS=.*|DEEPINFRA_MIRRORS=${STANDARD_MIRRORS}|" .env
        else
            echo "DEEPINFRA_MIRRORS=${STANDARD_MIRRORS}" >> .env
        fi
        
        echo -e "${GREEN}✅ 标准多端点配置已恢复${NC}"
        echo "配置内容:"
        echo "  - https://api.deepinfra.com/v1/openai/chat/completions"
        echo "  - https://api1.deepinfra.com/v1/openai/chat/completions"
        echo "  - https://api2.deepinfra.com/v1/openai/chat/completions"
        ;;
        
    2)
        echo -e "${BLUE}恢复自定义多端点配置...${NC}"
        echo "请输入端点域名（用逗号分隔）:"
        echo "示例: api.deepinfra.com,custom1.deepinfra.com,custom2.deepinfra.com"
        read -p "> " custom_domains
        
        if [ -n "$custom_domains" ]; then
            # 转换为完整URL
            mirrors=""
            IFS=',' read -ra DOMAINS <<< "$custom_domains"
            for domain in "${DOMAINS[@]}"; do
                domain=$(echo "$domain" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's|^https\?://||')
                
                if [ -n "$mirrors" ]; then
                    mirrors="$mirrors,https://$domain/v1/openai/chat/completions"
                else
                    mirrors="https://$domain/v1/openai/chat/completions"
                fi
            done
            
            # 确保 .env 文件存在
            if [ ! -f .env ]; then
                if [ -f .env.example ]; then
                    cp .env.example .env
                else
                    touch .env
                fi
            fi
            
            if grep -q "^DEEPINFRA_MIRRORS=" .env; then
                sed -i "s|^DEEPINFRA_MIRRORS=.*|DEEPINFRA_MIRRORS=${mirrors}|" .env
            else
                echo "DEEPINFRA_MIRRORS=${mirrors}" >> .env
            fi
            
            echo -e "${GREEN}✅ 自定义多端点配置已恢复${NC}"
            echo "配置内容:"
            echo "$mirrors" | tr ',' '\n' | sed 's/^/  - /'
        else
            echo -e "${YELLOW}⚠️ 未输入域名，操作取消${NC}"
        fi
        ;;
        
    3)
        echo -e "${BLUE}恢复单端点配置...${NC}"
        
        # 确保 .env 文件存在
        if [ ! -f .env ]; then
            if [ -f .env.example ]; then
                cp .env.example .env
            else
                touch .env
            fi
        fi
        
        SINGLE_ENDPOINT="https://api.deepinfra.com/v1/openai/chat/completions"
        
        if grep -q "^DEEPINFRA_MIRRORS=" .env; then
            sed -i "s|^DEEPINFRA_MIRRORS=.*|DEEPINFRA_MIRRORS=${SINGLE_ENDPOINT}|" .env
        else
            echo "DEEPINFRA_MIRRORS=${SINGLE_ENDPOINT}" >> .env
        fi
        
        echo -e "${GREEN}✅ 单端点配置已恢复${NC}"
        echo "配置内容: $SINGLE_ENDPOINT"
        ;;
        
    4)
        echo -e "${BLUE}从容器配置恢复...${NC}"
        
        if docker ps | grep -q "deepinfra-proxy-go"; then
            container_mirrors=$(docker exec deepinfra-proxy-go env | grep "^DEEPINFRA_MIRRORS=" | cut -d'=' -f2-)
            
            if [ -n "$container_mirrors" ]; then
                # 确保 .env 文件存在
                if [ ! -f .env ]; then
                    if [ -f .env.example ]; then
                        cp .env.example .env
                    else
                        touch .env
                    fi
                fi
                
                if grep -q "^DEEPINFRA_MIRRORS=" .env; then
                    sed -i "s|^DEEPINFRA_MIRRORS=.*|DEEPINFRA_MIRRORS=${container_mirrors}|" .env
                else
                    echo "DEEPINFRA_MIRRORS=${container_mirrors}" >> .env
                fi
                
                echo -e "${GREEN}✅ 从容器配置恢复成功${NC}"
                echo "恢复的配置: $container_mirrors"
            else
                echo -e "${YELLOW}⚠️ 容器中未找到多端点配置${NC}"
            fi
        else
            echo -e "${RED}❌ 未找到运行中的 Go 容器${NC}"
        fi
        ;;
        
    5)
        echo -e "${CYAN}📋 配置建议${NC}"
        echo ""
        echo "根据您的测试结果，建议使用以下配置:"
        echo ""
        echo "1. 标准配置（推荐）:"
        echo "   DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions"
        echo ""
        echo "2. 自定义配置（根据您的测试结果）:"
        echo "   - 只使用可用的端点"
        echo "   - 避免使用不可用的 api1.deepinfra.com 和 api2.deepinfra.com"
        echo ""
        echo "3. 单端点配置（最稳定）:"
        echo "   DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions"
        echo ""
        echo "4. 带 Workers 的配置（如果您有自定义端点）:"
        echo "   DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://deepinfra2apipoint.1163476949.workers.dev/v1/openai/chat/completions"
        ;;
        
    0)
        echo -e "${GREEN}退出配置恢复工具${NC}"
        exit 0
        ;;
        
    *)
        echo -e "${RED}❌ 无效选择${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}📋 后续操作建议${NC}"
echo "1. 检查配置: cat .env | grep DEEPINFRA_MIRRORS"
echo "2. 重启服务: ./quick-start.sh (选择选项 20)"
echo "3. 验证配置: ./verify-multi-endpoints.sh"

echo ""
echo -e "${GREEN}✨ 配置恢复完成！${NC}"
