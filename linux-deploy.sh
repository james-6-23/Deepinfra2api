#!/bin/bash

# DeepInfra2API Linux 服务器一键部署脚本
# 支持 Ubuntu、Debian、CentOS、RHEL 等主流 Linux 发行版

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 显示标题
show_title() {
    clear
    echo -e "${CYAN}🐧 DeepInfra2API Linux 服务器一键部署${NC}"
    echo -e "${CYAN}===========================================${NC}"
    echo ""
}

# 检测 Linux 发行版
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/redhat-release ]; then
        OS="CentOS"
        VER=$(cat /etc/redhat-release | sed 's/.*release //' | sed 's/ .*//')
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    echo -e "${BLUE}📋 检测到系统: $OS $VER${NC}"
}

# 安装 Docker
install_docker() {
    echo -e "${BLUE}🐳 安装 Docker...${NC}"
    
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Docker 已安装${NC}"
        return 0
    fi
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*)
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        *)
            echo -e "${RED}❌ 不支持的操作系统: $OS${NC}"
            echo "请手动安装 Docker: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
    
    # 启动 Docker 服务
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 添加当前用户到 docker 组
    sudo usermod -aG docker $USER
    
    echo -e "${GREEN}✅ Docker 安装完成${NC}"
    echo -e "${YELLOW}⚠️  请重新登录以使 Docker 组权限生效${NC}"
}

# 安装 Docker Compose (如果需要)
install_docker_compose() {
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}✅ Docker Compose 已安装${NC}"
        return 0
    fi
    
    if command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}✅ Docker Compose (standalone) 已安装${NC}"
        return 0
    fi
    
    echo -e "${BLUE}📦 安装 Docker Compose...${NC}"
    
    # 下载最新版本的 Docker Compose
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    echo -e "${GREEN}✅ Docker Compose 安装完成${NC}"
}

# 创建项目目录和配置
setup_project() {
    echo -e "${BLUE}📁 设置项目目录...${NC}"
    
    # 创建项目目录
    PROJECT_DIR="/opt/deepinfra2api"
    sudo mkdir -p $PROJECT_DIR
    sudo chown $USER:$USER $PROJECT_DIR
    
    # 创建 .env 文件
    cat > $PROJECT_DIR/.env << EOF
# API 密钥配置
VALID_API_KEYS=linux.do

# 端口配置
DENO_PORT=8000
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
    
    echo -e "${GREEN}✅ 项目目录设置完成: $PROJECT_DIR${NC}"
}

# 显示部署选项
show_deploy_options() {
    echo -e "${BLUE}🎯 请选择部署方案:${NC}"
    echo ""
    echo "1) Deno 版本 (端口 8000) - 推荐用于开发"
    echo "2) Go 版本 (端口 8001) - 推荐用于生产"
    echo "3) 双版本部署 (端口 8000 + 8001)"
    echo "4) 自定义配置"
    echo "0) 退出"
    echo ""
}

# 部署 Deno 版本
deploy_deno() {
    echo -e "${BLUE}🦕 部署 Deno 版本...${NC}"
    
    cd $PROJECT_DIR
    
    # 下载 Deno 版本文件
    curl -L https://raw.githubusercontent.com/your-repo/DeepInfra2API/main/deno-version/Dockerfile -o deno-Dockerfile
    curl -L https://raw.githubusercontent.com/your-repo/DeepInfra2API/main/deno-version/app.ts -o deno-app.ts
    curl -L https://raw.githubusercontent.com/your-repo/DeepInfra2API/main/deno-version/deno.json -o deno.json
    
    # 创建 Docker Compose 文件
    cat > docker-compose-deno.yml << EOF
version: '3.8'

services:
  deepinfra-proxy-deno:
    build:
      context: .
      dockerfile: deno-Dockerfile
    container_name: deepinfra-proxy-deno
    ports:
      - "\${DENO_PORT:-8000}:8000"
    environment:
      - VALID_API_KEYS=\${VALID_API_KEYS}
      - DEEPINFRA_MIRRORS=\${DEEPINFRA_MIRRORS}
      - ENABLE_DETAILED_LOGGING=\${ENABLE_DETAILED_LOGGING:-true}
      - LOG_USER_MESSAGES=\${LOG_USER_MESSAGES:-false}
      - LOG_RESPONSE_CONTENT=\${LOG_RESPONSE_CONTENT:-false}
      - PERFORMANCE_MODE=\${PERFORMANCE_MODE:-balanced}
      - MAX_RETRIES=\${MAX_RETRIES:-3}
      - RETRY_DELAY=\${RETRY_DELAY:-1000}
      - REQUEST_TIMEOUT=\${REQUEST_TIMEOUT:-30000}
      - RANDOM_DELAY=\${RANDOM_DELAY:-100-500ms}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF
    
    # 启动服务
    docker compose -f docker-compose-deno.yml up -d --build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Deno 版本部署成功！${NC}"
        echo -e "${BLUE}🔗 访问地址: http://$(curl -s ifconfig.me):8000${NC}"
    else
        echo -e "${RED}❌ Deno 版本部署失败${NC}"
    fi
}

# 部署 Go 版本
deploy_go() {
    echo -e "${BLUE}🐹 部署 Go 版本...${NC}"
    
    cd $PROJECT_DIR
    
    # 下载 Go 版本文件
    curl -L https://raw.githubusercontent.com/your-repo/DeepInfra2API/main/go-version/Dockerfile -o go-Dockerfile
    curl -L https://raw.githubusercontent.com/your-repo/DeepInfra2API/main/go-version/main.go -o go-main.go
    curl -L https://raw.githubusercontent.com/your-repo/DeepInfra2API/main/go-version/go.mod -o go.mod
    
    # 创建 Docker Compose 文件
    cat > docker-compose-go.yml << EOF
version: '3.8'

services:
  deepinfra-proxy-go:
    build:
      context: .
      dockerfile: go-Dockerfile
    container_name: deepinfra-proxy-go
    ports:
      - "\${GO_PORT:-8001}:8000"
    environment:
      - VALID_API_KEYS=\${VALID_API_KEYS}
      - DEEPINFRA_MIRRORS=\${DEEPINFRA_MIRRORS}
      - ENABLE_DETAILED_LOGGING=\${ENABLE_DETAILED_LOGGING:-true}
      - LOG_USER_MESSAGES=\${LOG_USER_MESSAGES:-false}
      - LOG_RESPONSE_CONTENT=\${LOG_RESPONSE_CONTENT:-false}
      - PERFORMANCE_MODE=\${PERFORMANCE_MODE:-balanced}
      - MAX_RETRIES=\${MAX_RETRIES:-3}
      - RETRY_DELAY=\${RETRY_DELAY:-1000}
      - REQUEST_TIMEOUT=\${REQUEST_TIMEOUT:-30000}
      - RANDOM_DELAY=\${RANDOM_DELAY:-100-500ms}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF
    
    # 启动服务
    docker compose -f docker-compose-go.yml up -d --build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Go 版本部署成功！${NC}"
        echo -e "${BLUE}🔗 访问地址: http://$(curl -s ifconfig.me):8001${NC}"
    else
        echo -e "${RED}❌ Go 版本部署失败${NC}"
    fi
}

# 主循环
main_loop() {
    while true; do
        show_title
        show_deploy_options
        
        read -p "请选择 (0-4): " choice
        echo ""
        
        case $choice in
            1)
                deploy_deno
                ;;
            2)
                deploy_go
                ;;
            3)
                deploy_deno
                deploy_go
                ;;
            4)
                echo -e "${BLUE}📝 请编辑配置文件: $PROJECT_DIR/.env${NC}"
                ;;
            0)
                echo -e "${GREEN}👋 感谢使用 DeepInfra2API！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 无效选择${NC}"
                ;;
        esac
        
        echo ""
        echo -e "${YELLOW}按任意键继续...${NC}"
        read -n 1 -s
    done
}

# 主函数
main() {
    show_title
    detect_os
    install_docker
    install_docker_compose
    setup_project
    main_loop
}

# 运行主函数
main "$@"
