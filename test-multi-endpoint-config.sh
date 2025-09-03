#!/bin/bash

# 多端点配置功能测试脚本
# 用于测试交互式多端点配置和重启功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🧪 多端点配置功能测试${NC}"
echo "=================================="

# 备份原始 .env 文件
if [ -f .env ]; then
    cp .env .env.backup
    echo -e "${INFO} 已备份原始 .env 文件${NC}"
fi

# 测试1: 测试默认单端点配置
echo -e "${CYAN}测试1: 默认单端点配置${NC}"
echo "模拟用户输入为空（使用默认单端点）"

# 创建测试 .env 文件
cat > .env << 'EOF'
PORT=8001
VALID_API_KEYS=linux.do
PERFORMANCE_MODE=balanced
MAX_RETRIES=3
REQUEST_TIMEOUT=120000
STREAM_TIMEOUT=300000
EOF

# 模拟交互式配置（空输入）
echo "" | bash -c '
source quick-start.sh
configure_multi_endpoints_interactive
'

echo "检查配置结果:"
if grep -q "DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions" .env; then
    echo -e "${GREEN}✅ 默认单端点配置正确${NC}"
else
    echo -e "${RED}❌ 默认单端点配置失败${NC}"
fi

echo ""

# 测试2: 测试多端点配置
echo -e "${CYAN}测试2: 多端点配置${NC}"
echo "模拟用户输入多个域名"

# 重置 .env 文件
cat > .env << 'EOF'
PORT=8001
VALID_API_KEYS=linux.do
PERFORMANCE_MODE=balanced
MAX_RETRIES=3
REQUEST_TIMEOUT=120000
STREAM_TIMEOUT=300000
EOF

# 模拟交互式配置（多端点输入）
echo "api.deepinfra.com,api1.deepinfra.com,api2.deepinfra.com" | bash -c '
source quick-start.sh
configure_multi_endpoints_interactive
'

echo "检查配置结果:"
if grep -q "DEEPINFRA_MIRRORS=.*api.deepinfra.com.*api1.deepinfra.com.*api2.deepinfra.com" .env; then
    echo -e "${GREEN}✅ 多端点配置正确${NC}"
    echo "配置内容:"
    grep "DEEPINFRA_MIRRORS=" .env
else
    echo -e "${RED}❌ 多端点配置失败${NC}"
fi

echo ""

# 测试3: 测试域名清理功能
echo -e "${CYAN}测试3: 域名清理功能${NC}"
echo "测试带协议前缀和空格的输入"

# 重置 .env 文件
cat > .env << 'EOF'
PORT=8001
VALID_API_KEYS=linux.do
PERFORMANCE_MODE=balanced
MAX_RETRIES=3
REQUEST_TIMEOUT=120000
STREAM_TIMEOUT=300000
EOF

# 模拟输入带协议和空格的域名
echo " https://api.deepinfra.com , http://api1.deepinfra.com , api2.deepinfra.com " | bash -c '
source quick-start.sh
configure_multi_endpoints_interactive
'

echo "检查域名清理结果:"
if grep -q "DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions" .env; then
    echo -e "${GREEN}✅ 域名清理功能正确${NC}"
else
    echo -e "${RED}❌ 域名清理功能失败${NC}"
    echo "实际配置:"
    grep "DEEPINFRA_MIRRORS=" .env
fi

echo ""

# 测试4: 测试现有配置检测
echo -e "${CYAN}测试4: 现有配置检测${NC}"
echo "测试是否正确检测现有配置"

# 创建带现有配置的 .env 文件
cat > .env << 'EOF'
PORT=8001
VALID_API_KEYS=linux.do
DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions
PERFORMANCE_MODE=balanced
EOF

# 模拟用户选择使用现有配置
echo "y" | bash -c '
source quick-start.sh
configure_multi_endpoints_interactive
'

echo "检查是否保持现有配置:"
if grep -q "DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions" .env; then
    echo -e "${GREEN}✅ 现有配置检测正确${NC}"
else
    echo -e "${RED}❌ 现有配置检测失败${NC}"
fi

echo ""

# 测试5: 测试配置持久化
echo -e "${CYAN}测试5: 配置持久化测试${NC}"
echo "验证配置是否正确写入 .env 文件"

# 创建新的配置
cat > .env << 'EOF'
PORT=8001
VALID_API_KEYS=linux.do
PERFORMANCE_MODE=balanced
EOF

echo "test1.deepinfra.com,test2.deepinfra.com" | bash -c '
source quick-start.sh
configure_multi_endpoints_interactive
'

echo "检查配置持久化:"
if [ -f .env ] && grep -q "DEEPINFRA_MIRRORS=" .env; then
    echo -e "${GREEN}✅ 配置已持久化到 .env 文件${NC}"
    echo "配置内容:"
    grep "DEEPINFRA_MIRRORS=" .env
else
    echo -e "${RED}❌ 配置持久化失败${NC}"
fi

echo ""

# 测试6: 测试重启服务配置检测
echo -e "${CYAN}测试6: 重启服务配置检测${NC}"
echo "测试重启服务时是否正确读取配置"

# 创建完整的测试配置
cat > .env << 'EOF'
PORT=8001
VALID_API_KEYS=linux.do
DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions
HTTP_PROXY=http://deepinfra-warp:1080
HTTPS_PROXY=http://deepinfra-warp:1080
MAX_CONCURRENT_CONNECTIONS=2000
PERFORMANCE_MODE=balanced
EOF

# 测试配置检测函数
echo "测试配置检测功能:"
bash -c '
source quick-start.sh
profiles=$(detect_current_services)
echo "检测到的启动配置: $profiles"
if [[ "$profiles" == *"warp"* ]]; then
    echo "✅ WARP 配置检测正确"
else
    echo "❌ WARP 配置检测失败"
fi
if [[ "$profiles" == *"deno"* ]] && [[ "$profiles" == *"go"* ]]; then
    echo "✅ 应用服务配置检测正确"
else
    echo "❌ 应用服务配置检测失败"
fi
'

echo ""

# 恢复原始配置
echo -e "${BLUE}恢复原始配置...${NC}"
if [ -f .env.backup ]; then
    mv .env.backup .env
    echo -e "${GREEN}✅ 已恢复原始 .env 文件${NC}"
else
    rm -f .env
    echo -e "${INFO} 已删除测试 .env 文件${NC}"
fi

echo ""
echo -e "${GREEN}🎉 多端点配置功能测试完成！${NC}"
echo ""
echo -e "${BLUE}📋 测试总结:${NC}"
echo "1. 默认单端点配置 - 测试完成"
echo "2. 多端点配置 - 测试完成"
echo "3. 域名清理功能 - 测试完成"
echo "4. 现有配置检测 - 测试完成"
echo "5. 配置持久化 - 测试完成"
echo "6. 重启服务配置检测 - 测试完成"

echo ""
echo -e "${CYAN}💡 使用建议:${NC}"
echo "1. 运行 ./quick-start.sh 选择多端点选项进行实际测试"
echo "2. 使用选项 20 测试重启服务功能"
echo "3. 运行 ./verify-multi-endpoints.sh 验证多端点配置"
