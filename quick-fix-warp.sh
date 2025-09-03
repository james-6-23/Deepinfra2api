#!/bin/bash

# WARP 部署快速修复脚本
# 解决 Docker 构建时的代理配置问题

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🔧 WARP 部署快速修复工具${NC}"
echo "=================================="

# 停止所有服务
echo -e "${CYAN}🛑 停止现有服务...${NC}"
docker compose down

# 确保 .env 文件存在
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}✅ 已创建 .env 文件${NC}"
    else
        echo -e "${RED}❌ 未找到 .env.example 文件${NC}"
        exit 1
    fi
fi

# 临时禁用代理配置
echo -e "${CYAN}🔧 临时禁用代理配置...${NC}"
sed -i 's/^HTTP_PROXY=/#HTTP_PROXY=/' .env
sed -i 's/^HTTPS_PROXY=/#HTTPS_PROXY=/' .env

# 询问用户要部署的版本
echo -e "${BLUE}请选择要部署的版本:${NC}"
echo "1) Deno + WARP 代理"
echo "2) Go + WARP 代理"
echo "3) Go + 多端点 + WARP 代理"
echo "4) Go 高并发 + WARP (1000并发)"
read -p "请选择 (1-4): " choice

case $choice in
    1)
        SERVICE_TYPE="deno"
        PROFILES="--profile warp --profile deno"
        DESCRIPTION="Deno + WARP 代理"
        ;;
    2)
        SERVICE_TYPE="go"
        PROFILES="--profile warp --profile go"
        DESCRIPTION="Go + WARP 代理"
        # 配置单端点
        sed -i 's/^DEEPINFRA_MIRRORS=/#DEEPINFRA_MIRRORS=/' .env
        ;;
    3)
        SERVICE_TYPE="go"
        PROFILES="--profile warp --profile go"
        DESCRIPTION="Go + 多端点 + WARP 代理"
        # 配置多端点
        if grep -q "^DEEPINFRA_MIRRORS=" .env; then
            sed -i 's|^DEEPINFRA_MIRRORS=.*|DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions|' .env
        else
            echo "DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions" >> .env
        fi
        ;;
    4)
        SERVICE_TYPE="go"
        PROFILES="--profile warp --profile go"
        DESCRIPTION="Go 高并发 + WARP (1000并发)"
        # 配置高并发
        sed -i 's/^REQUEST_TIMEOUT=.*/REQUEST_TIMEOUT=120000/' .env
        sed -i 's/^STREAM_TIMEOUT=.*/STREAM_TIMEOUT=300000/' .env
        if ! grep -q "MAX_CONCURRENT_CONNECTIONS=" .env; then
            echo "MAX_CONCURRENT_CONNECTIONS=1000" >> .env
            echo "STREAM_BUFFER_SIZE=16384" >> .env
            echo "MEMORY_LIMIT_MB=2048" >> .env
            echo "ENABLE_METRICS=true" >> .env
        fi
        ;;
    *)
        echo -e "${RED}❌ 无效选择${NC}"
        exit 1
        ;;
esac

echo -e "${BLUE}🚀 开始部署: $DESCRIPTION${NC}"

# 步骤1: 构建应用镜像（无代理）
echo -e "${CYAN}步骤1: 构建应用镜像...${NC}"
if [ "$SERVICE_TYPE" = "deno" ]; then
    docker compose --profile deno build
else
    docker compose --profile go build
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 应用镜像构建失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 应用镜像构建成功${NC}"

# 步骤2: 启动 WARP 代理
echo -e "${CYAN}步骤2: 启动 WARP 代理服务...${NC}"
docker compose --profile warp up -d

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ WARP 代理启动失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ WARP 代理启动成功${NC}"
echo -e "${YELLOW}⏳ 等待 WARP 代理初始化 (30秒)...${NC}"
sleep 30

# 步骤3: 启用代理配置
echo -e "${CYAN}步骤3: 启用代理配置...${NC}"
if ! grep -q "HTTP_PROXY=" .env; then
    echo "HTTP_PROXY=http://deepinfra-warp:1080" >> .env
else
    sed -i 's/^#HTTP_PROXY=/HTTP_PROXY=/' .env
fi

if ! grep -q "HTTPS_PROXY=" .env; then
    echo "HTTPS_PROXY=http://deepinfra-warp:1080" >> .env
else
    sed -i 's/^#HTTPS_PROXY=/HTTPS_PROXY=/' .env
fi

# 步骤4: 启动应用服务
echo -e "${CYAN}步骤4: 启动应用服务...${NC}"
if [ "$SERVICE_TYPE" = "deno" ]; then
    docker compose --profile deno up -d
else
    docker compose --profile go up -d
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}🎉 部署成功！${NC}"
    echo ""
    echo -e "${BLUE}📋 服务信息:${NC}"
    if [ "$SERVICE_TYPE" = "deno" ]; then
        echo -e "  🔗 Deno 版本: http://localhost:8000"
        echo -e "  📊 健康检查: curl http://localhost:8000/health"
    else
        echo -e "  🔗 Go 版本: http://localhost:8001"
        echo -e "  📊 健康检查: curl http://localhost:8001/health"
        if [ "$choice" = "4" ]; then
            echo -e "  📈 系统状态: curl http://localhost:8001/status"
        fi
    fi
    echo -e "  🔒 WARP 代理已启用"
    
    echo ""
    echo -e "${BLUE}📊 当前服务状态:${NC}"
    docker compose ps
    
else
    echo -e "${RED}❌ 应用服务启动失败${NC}"
    echo -e "${BLUE}💡 尝试回退方案...${NC}"
    
    # 禁用代理重试
    sed -i 's/^HTTP_PROXY=/#HTTP_PROXY=/' .env
    sed -i 's/^HTTPS_PROXY=/#HTTPS_PROXY=/' .env
    
    if [ "$SERVICE_TYPE" = "deno" ]; then
        docker compose --profile deno up -d
    else
        docker compose --profile go up -d
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${YELLOW}⚠️ 应用服务已启动，但未使用 WARP 代理${NC}"
    else
        echo -e "${RED}❌ 回退方案也失败了${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${CYAN}📋 有用的命令:${NC}"
echo "  查看服务状态: docker compose ps"
echo "  查看 WARP 日志: docker compose logs -f deepinfra-warp"
echo "  查看应用日志: docker compose logs -f deepinfra-proxy-$SERVICE_TYPE"
echo "  停止所有服务: docker compose down"

echo ""
echo -e "${GREEN}✨ 修复完成！${NC}"
