#!/bin/bash

# WARP 部署问题修复脚本
# 解决 WARP 代理部署时的 Docker 构建问题

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 WARP 部署问题修复工具${NC}"
echo "=================================="

# 检查当前状态
echo -e "${CYAN}📊 检查当前服务状态...${NC}"
docker compose ps

echo ""
echo -e "${CYAN}🛑 停止所有服务...${NC}"
docker compose down

echo ""
echo -e "${CYAN}🔧 清理代理配置...${NC}"

# 临时禁用代理配置
if [ -f .env ]; then
    # 备份当前配置
    cp .env .env.backup
    
    # 注释掉代理配置
    sed -i 's/^HTTP_PROXY=/#HTTP_PROXY=/' .env
    sed -i 's/^HTTPS_PROXY=/#HTTPS_PROXY=/' .env
    
    echo -e "${GREEN}✅ 代理配置已临时禁用${NC}"
else
    echo -e "${YELLOW}⚠️ 未找到 .env 文件${NC}"
fi

echo ""
echo -e "${CYAN}🚀 重新部署 Go + 多端点 + WARP 代理...${NC}"

# 分步部署策略
echo -e "${BLUE}步骤 1: 启动 WARP 代理服务${NC}"
if docker compose --profile warp up -d --build; then
    echo -e "${GREEN}✅ WARP 代理服务启动成功${NC}"
    
    echo -e "${YELLOW}⏳ 等待 WARP 代理初始化 (30秒)...${NC}"
    sleep 30
    
    echo -e "${BLUE}步骤 2: 配置代理环境变量${NC}"
    if [ -f .env ]; then
        # 启用代理配置
        sed -i 's/^#HTTP_PROXY=/HTTP_PROXY=/' .env
        sed -i 's/^#HTTPS_PROXY=/HTTPS_PROXY=/' .env
        
        # 确保代理配置存在
        if ! grep -q "HTTP_PROXY=" .env; then
            echo "HTTP_PROXY=http://deepinfra-warp:1080" >> .env
        fi
        if ! grep -q "HTTPS_PROXY=" .env; then
            echo "HTTPS_PROXY=http://deepinfra-warp:1080" >> .env
        fi
        
        echo -e "${GREEN}✅ 代理环境变量已配置${NC}"
    fi
    
    echo -e "${BLUE}步骤 3: 启动 Go 应用服务${NC}"
    if docker compose --profile go up -d --build; then
        echo -e "${GREEN}✅ Go 应用服务启动成功${NC}"
        
        echo ""
        echo -e "${GREEN}🎉 WARP 部署修复完成！${NC}"
        echo ""
        echo -e "${BLUE}📋 服务信息:${NC}"
        echo -e "  🔗 Go 版本: http://localhost:8001"
        echo -e "  📊 健康检查: curl http://localhost:8001/health"
        echo -e "  🌐 已启用多端点负载均衡"
        echo -e "  🔒 已启用 WARP 代理"
        
        echo ""
        echo -e "${BLUE}📊 当前服务状态:${NC}"
        docker compose ps
        
    else
        echo -e "${RED}❌ Go 应用服务启动失败${NC}"
        echo -e "${BLUE}💡 故障排除:${NC}"
        echo "  1. 查看日志: docker compose logs deepinfra-proxy-go"
        echo "  2. 检查端口占用: netstat -an | grep 8001"
        exit 1
    fi
    
else
    echo -e "${RED}❌ WARP 代理服务启动失败${NC}"
    echo -e "${BLUE}💡 故障排除:${NC}"
    echo "  1. 查看日志: docker compose logs deepinfra-warp"
    echo "  2. 检查 Docker 服务状态"
    exit 1
fi

echo ""
echo -e "${CYAN}📋 有用的命令:${NC}"
echo "  查看所有服务状态: docker compose ps"
echo "  查看 WARP 日志: docker compose logs -f deepinfra-warp"
echo "  查看 Go 服务日志: docker compose logs -f deepinfra-proxy-go"
echo "  停止所有服务: docker compose down"

echo ""
echo -e "${GREEN}✨ 修复完成！现在可以正常使用 WARP 代理功能了。${NC}"
