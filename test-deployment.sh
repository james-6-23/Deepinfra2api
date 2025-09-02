#!/bin/bash

# DeepInfra2API 部署测试脚本

echo "🧪 DeepInfra2API 部署测试脚本"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查 Docker 和 Docker Compose
echo -e "${BLUE}📋 检查环境...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose 未安装${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker 环境正常${NC}"

# 检查配置文件
echo -e "${BLUE}📋 检查配置文件...${NC}"
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

# 读取配置
source .env
DENO_PORT=${DENO_PORT:-8000}
GO_PORT=${GO_PORT:-8001}
API_KEY=${VALID_API_KEYS%%,*}  # 取第一个 API Key

echo -e "${GREEN}✅ 配置文件正常${NC}"
echo "   Deno 端口: $DENO_PORT"
echo "   Go 端口: $GO_PORT"
echo "   API Key: ${API_KEY:0:10}..."

# 选择测试模式
echo -e "${BLUE}🎯 选择测试模式:${NC}"
echo "1) 测试 Deno 版本"
echo "2) 测试 Go 版本"
echo "3) 测试两个版本"
echo "4) 测试 WARP + Deno"
echo "5) 测试 WARP + Go"
echo "6) 测试 WARP + 两个版本"

read -p "请选择 (1-6): " choice

case $choice in
    1)
        PROFILES="deno"
        TEST_PORTS="$DENO_PORT"
        ;;
    2)
        PROFILES="go"
        TEST_PORTS="$GO_PORT"
        ;;
    3)
        PROFILES="deno go"
        TEST_PORTS="$DENO_PORT $GO_PORT"
        ;;
    4)
        PROFILES="warp deno"
        TEST_PORTS="$DENO_PORT"
        ;;
    5)
        PROFILES="warp go"
        TEST_PORTS="$GO_PORT"
        ;;
    6)
        PROFILES="warp deno go"
        TEST_PORTS="$DENO_PORT $GO_PORT"
        ;;
    *)
        echo -e "${RED}❌ 无效选择${NC}"
        exit 1
        ;;
esac

# 构建和启动服务
echo -e "${BLUE}🚀 启动服务...${NC}"
PROFILE_ARGS=""
for profile in $PROFILES; do
    PROFILE_ARGS="$PROFILE_ARGS --profile $profile"
done

echo "执行命令: docker compose $PROFILE_ARGS up -d --build"
if docker compose $PROFILE_ARGS up -d --build; then
    echo -e "${GREEN}✅ 服务启动成功${NC}"
else
    echo -e "${RED}❌ 服务启动失败${NC}"
    exit 1
fi

# 等待服务启动
echo -e "${BLUE}⏳ 等待服务启动...${NC}"
sleep 10

# 测试服务
echo -e "${BLUE}🧪 开始测试...${NC}"
failed_tests=0

for port in $TEST_PORTS; do
    version_name=""
    if [ "$port" = "$DENO_PORT" ]; then
        version_name="Deno"
    elif [ "$port" = "$GO_PORT" ]; then
        version_name="Go"
    fi
    
    echo -e "${YELLOW}测试 $version_name 版本 (端口 $port):${NC}"
    
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
    
    echo -e "${BLUE}📋 服务信息:${NC}"
    docker compose ps
    
    echo -e "${BLUE}🔗 访问地址:${NC}"
    for port in $TEST_PORTS; do
        version_name=""
        if [ "$port" = "$DENO_PORT" ]; then
            version_name="Deno"
        elif [ "$port" = "$GO_PORT" ]; then
            version_name="Go"
        fi
        echo "  $version_name 版本: http://localhost:$port"
    done
    
    exit 0
else
    echo -e "${RED}❌ 有测试失败，请检查日志${NC}"
    
    echo -e "${BLUE}📋 容器状态:${NC}"
    docker compose ps
    
    echo -e "${BLUE}📋 查看日志命令:${NC}"
    for profile in $PROFILES; do
        if [ "$profile" = "deno" ]; then
            echo "  docker compose logs deepinfra-proxy-deno"
        elif [ "$profile" = "go" ]; then
            echo "  docker compose logs deepinfra-proxy-go"
        elif [ "$profile" = "warp" ]; then
            echo "  docker compose logs deepinfra-warp"
        fi
    done
    
    exit 1
fi
