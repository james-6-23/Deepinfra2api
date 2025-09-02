#!/bin/bash

# DeepInfra2API 统一启动脚本
# 支持多端点配置和完整的部署选项

echo "🚀 DeepInfra2API 统一启动脚本"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装，请先安装 Docker${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose 未安装，请先安装 Docker Compose${NC}"
    exit 1
fi

# 多端点配置选项
configure_endpoints() {
    echo -e "${CYAN}🌐 配置多端点负载均衡${NC}"
    echo "多端点可以提高可用性和稳定性，支持故障转移"
    echo ""
    echo "预设配置选项："
    echo "1) 单端点（默认）- 仅使用官方 API"
    echo "2) 双端点配置 - 官方 + 备用端点"
    echo "3) 三端点配置 - 官方 + 两个备用端点"
    echo "4) 自定义配置 - 手动输入端点"
    echo "5) 跳过配置 - 使用现有配置"

    read -p "请选择端点配置 (1-5): " endpoint_choice

    case $endpoint_choice in
        1)
            # 单端点 - 清空 DEEPINFRA_MIRRORS
            sed -i 's/^DEEPINFRA_MIRRORS=.*/DEEPINFRA_MIRRORS=/' .env 2>/dev/null || true
            echo -e "${GREEN}✅ 配置为单端点模式${NC}"
            ;;
        2)
            # 双端点配置
            mirrors="https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions"
            update_env_var "DEEPINFRA_MIRRORS" "$mirrors"
            echo -e "${GREEN}✅ 配置为双端点模式${NC}"
            ;;
        3)
            # 三端点配置
            mirrors="https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions"
            update_env_var "DEEPINFRA_MIRRORS" "$mirrors"
            echo -e "${GREEN}✅ 配置为三端点模式${NC}"
            ;;
        4)
            # 自定义配置
            echo "请输入端点 URL（用逗号分隔）："
            echo "示例: https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions"
            read -p "端点列表: " custom_mirrors
            if [ -n "$custom_mirrors" ]; then
                update_env_var "DEEPINFRA_MIRRORS" "$custom_mirrors"
                echo -e "${GREEN}✅ 自定义端点配置完成${NC}"
            else
                echo -e "${YELLOW}⚠️  输入为空，保持现有配置${NC}"
            fi
            ;;
        5)
            echo -e "${BLUE}ℹ️  跳过端点配置${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠️  无效选择，使用默认单端点配置${NC}"
            sed -i 's/^DEEPINFRA_MIRRORS=.*/DEEPINFRA_MIRRORS=/' .env 2>/dev/null || true
            ;;
    esac
    echo ""
}

# 更新环境变量
update_env_var() {
    local var_name=$1
    local var_value=$2

    if grep -q "^${var_name}=" .env; then
        # 变量存在，更新它
        sed -i "s|^${var_name}=.*|${var_name}=${var_value}|" .env
    else
        # 变量不存在，添加它
        echo "${var_name}=${var_value}" >> .env
    fi
}

# 测试部署函数
test_deployment() {
    echo -e "${CYAN}🧪 开始测试部署...${NC}"

    # 读取配置
    source .env 2>/dev/null || true
    DENO_PORT=${DENO_PORT:-8000}
    GO_PORT=${GO_PORT:-8001}
    API_KEY=${VALID_API_KEYS%%,*}  # 取第一个 API Key

    # 检查运行中的容器
    echo -e "${BLUE}📊 检查运行中的服务...${NC}"
    docker compose ps

    # 测试函数
    test_endpoint() {
        local name=$1
        local url=$2
        local expected_status=$3

        echo -n "测试 $name... "

        response=$(curl -s -w "%{http_code}" -o /tmp/response.json "$url" 2>/dev/null)
        status_code="${response: -3}"

        if [ "$status_code" = "$expected_status" ]; then
            echo -e "${GREEN}✅ 通过${NC} (状态码: $status_code)"
            return 0
        else
            echo -e "${RED}❌ 失败${NC} (状态码: $status_code, 期望: $expected_status)"
            return 1
        fi
    }

    test_api_endpoint() {
        local name=$1
        local url=$2
        local api_key=$3

        echo -n "测试 $name API... "

        response=$(curl -s -w "%{http_code}" -o /tmp/api_response.json \
            -H "Authorization: Bearer $api_key" \
            "$url" 2>/dev/null)
        status_code="${response: -3}"

        if [ "$status_code" = "200" ]; then
            echo -e "${GREEN}✅ 通过${NC}"
            return 0
        else
            echo -e "${RED}❌ 失败${NC} (状态码: $status_code)"
            return 1
        fi
    }

    # 检测可用的端口
    available_ports=()
    if curl -s "http://localhost:$DENO_PORT/health" >/dev/null 2>&1; then
        available_ports+=("$DENO_PORT:Deno")
    fi
    if curl -s "http://localhost:$GO_PORT/health" >/dev/null 2>&1; then
        available_ports+=("$GO_PORT:Go")
    fi

    if [ ${#available_ports[@]} -eq 0 ]; then
        echo -e "${RED}❌ 没有检测到运行中的服务${NC}"
        echo -e "${YELLOW}💡 请先启动服务后再进行测试${NC}"
        return 1
    fi

    echo -e "${BLUE}🔍 检测到 ${#available_ports[@]} 个运行中的服务${NC}"

    # 测试每个可用的服务
    failed_tests=0
    passed_tests=0

    for port_info in "${available_ports[@]}"; do
        port="${port_info%%:*}"
        version="${port_info##*:}"

        echo -e "${YELLOW}测试 $version 版本 (端口 $port):${NC}"

        # 测试健康检查
        if test_endpoint "健康检查" "http://localhost:$port/health" "200"; then
            ((passed_tests++))
        else
            ((failed_tests++))
        fi

        # 测试模型列表
        if test_api_endpoint "模型列表" "http://localhost:$port/v1/models" "$API_KEY"; then
            ((passed_tests++))
        else
            ((failed_tests++))
        fi

        # 测试聊天 API
        echo -n "测试聊天 API... "
        response=$(curl -s -w "%{http_code}" -o /tmp/chat_response.json \
            -X POST "http://localhost:$port/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $API_KEY" \
            -d '{
                "model": "deepseek-ai/DeepSeek-V3.1",
                "messages": [{"role": "user", "content": "Hello! Just say hi back."}],
                "stream": false,
                "max_tokens": 10
            }' 2>/dev/null)

        status_code="${response: -3}"
        if [ "$status_code" = "200" ]; then
            echo -e "${GREEN}✅ 通过${NC}"
            ((passed_tests++))
        else
            echo -e "${RED}❌ 失败${NC} (状态码: $status_code)"
            ((failed_tests++))
        fi

        echo ""
    done

    # 显示测试结果
    echo -e "${BLUE}📊 测试结果:${NC}"
    echo "通过: $passed_tests"
    echo "失败: $failed_tests"

    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}🎉 所有测试通过！${NC}"
        return 0
    else
        echo -e "${RED}❌ 有测试失败，请检查日志${NC}"
        echo -e "${BLUE}📋 查看日志命令:${NC}"
        echo "  docker compose logs deepinfra-proxy-deno"
        echo "  docker compose logs deepinfra-proxy-go"
        echo "  docker compose logs deepinfra-warp"
        return 1
    fi
}

# 检查并创建 .env 文件
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env 文件不存在，从 .env.example 创建...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${GREEN}✅ .env 文件已创建${NC}"
    else
        echo -e "${RED}❌ .env.example 文件不存在${NC}"
        exit 1
    fi
fi

# 显示选项
echo -e "${BLUE}🎯 请选择操作:${NC}"
echo "1) Deno 版本 (端口 8000) - 推荐用于开发"
echo "2) Go 版本 (端口 8001) - 推荐用于生产"
echo "3) 两个版本同时部署"
echo "4) Deno + WARP 代理"
echo "5) Go + WARP 代理"
echo "6) 两个版本 + WARP 代理"
echo "7) 仅 WARP 代理"
echo "8) 配置多端点负载均衡"
echo "9) 测试部署"
echo "10) 停止所有服务"
echo "11) 查看服务状态"

read -p "请选择 (1-11): " choice

case $choice in
    1)
        echo -e "${BLUE}🦕 启动 Deno 版本...${NC}"
        docker compose --profile deno up -d --build
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Deno 版本启动成功！${NC}"
            echo -e "${BLUE}🔗 访问地址: http://localhost:8000${NC}"
            echo -e "${BLUE}📊 健康检查: curl http://localhost:8000/health${NC}"
        fi
        ;;
    2)
        echo -e "${BLUE}🐹 启动 Go 版本...${NC}"
        docker compose --profile go up -d --build
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Go 版本启动成功！${NC}"
            echo -e "${BLUE}🔗 访问地址: http://localhost:8001${NC}"
            echo -e "${BLUE}📊 健康检查: curl http://localhost:8001/health${NC}"
        fi
        ;;
    3)
        echo -e "${BLUE}🔄 启动两个版本...${NC}"
        docker compose --profile deno --profile go up -d --build
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ 两个版本启动成功！${NC}"
            echo -e "${BLUE}🔗 Deno 版本: http://localhost:8000${NC}"
            echo -e "${BLUE}🔗 Go 版本: http://localhost:8001${NC}"
        fi
        ;;
    4)
        echo -e "${BLUE}🦕🛡️ 启动 Deno + WARP...${NC}"
        docker compose --profile warp --profile deno up -d --build
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Deno + WARP 启动成功！${NC}"
            echo -e "${BLUE}🔗 访问地址: http://localhost:8000${NC}"
            echo -e "${YELLOW}⏳ WARP 代理需要约 30 秒启动时间${NC}"
        fi
        ;;
    5)
        echo -e "${BLUE}🐹🛡️ 启动 Go + WARP...${NC}"
        docker compose --profile warp --profile go up -d --build
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Go + WARP 启动成功！${NC}"
            echo -e "${BLUE}🔗 访问地址: http://localhost:8001${NC}"
            echo -e "${YELLOW}⏳ WARP 代理需要约 30 秒启动时间${NC}"
        fi
        ;;
    6)
        echo -e "${BLUE}🔄🛡️ 启动两个版本 + WARP...${NC}"
        docker compose --profile warp --profile deno --profile go up -d --build
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ 完整部署启动成功！${NC}"
            echo -e "${BLUE}🔗 Deno 版本: http://localhost:8000${NC}"
            echo -e "${BLUE}🔗 Go 版本: http://localhost:8001${NC}"
            echo -e "${YELLOW}⏳ WARP 代理需要约 30 秒启动时间${NC}"
        fi
        ;;
    7)
        echo -e "${BLUE}🛡️ 启动 WARP 代理...${NC}"
        docker compose --profile warp up -d --build
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ WARP 代理启动成功！${NC}"
            echo -e "${YELLOW}⏳ WARP 代理需要约 30 秒启动时间${NC}"
        fi
        ;;
    8)
        echo -e "${BLUE}🌐 配置多端点负载均衡...${NC}"
        configure_endpoints
        ;;
    9)
        echo -e "${BLUE}🧪 测试部署...${NC}"
        test_deployment
        ;;
    10)
        echo -e "${BLUE}🛑 停止所有服务...${NC}"
        docker compose down
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ 所有服务已停止${NC}"
        fi
        ;;
    11)
        echo -e "${BLUE}📊 服务状态:${NC}"
        docker compose ps
        echo ""
        echo -e "${BLUE}📋 容器日志查看命令:${NC}"
        echo "  docker compose logs -f deepinfra-proxy-deno"
        echo "  docker compose logs -f deepinfra-proxy-go"
        echo "  docker compose logs -f deepinfra-warp"
        ;;
    *)
        echo -e "${RED}❌ 无效选择${NC}"
        exit 1
        ;;
esac

# 如果是启动操作，显示额外信息
if [[ $choice -ge 1 && $choice -le 7 ]]; then
    echo ""
    echo -e "${BLUE}📋 有用的命令:${NC}"
    echo "  查看状态: docker compose ps"
    echo "  查看日志: docker compose logs -f"
    echo "  停止服务: docker compose down"
    echo "  重启服务: docker compose restart"
    echo ""
    echo -e "${BLUE}🧪 运行测试:${NC}"
    echo "  chmod +x test-deployment.sh && ./test-deployment.sh"
    echo ""
    echo -e "${BLUE}📖 查看完整文档:${NC}"
    echo "  cat DEPLOYMENT_GUIDE.md"
fi
