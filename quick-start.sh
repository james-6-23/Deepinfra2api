#!/bin/bash

# DeepInfra2API 统一启动脚本
# 支持多端点配置、WARP 代理和循环交互

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 显示标题
show_title() {
    clear
    echo -e "${CYAN}🚀 DeepInfra2API 统一启动脚本${NC}"
    echo -e "${CYAN}================================${NC}"
    echo ""
}

# 更新环境变量函数
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

# 端口扫描和管理函数
check_port_available() {
    local port=$1
    local protocol=${2:-tcp}

    # 使用多种方法检查端口是否可用
    if command -v netstat >/dev/null 2>&1; then
        # 使用 netstat 检查 (Windows/Linux)
        if netstat -an 2>/dev/null | grep -q ":${port} "; then
            return 1  # 端口被占用
        fi
    elif command -v ss >/dev/null 2>&1; then
        # 使用 ss 检查（Linux 现代工具）
        if ss -tuln 2>/dev/null | grep -q ":${port} "; then
            return 1  # 端口被占用
        fi
    elif command -v lsof >/dev/null 2>&1; then
        # 使用 lsof 检查（macOS/Linux）
        if lsof -i :${port} >/dev/null 2>&1; then
            return 1  # 端口被占用
        fi
    fi

    # 最后使用 PowerShell 检查（Windows 兼容）
    if command -v powershell >/dev/null 2>&1; then
        if powershell -Command "Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue" 2>/dev/null | grep -q "$port"; then
            return 1  # 端口被占用
        fi
    fi

    # 使用 nc 作为最后手段
    if command -v nc >/dev/null 2>&1; then
        if nc -z localhost ${port} 2>/dev/null; then
            return 1  # 端口被占用
        fi
    fi

    return 0  # 端口可用
}

# 查找可用端口
find_available_port() {
    local start_port=$1
    local max_attempts=${2:-50}

    for ((i=0; i<max_attempts; i++)); do
        local test_port=$((start_port + i))
        if check_port_available $test_port; then
            echo $test_port
            return 0
        fi
    done

    return 1  # 未找到可用端口
}

# 获取当前使用的端口
get_current_ports() {
    local deno_port=$(grep "^DENO_PORT=" .env 2>/dev/null | cut -d'=' -f2)
    local go_port=$(grep "^GO_PORT=" .env 2>/dev/null | cut -d'=' -f2)

    # 设置默认值
    deno_port=${deno_port:-8000}
    go_port=${go_port:-8001}

    echo "$deno_port $go_port"
}

# 端口配置向导
configure_ports() {
    local deployment_type=$1  # "deno", "go", "both"

    echo ""
    echo -e "${CYAN}🔌 端口配置向导${NC}"
    echo -e "${CYAN}================================${NC}"
    echo "正在扫描可用端口..."

    # 获取当前端口配置
    local current_ports=($(get_current_ports))
    local current_deno_port=${current_ports[0]}
    local current_go_port=${current_ports[1]}

    # 检查当前端口状态
    local deno_available=false
    local go_available=false

    if [ "$deployment_type" = "deno" ] || [ "$deployment_type" = "both" ]; then
        if check_port_available $current_deno_port; then
            deno_available=true
        fi
    fi

    if [ "$deployment_type" = "go" ] || [ "$deployment_type" = "both" ]; then
        if check_port_available $current_go_port; then
            go_available=true
        fi
    fi

    echo ""
    echo -e "${BLUE}📊 端口状态扫描结果:${NC}"

    if [ "$deployment_type" = "deno" ] || [ "$deployment_type" = "both" ]; then
        if $deno_available; then
            echo -e "  Deno 端口 $current_deno_port: ${GREEN}✅ 可用${NC}"
        else
            echo -e "  Deno 端口 $current_deno_port: ${RED}❌ 被占用${NC}"
        fi
    fi

    if [ "$deployment_type" = "go" ] || [ "$deployment_type" = "both" ]; then
        if $go_available; then
            echo -e "  Go 端口 $current_go_port: ${GREEN}✅ 可用${NC}"
        else
            echo -e "  Go 端口 $current_go_port: ${RED}❌ 被占用${NC}"
        fi
    fi

    echo ""

    # 如果有端口冲突，提供解决方案
    local need_reconfigure=false

    if [ "$deployment_type" = "deno" ] || [ "$deployment_type" = "both" ]; then
        if ! $deno_available; then
            need_reconfigure=true
        fi
    fi

    if [ "$deployment_type" = "go" ] || [ "$deployment_type" = "both" ]; then
        if ! $go_available; then
            need_reconfigure=true
        fi
    fi

    if $need_reconfigure; then
        echo -e "${YELLOW}⚠️  检测到端口冲突，需要重新配置端口${NC}"
        echo ""
        echo -e "${BLUE}请选择处理方式:${NC}"
        echo "  1) 自动分配可用端口 ${GREEN}(推荐)${NC}"
        echo "  2) 手动指定端口"
        echo "  3) 使用默认端口 ${RED}(可能导致冲突)${NC}"
        echo ""

        while true; do
            read -p "请选择 (1-3): " port_choice

            case $port_choice in
                1)
                    echo ""
                    if auto_assign_ports "$deployment_type"; then
                        break
                    else
                        echo -e "${RED}❌ 自动分配失败，请选择其他方式${NC}"
                        echo ""
                    fi
                    ;;
                2)
                    echo ""
                    if manual_assign_ports "$deployment_type"; then
                        break
                    else
                        echo -e "${RED}❌ 手动配置失败，请重试${NC}"
                        echo ""
                    fi
                    ;;
                3)
                    echo ""
                    echo -e "${YELLOW}⚠️  使用默认端口，可能存在冲突风险${NC}"
                    break
                    ;;
                *)
                    echo -e "${RED}❌ 无效选择，请输入 1、2 或 3${NC}"
                    ;;
            esac
        done
    else
        echo -e "${GREEN}✅ 所有端口都可用，无需重新配置${NC}"
    fi

    echo ""
}

# 自动分配端口
auto_assign_ports() {
    local deployment_type=$1
    local success=true

    echo -e "${BLUE}🔍 自动扫描可用端口...${NC}"

    if [ "$deployment_type" = "deno" ] || [ "$deployment_type" = "both" ]; then
        echo "  正在为 Deno 版本查找可用端口..."
        local new_deno_port=$(find_available_port 8000)
        if [ $? -eq 0 ] && [ -n "$new_deno_port" ]; then
            update_env_var "DENO_PORT" "$new_deno_port"
            echo -e "  Deno 端口: ${GREEN}$new_deno_port${NC}"
        else
            echo -e "  ${RED}❌ 无法找到 Deno 可用端口 (尝试范围: 8000-8049)${NC}"
            success=false
        fi
    fi

    if [ "$deployment_type" = "go" ] || [ "$deployment_type" = "both" ]; then
        echo "  正在为 Go 版本查找可用端口..."
        local new_go_port=$(find_available_port 8001)
        if [ $? -eq 0 ] && [ -n "$new_go_port" ]; then
            update_env_var "GO_PORT" "$new_go_port"
            echo -e "  Go 端口: ${GREEN}$new_go_port${NC}"
        else
            echo -e "  ${RED}❌ 无法找到 Go 可用端口 (尝试范围: 8001-8050)${NC}"
            success=false
        fi
    fi

    if $success; then
        echo -e "${GREEN}✅ 端口自动配置完成${NC}"
        return 0
    else
        echo -e "${RED}❌ 端口自动配置失败${NC}"
        return 1
    fi
}

# 手动分配端口
manual_assign_ports() {
    local deployment_type=$1
    local success=true

    echo -e "${BLUE}✏️  手动端口配置${NC}"
    echo -e "${YELLOW}提示: 端口范围建议 1024-65535，避免使用系统保留端口${NC}"
    echo ""

    if [ "$deployment_type" = "deno" ] || [ "$deployment_type" = "both" ]; then
        local attempts=0
        while [ $attempts -lt 3 ]; do
            read -p "请输入 Deno 版本端口 (建议 8000-8099，回车使用默认 8000): " deno_port

            # 如果用户直接回车，使用默认端口
            if [ -z "$deno_port" ]; then
                deno_port=8000
            fi

            if [[ "$deno_port" =~ ^[0-9]+$ ]] && [ "$deno_port" -ge 1024 ] && [ "$deno_port" -le 65535 ]; then
                if check_port_available "$deno_port"; then
                    update_env_var "DENO_PORT" "$deno_port"
                    echo -e "  Deno 端口设置为: ${GREEN}$deno_port${NC}"
                    break
                else
                    echo -e "  ${RED}❌ 端口 $deno_port 已被占用，请选择其他端口${NC}"
                    attempts=$((attempts + 1))
                fi
            else
                echo -e "  ${RED}❌ 无效端口号，请输入 1024-65535 之间的数字${NC}"
                attempts=$((attempts + 1))
            fi

            if [ $attempts -eq 3 ]; then
                echo -e "  ${RED}❌ 尝试次数过多，Deno 端口配置失败${NC}"
                success=false
            fi
        done
    fi

    if [ "$deployment_type" = "go" ] || [ "$deployment_type" = "both" ]; then
        local attempts=0
        while [ $attempts -lt 3 ]; do
            read -p "请输入 Go 版本端口 (建议 8001-8099，回车使用默认 8001): " go_port

            # 如果用户直接回车，使用默认端口
            if [ -z "$go_port" ]; then
                go_port=8001
            fi

            if [[ "$go_port" =~ ^[0-9]+$ ]] && [ "$go_port" -ge 1024 ] && [ "$go_port" -le 65535 ]; then
                if check_port_available "$go_port"; then
                    update_env_var "GO_PORT" "$go_port"
                    echo -e "  Go 端口设置为: ${GREEN}$go_port${NC}"
                    break
                else
                    echo -e "  ${RED}❌ 端口 $go_port 已被占用，请选择其他端口${NC}"
                    attempts=$((attempts + 1))
                fi
            else
                echo -e "  ${RED}❌ 无效端口号，请输入 1024-65535 之间的数字${NC}"
                attempts=$((attempts + 1))
            fi

            if [ $attempts -eq 3 ]; then
                echo -e "  ${RED}❌ 尝试次数过多，Go 端口配置失败${NC}"
                success=false
            fi
        done
    fi

    if $success; then
        echo -e "${GREEN}✅ 端口手动配置完成${NC}"
        return 0
    else
        echo -e "${RED}❌ 端口手动配置失败${NC}"
        return 1
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

    # 获取实际端口配置
    local current_ports=($(get_current_ports))
    local actual_deno_port=${current_ports[0]}
    local actual_go_port=${current_ports[1]}

    # 检测可用的端口
    available_ports=()
    if curl -s "http://localhost:$actual_deno_port/health" >/dev/null 2>&1; then
        available_ports+=("$actual_deno_port:Deno")
    fi
    if curl -s "http://localhost:$actual_go_port/health" >/dev/null 2>&1; then
        available_ports+=("$actual_go_port:Go")
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

# 显示主菜单
show_menu() {
    echo -e "${BLUE}🎯 请选择部署方案:${NC}"
    echo ""
    echo -e "${YELLOW}📦 Deno 版本部署 (端口 8000) - 推荐用于开发${NC}"
    echo "  1) Deno 基础版"
    echo "  2) Deno + 多端点负载均衡"
    echo "  3) Deno + WARP 代理"
    echo "  4) Deno + 多端点 + WARP 代理"
    echo ""
    echo -e "${YELLOW}🐹 Go 版本部署 (端口 8001) - 推荐用于生产${NC}"
    echo "  5) Go 基础版"
    echo "  6) Go + 多端点负载均衡"
    echo "  7) Go + WARP 代理"
    echo "  8) Go + 多端点 + WARP 代理"
    echo ""
    echo -e "${YELLOW}🔄 双版本部署${NC}"
    echo "  9) 双版本基础部署"
    echo "  10) 双版本 + 多端点负载均衡"
    echo "  11) 双版本 + WARP 代理"
    echo "  12) 双版本 + 多端点 + WARP 代理"
    echo ""
    echo -e "${YELLOW}🛠️ 管理操作${NC}"
    echo "  13) 测试部署"
    echo "  14) 查看服务状态"
    echo "  15) 停止所有服务"
    echo "  0) 退出"
    echo ""
}

# 部署函数
deploy_service() {
    local profiles="$1"
    local description="$2"
    local endpoints="$3"

    echo -e "${BLUE}🚀 $description...${NC}"

    # 确定部署类型
    local deployment_type="both"
    if [[ "$profiles" == *"deno"* ]] && [[ "$profiles" != *"go"* ]]; then
        deployment_type="deno"
    elif [[ "$profiles" == *"go"* ]] && [[ "$profiles" != *"deno"* ]]; then
        deployment_type="go"
    fi

    # 端口配置检查
    configure_ports "$deployment_type"

    # 配置多端点（如果需要）
    if [ "$endpoints" = "multi" ]; then
        configure_multi_endpoints
    elif [ "$endpoints" = "single" ]; then
        configure_single_endpoint
    fi

    # 获取实际端口配置
    local current_ports=($(get_current_ports))
    local actual_deno_port=${current_ports[0]}
    local actual_go_port=${current_ports[1]}

    # 启动服务
    if docker compose $profiles up -d --build; then
        echo -e "${GREEN}✅ $description 启动成功！${NC}"

        # 显示访问信息
        if [[ "$profiles" == *"deno"* ]]; then
            echo -e "${BLUE}🔗 Deno 版本: http://localhost:$actual_deno_port${NC}"
            echo -e "${BLUE}📊 健康检查: curl http://localhost:$actual_deno_port/health${NC}"
        fi
        if [[ "$profiles" == *"go"* ]]; then
            echo -e "${BLUE}🔗 Go 版本: http://localhost:$actual_go_port${NC}"
            echo -e "${BLUE}📊 健康检查: curl http://localhost:$actual_go_port/health${NC}"
        fi
        if [[ "$profiles" == *"warp"* ]]; then
            echo -e "${YELLOW}⏳ WARP 代理需要约 30 秒启动时间${NC}"
        fi

        # 显示端点配置信息
        if [ "$endpoints" = "multi" ]; then
            echo -e "${CYAN}🌐 已启用多端点负载均衡${NC}"
        fi

    else
        echo -e "${RED}❌ $description 启动失败${NC}"
        echo -e "${BLUE}💡 故障排除建议:${NC}"
        echo "  1. 检查端口是否被占用"
        echo "  2. 查看 Docker 日志: docker compose logs"
        echo "  3. 确认 Docker 服务正常运行"
    fi
}

# 配置单端点
configure_single_endpoint() {
    update_env_var "DEEPINFRA_MIRRORS" ""
    echo -e "${GREEN}✅ 配置为单端点模式${NC}"
}

# 配置多端点
configure_multi_endpoints() {
    local mirrors="https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions"
    update_env_var "DEEPINFRA_MIRRORS" "$mirrors"
    echo -e "${GREEN}✅ 配置为多端点负载均衡模式${NC}"
}

# 处理用户选择
handle_choice() {
    local choice=$1

    case $choice in
        1) deploy_service "--profile deno" "Deno 基础版部署" "single" ;;
        2) deploy_service "--profile deno" "Deno + 多端点部署" "multi" ;;
        3) deploy_service "--profile warp --profile deno" "Deno + WARP 代理部署" "single" ;;
        4) deploy_service "--profile warp --profile deno" "Deno + 多端点 + WARP 代理部署" "multi" ;;
        5) deploy_service "--profile go" "Go 基础版部署" "single" ;;
        6) deploy_service "--profile go" "Go + 多端点部署" "multi" ;;
        7) deploy_service "--profile warp --profile go" "Go + WARP 代理部署" "single" ;;
        8) deploy_service "--profile warp --profile go" "Go + 多端点 + WARP 代理部署" "multi" ;;
        9) deploy_service "--profile deno --profile go" "双版本基础部署" "single" ;;
        10) deploy_service "--profile deno --profile go" "双版本 + 多端点部署" "multi" ;;
        11) deploy_service "--profile warp --profile deno --profile go" "双版本 + WARP 代理部署" "single" ;;
        12) deploy_service "--profile warp --profile deno --profile go" "双版本 + 多端点 + WARP 代理部署" "multi" ;;
        13)
            echo -e "${BLUE}🧪 测试部署...${NC}"
            test_deployment
            ;;
        14)
            echo -e "${BLUE}📊 服务状态:${NC}"
            docker compose ps
            echo ""
            echo -e "${BLUE}📋 容器日志查看命令:${NC}"
            echo "  docker compose logs -f deepinfra-proxy-deno"
            echo "  docker compose logs -f deepinfra-proxy-go"
            echo "  docker compose logs -f deepinfra-warp"
            ;;
        15)
            echo -e "${BLUE}🛑 停止所有服务...${NC}"
            if docker compose down; then
                echo -e "${GREEN}✅ 所有服务已停止${NC}"
            else
                echo -e "${RED}❌ 停止服务失败${NC}"
            fi
            ;;
        0)
            echo -e "${GREEN}👋 感谢使用 DeepInfra2API！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ 无效选择，请输入 0-15${NC}"
            ;;
    esac
}

# 主循环
main_loop() {
    while true; do
        show_title
        show_menu

        read -p "请选择 (0-15): " choice
        echo ""

        handle_choice "$choice"

        # 如果不是退出选项，显示提示并等待用户按键
        if [ "$choice" != "0" ]; then
            echo ""
            echo -e "${BLUE}📋 有用的命令:${NC}"
            echo "  查看状态: docker compose ps"
            echo "  查看日志: docker compose logs -f"
            echo "  停止服务: docker compose down"
            echo ""
            echo -e "${YELLOW}按任意键返回主菜单...${NC}"
            read -n 1 -s
        fi
    done
}

# 脚本入口点
main() {
    # 检查 Docker 环境
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker 未安装，请先安装 Docker${NC}"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}❌ Docker Compose 未安装，请先安装 Docker Compose${NC}"
        exit 1
    fi

    # 检查并创建 .env 文件
    if [ ! -f ".env" ]; then
        echo -e "${YELLOW}⚠️  .env 文件不存在，从 .env.example 创建...${NC}"
        if [ -f ".env.example" ]; then
            cp .env.example .env
            echo -e "${GREEN}✅ .env 文件已创建${NC}"
            sleep 2
        else
            echo -e "${RED}❌ .env.example 文件不存在${NC}"
            exit 1
        fi
    fi

    # 启动主循环
    main_loop
}

# 运行主函数
main "$@"
