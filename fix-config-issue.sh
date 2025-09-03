#!/bin/bash

# 配置问题修复脚本
# 解决 .env 文件和容器配置不一致的问题

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔧 配置问题修复工具${NC}"
echo "=================================="

# 检测当前状态
echo -e "${CYAN}📊 当前状态检测${NC}"

# 检查 .env 文件
echo "1. .env 文件状态:"
if [ -f .env ]; then
    echo "   ✅ .env 文件存在"
    
    if grep -q "^DEEPINFRA_MIRRORS=" .env; then
        env_config=$(grep "^DEEPINFRA_MIRRORS=" .env | cut -d'=' -f2-)
        echo "   ✅ 发现未注释的配置: $env_config"
        ENV_HAS_CONFIG=true
    elif grep -q "^#.*DEEPINFRA_MIRRORS=" .env; then
        commented_config=$(grep "^#.*DEEPINFRA_MIRRORS=" .env | head -1)
        echo "   ⚠️ 发现被注释的配置: $commented_config"
        ENV_HAS_CONFIG=false
    else
        echo "   ❌ 未找到多端点配置"
        ENV_HAS_CONFIG=false
    fi
else
    echo "   ❌ .env 文件不存在"
    ENV_HAS_CONFIG=false
fi

echo ""

# 检查容器配置
echo "2. 容器配置状态:"
if docker ps | grep -q "deepinfra-proxy"; then
    if docker ps | grep -q "deepinfra-proxy-go"; then
        container_config=$(docker exec deepinfra-proxy-go env | grep "^DEEPINFRA_MIRRORS=" | cut -d'=' -f2- 2>/dev/null)
        if [ -n "$container_config" ]; then
            echo "   ✅ Go 容器配置: $container_config"
            CONTAINER_HAS_CONFIG=true
        else
            echo "   ❌ Go 容器未找到多端点配置"
            CONTAINER_HAS_CONFIG=false
        fi
    elif docker ps | grep -q "deepinfra-proxy-deno"; then
        container_config=$(docker exec deepinfra-proxy-deno env | grep "^DEEPINFRA_MIRRORS=" | cut -d'=' -f2- 2>/dev/null)
        if [ -n "$container_config" ]; then
            echo "   ✅ Deno 容器配置: $container_config"
            CONTAINER_HAS_CONFIG=true
        else
            echo "   ❌ Deno 容器未找到多端点配置"
            CONTAINER_HAS_CONFIG=false
        fi
    fi
else
    echo "   ❌ 未找到运行中的应用容器"
    CONTAINER_HAS_CONFIG=false
fi

echo ""

# 分析问题并提供解决方案
echo -e "${CYAN}🔍 问题分析${NC}"

if [ "$ENV_HAS_CONFIG" = true ] && [ "$CONTAINER_HAS_CONFIG" = true ]; then
    if [ "$env_config" = "$container_config" ]; then
        echo "✅ 配置一致，无需修复"
        exit 0
    else
        echo "⚠️ 配置不一致，需要同步"
        ISSUE_TYPE="inconsistent"
    fi
elif [ "$ENV_HAS_CONFIG" = false ] && [ "$CONTAINER_HAS_CONFIG" = true ]; then
    echo "⚠️ .env 文件缺少配置，但容器有配置"
    ISSUE_TYPE="env_missing"
elif [ "$ENV_HAS_CONFIG" = true ] && [ "$CONTAINER_HAS_CONFIG" = false ]; then
    echo "⚠️ .env 文件有配置，但容器缺少配置"
    ISSUE_TYPE="container_missing"
else
    echo "❌ 两边都没有配置"
    ISSUE_TYPE="both_missing"
fi

echo ""

# 提供修复选项
echo -e "${CYAN}🛠️ 修复选项${NC}"
echo "1) 从容器配置恢复到 .env 文件"
echo "2) 使用您的 Workers 端点配置"
echo "3) 使用标准官方端点配置"
echo "4) 手动输入自定义配置"
echo "5) 取消注释现有配置"
echo "0) 退出"
echo ""

read -p "请选择修复方案 (0-5): " choice

case $choice in
    1)
        if [ "$CONTAINER_HAS_CONFIG" = true ]; then
            echo -e "${BLUE}从容器配置恢复...${NC}"
            
            # 确保 .env 文件存在
            if [ ! -f .env ]; then
                if [ -f .env.example ]; then
                    cp .env.example .env
                else
                    touch .env
                fi
            fi
            
            # 更新配置
            if grep -q "^DEEPINFRA_MIRRORS=" .env; then
                sed -i "s|^DEEPINFRA_MIRRORS=.*|DEEPINFRA_MIRRORS=${container_config}|" .env
            elif grep -q "^#.*DEEPINFRA_MIRRORS=" .env; then
                sed -i "s|^#.*DEEPINFRA_MIRRORS=.*|DEEPINFRA_MIRRORS=${container_config}|" .env
            else
                echo "DEEPINFRA_MIRRORS=${container_config}" >> .env
            fi
            
            echo -e "${GREEN}✅ 已从容器恢复配置${NC}"
            echo "配置内容: $container_config"
        else
            echo -e "${RED}❌ 容器中没有配置可恢复${NC}"
        fi
        ;;
        
    2)
        echo -e "${BLUE}配置 Workers 端点...${NC}"
        
        # 基于您的 Workers 配置
        workers_config="https://api.deepinfra.com/v1/openai/chat/completions,https://deepinfra2apipoint.1163476949.workers.dev/v1/openai/chat/completions,https://deepinfra22.kyxjames23.workers.dev/v1/openai/chat/completions"
        
        # 确保 .env 文件存在
        if [ ! -f .env ]; then
            if [ -f .env.example ]; then
                cp .env.example .env
            else
                touch .env
            fi
        fi
        
        # 更新配置
        if grep -q "^DEEPINFRA_MIRRORS=" .env; then
            sed -i "s|^DEEPINFRA_MIRRORS=.*|DEEPINFRA_MIRRORS=${workers_config}|" .env
        elif grep -q "^#.*DEEPINFRA_MIRRORS=" .env; then
            sed -i "s|^#.*DEEPINFRA_MIRRORS=.*|DEEPINFRA_MIRRORS=${workers_config}|" .env
        else
            echo "DEEPINFRA_MIRRORS=${workers_config}" >> .env
        fi
        
        echo -e "${GREEN}✅ 已配置 Workers 端点${NC}"
        echo "配置内容:"
        echo "  - https://api.deepinfra.com/v1/openai/chat/completions"
        echo "  - https://deepinfra2apipoint.1163476949.workers.dev/v1/openai/chat/completions"
        echo "  - https://deepinfra22.kyxjames23.workers.dev/v1/openai/chat/completions"
        ;;
        
    3)
        echo -e "${BLUE}配置标准官方端点...${NC}"
        
        standard_config="https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions"
        
        # 确保 .env 文件存在
        if [ ! -f .env ]; then
            if [ -f .env.example ]; then
                cp .env.example .env
            else
                touch .env
            fi
        fi
        
        # 更新配置
        if grep -q "^DEEPINFRA_MIRRORS=" .env; then
            sed -i "s|^DEEPINFRA_MIRRORS=.*|DEEPINFRA_MIRRORS=${standard_config}|" .env
        elif grep -q "^#.*DEEPINFRA_MIRRORS=" .env; then
            sed -i "s|^#.*DEEPINFRA_MIRRORS=.*|DEEPINFRA_MIRRORS=${standard_config}|" .env
        else
            echo "DEEPINFRA_MIRRORS=${standard_config}" >> .env
        fi
        
        echo -e "${GREEN}✅ 已配置标准官方端点${NC}"
        echo "配置内容:"
        echo "  - https://api.deepinfra.com/v1/openai/chat/completions"
        echo "  - https://api1.deepinfra.com/v1/openai/chat/completions"
        echo "  - https://api2.deepinfra.com/v1/openai/chat/completions"
        ;;
        
    4)
        echo -e "${BLUE}手动输入自定义配置...${NC}"
        echo "请输入端点域名（用逗号分隔）:"
        echo "示例: api.deepinfra.com,your-worker.workers.dev"
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
            
            # 更新配置
            if grep -q "^DEEPINFRA_MIRRORS=" .env; then
                sed -i "s|^DEEPINFRA_MIRRORS=.*|DEEPINFRA_MIRRORS=${mirrors}|" .env
            elif grep -q "^#.*DEEPINFRA_MIRRORS=" .env; then
                sed -i "s|^#.*DEEPINFRA_MIRRORS=.*|DEEPINFRA_MIRRORS=${mirrors}|" .env
            else
                echo "DEEPINFRA_MIRRORS=${mirrors}" >> .env
            fi
            
            echo -e "${GREEN}✅ 已配置自定义端点${NC}"
            echo "配置内容:"
            echo "$mirrors" | tr ',' '\n' | sed 's/^/  - /'
        else
            echo -e "${YELLOW}⚠️ 未输入配置，操作取消${NC}"
        fi
        ;;
        
    5)
        if grep -q "^#.*DEEPINFRA_MIRRORS=" .env; then
            echo -e "${BLUE}取消注释现有配置...${NC}"
            sed -i 's|^#\(.*DEEPINFRA_MIRRORS=.*\)|\1|' .env
            
            uncommented_config=$(grep "^DEEPINFRA_MIRRORS=" .env | cut -d'=' -f2-)
            echo -e "${GREEN}✅ 已取消注释配置${NC}"
            echo "配置内容: $uncommented_config"
        else
            echo -e "${RED}❌ 未找到被注释的配置${NC}"
        fi
        ;;
        
    0)
        echo -e "${GREEN}退出修复工具${NC}"
        exit 0
        ;;
        
    *)
        echo -e "${RED}❌ 无效选择${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}📋 后续操作建议${NC}"
echo "1. 重启服务应用配置: ./quick-start.sh (选择选项 20)"
echo "2. 验证配置: ./verify-multi-endpoints.sh"
echo "3. 测试 API: curl -H \"Authorization: Bearer linux.do\" http://localhost:8001/v1/models"

echo ""
echo -e "${GREEN}✨ 配置修复完成！${NC}"
