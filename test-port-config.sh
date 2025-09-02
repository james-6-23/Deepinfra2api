#!/bin/bash

# 端口配置测试脚本
# 用于验证端口配置向导是否正常工作

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🧪 端口配置向导测试脚本${NC}"
echo -e "${CYAN}================================${NC}"

# 检查 quick-start.sh 是否存在
if [ ! -f "quick-start.sh" ]; then
    echo -e "${RED}❌ quick-start.sh 文件不存在${NC}"
    exit 1
fi

# 检查脚本语法
echo -e "${BLUE}📋 检查脚本语法...${NC}"
if bash -n quick-start.sh; then
    echo -e "${GREEN}✅ 脚本语法正确${NC}"
else
    echo -e "${RED}❌ 脚本语法错误${NC}"
    exit 1
fi

# 源码加载测试
echo -e "${BLUE}📋 测试函数加载...${NC}"
source quick-start.sh 2>/dev/null

# 检查关键函数是否存在
functions_to_check=(
    "check_port_available"
    "find_available_port"
    "get_current_ports"
    "configure_ports"
    "auto_assign_ports"
    "manual_assign_ports"
    "update_env_var"
)

for func in "${functions_to_check[@]}"; do
    if declare -f "$func" > /dev/null; then
        echo -e "  ${GREEN}✅ $func${NC}"
    else
        echo -e "  ${RED}❌ $func 函数不存在${NC}"
    fi
done

# 测试端口检测功能
echo ""
echo -e "${BLUE}📋 测试端口检测功能...${NC}"

# 测试已知占用的端口（通常 80 端口会被占用）
if check_port_available 80; then
    echo -e "  端口 80: ${GREEN}可用${NC}"
else
    echo -e "  端口 80: ${RED}被占用${NC} (这是正常的)"
fi

# 测试高端口（通常可用）
if check_port_available 58888; then
    echo -e "  端口 58888: ${GREEN}可用${NC}"
else
    echo -e "  端口 58888: ${RED}被占用${NC}"
fi

# 测试查找可用端口
echo ""
echo -e "${BLUE}📋 测试查找可用端口...${NC}"
available_port=$(find_available_port 58000)
if [ $? -eq 0 ] && [ -n "$available_port" ]; then
    echo -e "  找到可用端口: ${GREEN}$available_port${NC}"
else
    echo -e "  ${RED}❌ 未找到可用端口${NC}"
fi

# 测试获取当前端口配置
echo ""
echo -e "${BLUE}📋 测试获取当前端口配置...${NC}"
current_ports=($(get_current_ports))
echo -e "  当前 Deno 端口: ${YELLOW}${current_ports[0]}${NC}"
echo -e "  当前 Go 端口: ${YELLOW}${current_ports[1]}${NC}"

# 测试环境变量更新
echo ""
echo -e "${BLUE}📋 测试环境变量更新...${NC}"
# 备份原始 .env 文件
if [ -f ".env" ]; then
    cp .env .env.backup
    echo -e "  ${GREEN}✅ 已备份原始 .env 文件${NC}"
fi

# 测试更新环境变量
update_env_var "TEST_PORT" "9999"
if grep -q "TEST_PORT=9999" .env; then
    echo -e "  ${GREEN}✅ 环境变量更新成功${NC}"
    # 清理测试变量
    sed -i '/^TEST_PORT=/d' .env
else
    echo -e "  ${RED}❌ 环境变量更新失败${NC}"
fi

# 恢复原始 .env 文件
if [ -f ".env.backup" ]; then
    mv .env.backup .env
    echo -e "  ${GREEN}✅ 已恢复原始 .env 文件${NC}"
fi

echo ""
echo -e "${CYAN}🎯 测试完成！${NC}"
echo ""
echo -e "${BLUE}💡 使用建议:${NC}"
echo "1. 运行 ./quick-start.sh 并选择任意部署选项 (1-12)"
echo "2. 应该会看到端口配置向导出现"
echo "3. 如果端口有冲突，会提供三种解决方案"
echo "4. 配置完成后继续部署流程"
echo ""
echo -e "${YELLOW}如果端口配置向导没有出现，请检查：${NC}"
echo "- 脚本是否有执行权限: chmod +x quick-start.sh"
echo "- 是否在正确的目录中运行"
echo "- .env 文件是否存在"
