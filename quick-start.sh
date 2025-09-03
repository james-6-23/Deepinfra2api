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

# 取消注释环境变量函数
uncomment_env_var() {
    local var_name=$1
    local var_value=$2

    # 先尝试取消注释已存在的变量
    if grep -q "^# ${var_name}=" .env; then
        sed -i "s|^# ${var_name}=.*|${var_name}=${var_value}|" .env
    elif grep -q "^#${var_name}=" .env; then
        sed -i "s|^#${var_name}=.*|${var_name}=${var_value}|" .env
    else
        # 如果没找到注释的变量，调用常规更新函数
        update_env_var "$var_name" "$var_value"
    fi
}

# 注释环境变量函数
comment_env_var() {
    local var_name=$1

    # 如果变量存在且未被注释，则注释它
    if grep -q "^${var_name}=" .env; then
        sed -i "s|^${var_name}=|# ${var_name}=|" .env
    fi
}

# 端口扫描和管理函数
check_port_available() {
    local port=$1
    local protocol=${2:-tcp}

    # 使用多种方法检查端口是否可用
    if command -v netstat >/dev/null 2>&1; then
        # 使用 netstat 检查
        if netstat -tuln 2>/dev/null | grep -q ":${port} "; then
            return 1  # 端口被占用
        fi
    elif command -v ss >/dev/null 2>&1; then
        # 使用 ss 检查（更现代的工具）
        if ss -tuln 2>/dev/null | grep -q ":${port} "; then
            return 1  # 端口被占用
        fi
    elif command -v lsof >/dev/null 2>&1; then
        # 使用 lsof 检查
        if lsof -i :${port} >/dev/null 2>&1; then
            return 1  # 端口被占用
        fi
    else
        # 使用 nc 或 telnet 作为最后手段
        if command -v nc >/dev/null 2>&1; then
            if nc -z localhost ${port} 2>/dev/null; then
                return 1  # 端口被占用
            fi
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

    echo -e "${CYAN}🔌 端口配置向导${NC}"
    echo "正在扫描可用端口..."

    # 获取当前端口配置
    local current_ports=($(get_current_ports))
    local current_deno_port=${current_ports[0]}
    local current_go_port=${current_ports[1]}

    # 检查当前端口状态
    local deno_available=false
    local go_available=false

    if check_port_available $current_deno_port; then
        deno_available=true
    fi

    if check_port_available $current_go_port; then
        go_available=true
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
        echo "请选择处理方式："
        echo "1) 自动分配可用端口"
        echo "2) 手动指定端口"
        echo "3) 使用默认端口（可能导致冲突）"
        echo ""

        read -p "请选择 (1-3): " port_choice

        case $port_choice in
            1)
                auto_assign_ports "$deployment_type"
                ;;
            2)
                manual_assign_ports "$deployment_type"
                ;;
            3)
                echo -e "${YELLOW}⚠️  使用默认端口，可能存在冲突风险${NC}"
                ;;
            *)
                echo -e "${YELLOW}⚠️  无效选择，使用自动分配${NC}"
                auto_assign_ports "$deployment_type"
                ;;
        esac
    else
        echo -e "${GREEN}✅ 所有端口都可用，无需重新配置${NC}"
    fi
}

# 自动分配端口
auto_assign_ports() {
    local deployment_type=$1

    echo -e "${BLUE}🔍 自动扫描可用端口...${NC}"

    if [ "$deployment_type" = "deno" ] || [ "$deployment_type" = "both" ]; then
        local new_deno_port=$(find_available_port 8000)
        if [ $? -eq 0 ]; then
            update_env_var "DENO_PORT" "$new_deno_port"
            echo -e "  Deno 端口: ${GREEN}$new_deno_port${NC}"
        else
            echo -e "  ${RED}❌ 无法找到 Deno 可用端口${NC}"
            return 1
        fi
    fi

    if [ "$deployment_type" = "go" ] || [ "$deployment_type" = "both" ]; then
        local new_go_port=$(find_available_port 8001)
        if [ $? -eq 0 ]; then
            update_env_var "GO_PORT" "$new_go_port"
            echo -e "  Go 端口: ${GREEN}$new_go_port${NC}"
        else
            echo -e "  ${RED}❌ 无法找到 Go 可用端口${NC}"
            return 1
        fi
    fi

    echo -e "${GREEN}✅ 端口自动配置完成${NC}"
}

# 手动分配端口
manual_assign_ports() {
    local deployment_type=$1

    echo -e "${BLUE}✏️  手动端口配置${NC}"

    if [ "$deployment_type" = "deno" ] || [ "$deployment_type" = "both" ]; then
        while true; do
            read -p "请输入 Deno 版本端口 (建议 8000-8099): " deno_port

            if [[ "$deno_port" =~ ^[0-9]+$ ]] && [ "$deno_port" -ge 1024 ] && [ "$deno_port" -le 65535 ]; then
                if check_port_available "$deno_port"; then
                    update_env_var "DENO_PORT" "$deno_port"
                    echo -e "  Deno 端口设置为: ${GREEN}$deno_port${NC}"
                    break
                else
                    echo -e "  ${RED}❌ 端口 $deno_port 已被占用，请选择其他端口${NC}"
                fi
            else
                echo -e "  ${RED}❌ 无效端口号，请输入 1024-65535 之间的数字${NC}"
            fi
        done
    fi

    if [ "$deployment_type" = "go" ] || [ "$deployment_type" = "both" ]; then
        while true; do
            read -p "请输入 Go 版本端口 (建议 8001-8099): " go_port

            if [[ "$go_port" =~ ^[0-9]+$ ]] && [ "$go_port" -ge 1024 ] && [ "$go_port" -le 65535 ]; then
                if check_port_available "$go_port"; then
                    update_env_var "GO_PORT" "$go_port"
                    echo -e "  Go 端口设置为: ${GREEN}$go_port${NC}"
                    break
                else
                    echo -e "  ${RED}❌ 端口 $go_port 已被占用，请选择其他端口${NC}"
                fi
            else
                echo -e "  ${RED}❌ 无效端口号，请输入 1024-65535 之间的数字${NC}"
            fi
        done
    fi

    echo -e "${GREEN}✅ 端口手动配置完成${NC}"
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
    echo -e "${YELLOW}� Go 高并发版本 (端口 8001) - 企业级高性能${NC}"
    echo "  9) Go 高并发基础版 (1000并发)"
    echo "  10) Go 高并发 + 多端点 (2000并发)"
    echo "  11) Go 高并发 + WARP (1000并发)"
    echo "  12) Go 高并发完整版 (3000并发)"
    echo ""
    echo -e "${YELLOW}�🔄 双版本部署${NC}"
    echo "  13) 双版本基础部署"
    echo "  14) 双版本 + 多端点负载均衡"
    echo "  15) 双版本 + WARP 代理"
    echo "  16) 双版本 + 多端点 + WARP 代理"
    echo ""
    echo -e "${YELLOW}🛠️ 管理操作${NC}"
    echo "  17) 测试部署"
    echo "  18) 查看服务状态"
    echo "  19) 停止所有服务"
    echo "  0) 退出"
    echo ""
}

# 部署函数
deploy_service() {
    local profiles="$1"
    local description="$2"
    local endpoints="$3"
    local concurrency_config="$4"  # 新增高并发配置参数

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

    # 配置高并发（如果需要）
    case "$concurrency_config" in
        "high_concurrency_basic")
            configure_high_concurrency_basic
            ;;
        "high_concurrency_medium")
            configure_high_concurrency_medium
            ;;
        "high_concurrency_full")
            configure_high_concurrency_full
            ;;
    esac

    # 获取实际端口配置
    local current_ports=($(get_current_ports))
    local actual_deno_port=${current_ports[0]}
    local actual_go_port=${current_ports[1]}

    # 智能 WARP 部署策略
    if [[ "$profiles" == *"warp"* ]]; then
        echo -e "${CYAN}🔧 WARP 部署模式：分阶段启动${NC}"

        # 阶段1：确保代理配置被禁用，先构建应用镜像
        echo -e "${BLUE}阶段1: 禁用代理配置并构建应用镜像${NC}"
        configure_warp_proxy "false"

        # 提取非 warp 的 profiles 用于构建
        local app_profiles=""
        if [[ "$profiles" == *"deno"* ]]; then
            app_profiles="$app_profiles --profile deno"
        fi
        if [[ "$profiles" == *"go"* ]]; then
            app_profiles="$app_profiles --profile go"
        fi

        # 先构建应用镜像（不启动）
        echo -e "${CYAN}🔨 构建应用镜像...${NC}"
        if docker compose $app_profiles build; then
            echo -e "${GREEN}✅ 应用镜像构建成功${NC}"
        else
            echo -e "${RED}❌ 应用镜像构建失败${NC}"
            return 1
        fi

        # 阶段2：启动 WARP 代理服务
        echo -e "${BLUE}阶段2: 启动 WARP 代理服务${NC}"
        if docker compose --profile warp up -d; then
            echo -e "${GREEN}✅ WARP 代理服务启动成功${NC}"
            echo -e "${YELLOW}⏳ 等待 WARP 代理完全初始化 (45秒)...${NC}"
            sleep 45
        else
            echo -e "${RED}❌ WARP 代理服务启动失败${NC}"
            return 1
        fi

        # 阶段3：验证 WARP 代理可用性
        echo -e "${BLUE}阶段3: 验证 WARP 代理连接${NC}"
        local warp_ready=false
        for i in {1..10}; do
            if docker exec deepinfra-warp curl -s --connect-timeout 5 http://www.google.com > /dev/null 2>&1; then
                echo -e "${GREEN}✅ WARP 代理连接验证成功${NC}"
                warp_ready=true
                break
            else
                echo -e "${YELLOW}⏳ WARP 代理连接验证中... ($i/10)${NC}"
                sleep 5
            fi
        done

        if [ "$warp_ready" = false ]; then
            echo -e "${YELLOW}⚠️ WARP 代理连接验证超时，但继续部署${NC}"
        fi

        # 阶段4：配置代理环境变量并启动应用
        echo -e "${BLUE}阶段4: 配置代理并启动应用服务${NC}"
        configure_warp_proxy "true"

        # 启动应用服务（使用已构建的镜像）
        if docker compose $app_profiles up -d; then
            echo -e "${GREEN}✅ 应用服务启动成功${NC}"
        else
            echo -e "${RED}❌ 应用服务启动失败${NC}"
            echo -e "${BLUE}💡 尝试回退方案...${NC}"
            # 回退：禁用代理重新启动
            configure_warp_proxy "false"
            if docker compose $app_profiles up -d; then
                echo -e "${YELLOW}⚠️ 应用服务已启动，但未使用 WARP 代理${NC}"
            else
                return 1
            fi
        fi

    else
        # 非 WARP 部署，直接启动
        configure_warp_proxy "false"
        if docker compose $profiles up -d --build; then
            echo -e "${GREEN}✅ 服务启动成功${NC}"
        else
            echo -e "${RED}❌ 服务启动失败${NC}"
            return 1
        fi
    fi

    # 服务启动成功后的处理
    if true; then
        echo -e "${GREEN}✅ $description 启动成功！${NC}"

        # 显示访问信息
        if [[ "$profiles" == *"deno"* ]]; then
            echo -e "${BLUE}🔗 Deno 版本: http://localhost:$actual_deno_port${NC}"
            echo -e "${BLUE}📊 健康检查: curl http://localhost:$actual_deno_port/health${NC}"
        fi
        if [[ "$profiles" == *"go"* ]]; then
            echo -e "${BLUE}🔗 Go 版本: http://localhost:$actual_go_port${NC}"
            echo -e "${BLUE}📊 健康检查: curl http://localhost:$actual_go_port/health${NC}"

            # 高并发版本特殊提示
            if [[ -n "$concurrency_config" ]]; then
                echo -e "${BLUE}📈 系统状态监控: curl http://localhost:$actual_go_port/status${NC}"
                case "$concurrency_config" in
                    "high_concurrency_basic")
                        echo -e "${CYAN}🚀 高并发基础版已启用 (1000并发)${NC}"
                        ;;
                    "high_concurrency_medium")
                        echo -e "${CYAN}🚀 高并发中等版已启用 (2000并发)${NC}"
                        ;;
                    "high_concurrency_full")
                        echo -e "${CYAN}🚀 高并发完整版已启用 (3000并发)${NC}"
                        ;;
                esac
                echo -e "${YELLOW}💡 建议监控系统资源使用情况${NC}"
            fi
        fi
        if [[ "$profiles" == *"warp"* ]]; then
            echo -e "${YELLOW}⏳ WARP 代理需要约 30 秒启动时间${NC}"
            echo -e "${CYAN}🌐 WARP 代理已启用，环境变量已配置${NC}"
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

# 配置高并发基础版 (1000并发)
configure_high_concurrency_basic() {
    echo -e "${CYAN}🚀 配置高并发基础版 (1000并发)...${NC}"

    # 基础超时配置
    update_env_var "REQUEST_TIMEOUT" "120000"
    update_env_var "STREAM_TIMEOUT" "300000"

    # 高并发配置
    update_env_var "MAX_CONCURRENT_CONNECTIONS" "1000"
    update_env_var "STREAM_BUFFER_SIZE" "16384"
    update_env_var "MEMORY_LIMIT_MB" "2048"
    update_env_var "DISABLE_CONNECTION_CHECK" "false"
    update_env_var "CONNECTION_CHECK_INTERVAL" "20"
    update_env_var "ENABLE_METRICS" "true"

    echo -e "${GREEN}✅ 高并发基础版配置完成 (1000并发)${NC}"
}

# 配置高并发中等版 (2000并发)
configure_high_concurrency_medium() {
    echo -e "${CYAN}🚀 配置高并发中等版 (2000并发)...${NC}"

    # 优化超时配置
    update_env_var "REQUEST_TIMEOUT" "90000"
    update_env_var "STREAM_TIMEOUT" "240000"

    # 高并发配置
    update_env_var "MAX_CONCURRENT_CONNECTIONS" "2000"
    update_env_var "STREAM_BUFFER_SIZE" "32768"
    update_env_var "MEMORY_LIMIT_MB" "4096"
    update_env_var "DISABLE_CONNECTION_CHECK" "false"
    update_env_var "CONNECTION_CHECK_INTERVAL" "30"
    update_env_var "ENABLE_METRICS" "true"

    echo -e "${GREEN}✅ 高并发中等版配置完成 (2000并发)${NC}"
}

# 配置高并发完整版 (3000并发)
configure_high_concurrency_full() {
    echo -e "${CYAN}🚀 配置高并发完整版 (3000并发)...${NC}"

    # 高性能超时配置
    update_env_var "REQUEST_TIMEOUT" "60000"
    update_env_var "STREAM_TIMEOUT" "180000"

    # 高并发配置
    update_env_var "MAX_CONCURRENT_CONNECTIONS" "3000"
    update_env_var "STREAM_BUFFER_SIZE" "65536"
    update_env_var "MEMORY_LIMIT_MB" "6144"
    update_env_var "DISABLE_CONNECTION_CHECK" "true"
    update_env_var "CONNECTION_CHECK_INTERVAL" "50"
    update_env_var "ENABLE_METRICS" "true"

    echo -e "${GREEN}✅ 高并发完整版配置完成 (3000并发)${NC}"
}

# 配置 WARP 代理
configure_warp_proxy() {
    local enable_warp=$1  # true 或 false

    if [ "$enable_warp" = "true" ]; then
        echo -e "${CYAN}🔧 正在启用 WARP 代理配置...${NC}"
        
        # 启用 WARP 服务
        update_env_var "WARP_ENABLED" "true"
        
        # 取消注释并配置代理环境变量
        uncomment_env_var "HTTP_PROXY" "http://deepinfra-warp:1080"
        uncomment_env_var "HTTPS_PROXY" "http://deepinfra-warp:1080"
        
        echo -e "${GREEN}✅ WARP 代理已启用${NC}"
        echo -e "${YELLOW}⚠️  WARP 代理需要约 30 秒启动时间${NC}"
    else
        echo -e "${CYAN}🔧 正在禁用 WARP 代理配置...${NC}"
        
        # 禁用 WARP 服务
        update_env_var "WARP_ENABLED" "false"
        
        # 注释代理环境变量
        comment_env_var "HTTP_PROXY"
        comment_env_var "HTTPS_PROXY"
        
        echo -e "${GREEN}✅ WARP 代理已禁用${NC}"
    fi
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
        9) deploy_service "--profile go" "Go 高并发基础版部署 (1000并发)" "single" "high_concurrency_basic" ;;
        10) deploy_service "--profile go" "Go 高并发 + 多端点部署 (2000并发)" "multi" "high_concurrency_medium" ;;
        11) deploy_service "--profile warp --profile go" "Go 高并发 + WARP 代理部署 (1000并发)" "single" "high_concurrency_basic" ;;
        12) deploy_service "--profile warp --profile go" "Go 高并发完整版部署 (3000并发)" "multi" "high_concurrency_full" ;;
        13) deploy_service "--profile deno --profile go" "双版本基础部署" "single" ;;
        14) deploy_service "--profile deno --profile go" "双版本 + 多端点部署" "multi" ;;
        15) deploy_service "--profile warp --profile deno --profile go" "双版本 + WARP 代理部署" "single" ;;
        16) deploy_service "--profile warp --profile deno --profile go" "双版本 + 多端点 + WARP 代理部署" "multi" ;;
        17)
            echo -e "${BLUE}🧪 测试部署...${NC}"
            test_deployment
            ;;
        18)
            echo -e "${BLUE}📊 服务状态:${NC}"
            docker compose ps
            echo ""
            echo -e "${BLUE}📋 容器日志查看命令:${NC}"
            echo "  docker compose logs -f deepinfra-proxy-deno"
            echo "  docker compose logs -f deepinfra-proxy-go"
            echo "  docker compose logs -f deepinfra-warp"
            ;;
        19)
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
