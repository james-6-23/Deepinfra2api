#!/bin/bash

# DeepInfra2API 快速启动脚本

echo "🚀 DeepInfra2API 快速启动脚本"
echo "============================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
echo -e "${BLUE}🎯 请选择部署方案:${NC}"
echo "1) Deno 版本 (端口 8000) - 推荐用于开发"
echo "2) Go 版本 (端口 8001) - 推荐用于生产"
echo "3) 两个版本同时部署"
echo "4) Deno + WARP 代理"
echo "5) Go + WARP 代理"
echo "6) 两个版本 + WARP 代理"
echo "7) 仅 WARP 代理"
echo "8) 停止所有服务"
echo "9) 查看服务状态"

read -p "请选择 (1-9): " choice

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
        echo -e "${BLUE}🛑 停止所有服务...${NC}"
        docker compose down
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ 所有服务已停止${NC}"
        fi
        ;;
    9)
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
