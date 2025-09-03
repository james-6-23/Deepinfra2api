#!/bin/bash

# 立即修复当前配置问题的脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔧 立即修复配置问题${NC}"
echo "=================================="

# 检查当前状态
echo -e "${CYAN}📊 当前配置状态${NC}"

if [ -f .env ]; then
    echo "1. 检查 .env 文件配置:"
    
    # 检查 DEEPINFRA_MIRRORS 配置
    mirrors_lines=$(grep -n "DEEPINFRA_MIRRORS=" .env)
    mirrors_count=$(echo "$mirrors_lines" | wc -l)
    
    if [ $mirrors_count -gt 1 ]; then
        echo -e "${RED}❌ 发现 $mirrors_count 个 DEEPINFRA_MIRRORS 配置行${NC}"
        echo "$mirrors_lines"
    elif [ $mirrors_count -eq 1 ]; then
        current_mirrors=$(grep "^DEEPINFRA_MIRRORS=" .env | cut -d'=' -f2-)
        if [ -n "$current_mirrors" ]; then
            endpoint_count=$(echo "$current_mirrors" | tr ',' '\n' | wc -l)
            echo -e "${GREEN}✅ 发现有效的多端点配置 ($endpoint_count 个端点)${NC}"
            echo "   配置: $current_mirrors"
        else
            echo -e "${YELLOW}⚠️ 发现空的 DEEPINFRA_MIRRORS 配置${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ 未找到 DEEPINFRA_MIRRORS 配置${NC}"
    fi
    
    echo ""
    echo "2. 检查容器配置:"
    if docker ps | grep -q "deepinfra-proxy-go"; then
        container_mirrors=$(docker exec deepinfra-proxy-go env | grep "^DEEPINFRA_MIRRORS=" | cut -d'=' -f2- 2>/dev/null)
        if [ -n "$container_mirrors" ]; then
            container_endpoint_count=$(echo "$container_mirrors" | tr ',' '\n' | wc -l)
            echo -e "${GREEN}✅ 容器配置 ($container_endpoint_count 个端点)${NC}"
            echo "   配置: $container_mirrors"
        else
            echo -e "${YELLOW}⚠️ 容器中未找到多端点配置${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ 未找到运行中的 Go 容器${NC}"
    fi
else
    echo -e "${RED}❌ 未找到 .env 文件${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}🛠️ 自动修复${NC}"

# 清理重复配置
echo "1. 清理重复的 DEEPINFRA_MIRRORS 配置..."

# 获取所有 DEEPINFRA_MIRRORS 配置
all_mirrors=$(grep "^DEEPINFRA_MIRRORS=" .env)
if [ $(echo "$all_mirrors" | wc -l) -gt 1 ]; then
    echo "   发现多个配置，保留最后一个有效配置"
    
    # 获取最后一个非空配置
    last_valid_mirrors=""
    while IFS= read -r line; do
        value=$(echo "$line" | cut -d'=' -f2-)
        if [ -n "$value" ]; then
            last_valid_mirrors="$value"
        fi
    done <<< "$all_mirrors"
    
    # 删除所有 DEEPINFRA_MIRRORS 行
    sed -i '/^DEEPINFRA_MIRRORS=/d' .env
    
    # 在合适位置插入配置
    if [ -n "$last_valid_mirrors" ]; then
        # 在多端点配置注释后插入
        if grep -q "# 多端点配置" .env; then
            sed -i "/# 启用多端点可以提高可用性和稳定性/a\\DEEPINFRA_MIRRORS=$last_valid_mirrors" .env
        else
            echo "DEEPINFRA_MIRRORS=$last_valid_mirrors" >> .env
        fi
        echo -e "${GREEN}   ✅ 已设置配置: $last_valid_mirrors${NC}"
    fi
else
    echo "   配置正常，无需清理"
fi

echo ""
echo "2. 验证配置有效性..."

current_mirrors=$(grep "^DEEPINFRA_MIRRORS=" .env | cut -d'=' -f2-)
if [ -n "$current_mirrors" ]; then
    endpoint_count=$(echo "$current_mirrors" | tr ',' '\n' | wc -l)
    echo -e "${GREEN}✅ 多端点配置有效 ($endpoint_count 个端点)${NC}"
    
    echo "   端点列表:"
    echo "$current_mirrors" | tr ',' '\n' | sed 's/^/     - /' | sed 's|/v1/openai/chat/completions||'
    
    # 测试端点连通性
    echo ""
    echo "3. 快速测试端点连通性..."
    working_endpoints=0
    
    IFS=',' read -ra ENDPOINTS <<< "$current_mirrors"
    for endpoint in "${ENDPOINTS[@]}"; do
        model_endpoint=$(echo "$endpoint" | sed 's|/chat/completions|/models|')
        domain=$(echo "$endpoint" | sed 's|https\?://||' | cut -d'/' -f1)
        
        echo -n "   测试 $domain ... "
        if timeout 5 curl -s "$model_endpoint" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ 可用${NC}"
            working_endpoints=$((working_endpoints + 1))
        else
            echo -e "${RED}❌ 不可用${NC}"
        fi
    done
    
    echo ""
    echo "   连通性统计: $working_endpoints/$endpoint_count 可用"
    
    if [ $working_endpoints -eq $endpoint_count ]; then
        echo -e "${GREEN}✅ 所有端点都可用${NC}"
    elif [ $working_endpoints -gt 0 ]; then
        echo -e "${YELLOW}⚠️ 部分端点可用，建议检查不可用的端点${NC}"
    else
        echo -e "${RED}❌ 所有端点都不可用，请检查网络连接${NC}"
    fi
else
    echo -e "${RED}❌ 多端点配置为空或无效${NC}"
    
    # 提供修复选项
    echo ""
    echo -e "${CYAN}🔧 修复选项${NC}"
    echo "1) 使用您的 Workers 端点配置"
    echo "2) 使用标准官方端点配置"
    echo "3) 手动输入配置"
    echo "0) 跳过"
    
    read -p "请选择 (0-3): " fix_choice
    
    case $fix_choice in
        1)
            workers_config="https://api.deepinfra.com/v1/openai/chat/completions,https://deepinfra2apipoint.1163476949.workers.dev/v1/openai/chat/completions,https://deepinfra22.kyxjames23.workers.dev/v1/openai/chat/completions"
            
            if grep -q "# 启用多端点可以提高可用性和稳定性" .env; then
                sed -i "/# 启用多端点可以提高可用性和稳定性/a\\DEEPINFRA_MIRRORS=$workers_config" .env
            else
                echo "DEEPINFRA_MIRRORS=$workers_config" >> .env
            fi
            
            echo -e "${GREEN}✅ 已配置 Workers 端点${NC}"
            ;;
        2)
            standard_config="https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions"
            
            if grep -q "# 启用多端点可以提高可用性和稳定性" .env; then
                sed -i "/# 启用多端点可以提高可用性和稳定性/a\\DEEPINFRA_MIRRORS=$standard_config" .env
            else
                echo "DEEPINFRA_MIRRORS=$standard_config" >> .env
            fi
            
            echo -e "${GREEN}✅ 已配置标准官方端点${NC}"
            ;;
        3)
            echo "请输入端点域名（用逗号分隔）:"
            read -r custom_domains
            
            if [ -n "$custom_domains" ]; then
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
                
                if grep -q "# 启用多端点可以提高可用性和稳定性" .env; then
                    sed -i "/# 启用多端点可以提高可用性和稳定性/a\\DEEPINFRA_MIRRORS=$mirrors" .env
                else
                    echo "DEEPINFRA_MIRRORS=$mirrors" >> .env
                fi
                
                echo -e "${GREEN}✅ 已配置自定义端点${NC}"
            fi
            ;;
        0)
            echo "跳过配置修复"
            ;;
    esac
fi

echo ""
echo -e "${BLUE}📋 后续操作建议${NC}"
echo "1. 重启服务应用配置: ./quick-start.sh (选择选项 20)"
echo "2. 验证多端点功能: ./verify-multi-endpoints.sh"
echo "3. 测试 Workers 端点: ./test-workers-endpoints.sh"

echo ""
echo -e "${GREEN}✨ 配置修复完成！${NC}"
