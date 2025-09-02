#!/bin/bash

# DeepInfra2API Go 版本独立部署脚本
# 适用于 Linux 服务器自主部署

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 显示标题
echo -e "${CYAN}🐹 DeepInfra2API Go 版本部署脚本${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

# 检查 Docker 环境
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker 未安装，请先安装 Docker${NC}"
        echo "安装命令："
        echo "  Ubuntu/Debian: sudo apt-get update && sudo apt-get install docker.io"
        echo "  CentOS/RHEL: sudo yum install docker"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}❌ Docker Compose 未安装，请先安装 Docker Compose${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Docker 环境检查通过${NC}"
}

# 检查并创建环境文件
setup_env() {
    if [ ! -f "../.env" ]; then
        echo -e "${YELLOW}⚠️  .env 文件不存在，创建默认配置...${NC}"
        cat > ../.env << EOF
# API 密钥配置
VALID_API_KEYS=linux.do

# 端口配置
GO_PORT=8001

# 日志配置
ENABLE_DETAILED_LOGGING=true
LOG_USER_MESSAGES=false
LOG_RESPONSE_CONTENT=false

# 性能配置
PERFORMANCE_MODE=balanced
MAX_RETRIES=3
RETRY_DELAY=1000
REQUEST_TIMEOUT=30000
RANDOM_DELAY=100-500ms

# 多端点配置（可选）
# DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions
EOF
        echo -e "${GREEN}✅ 已创建默认 .env 文件${NC}"
    else
        echo -e "${GREEN}✅ .env 文件已存在${NC}"
    fi
}

# 端口检查
check_port() {
    local port=${1:-8001}
    
    if netstat -tuln 2>/dev/null | grep -q ":${port} " || ss -tuln 2>/dev/null | grep -q ":${port} "; then
        echo -e "${YELLOW}⚠️  端口 $port 已被占用${NC}"
        read -p "是否继续部署？(y/N): " continue_deploy
        if [[ ! "$continue_deploy" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}💡 请修改 .env 文件中的 GO_PORT 配置${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ 端口 $port 可用${NC}"
    fi
}

# 部署服务
deploy() {
    echo -e "${BLUE}🚀 开始部署 Go 版本...${NC}"
    
    # 加载环境变量
    if [ -f "../.env" ]; then
        source ../.env
    fi
    
    # 检查端口
    check_port ${GO_PORT:-8001}
    
    # 构建和启动服务
    if docker compose up -d --build; then
        echo -e "${GREEN}✅ Go 版本部署成功！${NC}"
        echo ""
        echo -e "${BLUE}📋 服务信息:${NC}"
        echo -e "  🔗 访问地址: http://localhost:${GO_PORT:-8001}"
        echo -e "  📊 健康检查: curl http://localhost:${GO_PORT:-8001}/health"
        echo -e "  📝 查看日志: docker compose logs -f"
        echo -e "  🛑 停止服务: docker compose down"
        echo ""
        
        # 测试服务
        echo -e "${BLUE}🧪 测试服务连通性...${NC}"
        sleep 5
        if curl -f http://localhost:${GO_PORT:-8001}/health >/dev/null 2>&1; then
            echo -e "${GREEN}✅ 服务运行正常${NC}"
        else
            echo -e "${YELLOW}⚠️  服务可能还在启动中，请稍后测试${NC}"
        fi
    else
        echo -e "${RED}❌ 部署失败${NC}"
        echo -e "${BLUE}💡 故障排除:${NC}"
        echo "  1. 检查 Docker 服务状态: sudo systemctl status docker"
        echo "  2. 查看详细日志: docker compose logs"
        echo "  3. 检查端口占用: netstat -tuln | grep ${GO_PORT:-8001}"
        exit 1
    fi
}

# 主函数
main() {
    check_docker
    setup_env
    deploy
}

# 运行主函数
main "$@"
