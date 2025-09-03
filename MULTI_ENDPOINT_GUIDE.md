# 多端点配置优化指南

## 🎯 优化概览

本次优化完全重构了多端点配置逻辑和服务重启功能，提供了更加智能和用户友好的配置体验。

## 🔧 新功能特性

### 1. **交互式多端点配置**

#### 自动检测现有配置
- 启动时自动检查 `.env` 文件中的 `DEEPINFRA_MIRRORS` 配置
- 如果已有配置，询问用户是否使用现有配置
- 支持配置的查看和修改

#### 智能域名处理
- 用户只需输入域名，无需完整URL
- 自动清理域名中的协议前缀（http://、https://）
- 自动去除多余的空格
- 自动转换为完整的端点URL格式

#### 默认配置支持
- 用户未输入任何内容时，自动使用官方单端点
- 提供清晰的输入提示和示例

### 2. **强化的服务重启功能**

#### 强制停止机制
```bash
# 新增强制停止功能
force_stop_containers() {
    # 获取所有相关容器并强制停止
    # 清理网络资源
    # 确保完全停止
}
```

#### 智能配置检测
```bash
# 自动检测当前配置
detect_current_services() {
    # 读取 .env 文件配置
    # 检测 WARP 代理配置
    # 检测多端点配置
    # 检测高并发配置
    # 返回相应的启动参数
}
```

#### 分阶段重启
- **WARP 版本**：先启动 WARP 代理，再启动应用服务
- **普通版本**：直接启动所有服务
- **配置验证**：重启后自动验证服务状态

## 📋 使用方法

### 交互式多端点配置

#### 方法1：通过启动脚本
```bash
./quick-start.sh
# 选择任意多端点选项（2, 4, 6, 8, 10, 14, 16）
# 系统会自动提示配置多端点
```

#### 方法2：直接配置
当选择多端点选项时，系统会显示：
```
🌐 多端点负载均衡配置
ℹ️ 当前配置: DEEPINFRA_MIRRORS=... (如果已有配置)
是否使用现有配置？ (y/n, 默认: y)

请输入 DeepInfra 端点域名（用逗号分隔）
示例: api.deepinfra.com,api1.deepinfra.com,api2.deepinfra.com
留空则使用默认单端点 (api.deepinfra.com)
> 
```

#### 输入示例
```bash
# 示例1: 标准多端点
api.deepinfra.com,api1.deepinfra.com,api2.deepinfra.com

# 示例2: 带协议前缀（会自动清理）
https://api.deepinfra.com, http://api1.deepinfra.com, api2.deepinfra.com

# 示例3: 空输入（使用默认单端点）
[直接按回车]

# 示例4: 自定义端点
custom1.deepinfra.com,custom2.deepinfra.com
```

### 服务重启功能

#### 使用方法
```bash
./quick-start.sh
# 选择选项 20) 重启所有服务（应用 .env 配置变更）
```

#### 重启流程
1. **检查当前状态** - 显示运行中的服务
2. **优雅停止** - 尝试正常停止所有服务
3. **强制停止** - 如果优雅停止失败，强制停止
4. **配置检测** - 读取 `.env` 文件检测配置
5. **分阶段启动** - 根据配置启动相应服务
6. **健康检查** - 验证所有服务状态
7. **配置摘要** - 显示当前配置信息

## 🔍 配置验证

### 验证多端点配置
```bash
# 运行多端点验证脚本
./verify-multi-endpoints.sh

# 检查 .env 文件配置
cat .env | grep DEEPINFRA_MIRRORS

# 测试 API 访问
curl -H "Authorization: Bearer linux.do" http://localhost:8001/v1/models
```

### 验证重启功能
```bash
# 修改 .env 文件中的配置
nano .env

# 重启服务应用配置
./quick-start.sh
# 选择选项 20

# 验证配置是否生效
docker compose ps
curl http://localhost:8001/health
```

## 📊 配置示例

### 单端点配置
```env
DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions
```

### 多端点配置
```env
DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions
```

### 完整配置示例
```env
# 基础配置
PORT=8001
VALID_API_KEYS=linux.do

# 多端点配置
DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions

# WARP 代理配置
HTTP_PROXY=http://deepinfra-warp:1080
HTTPS_PROXY=http://deepinfra-warp:1080

# 高并发配置
MAX_CONCURRENT_CONNECTIONS=2000
STREAM_BUFFER_SIZE=32768
MEMORY_LIMIT_MB=4096

# 性能配置
PERFORMANCE_MODE=balanced
REQUEST_TIMEOUT=120000
STREAM_TIMEOUT=300000
```

## 🛠️ 故障排除

### 重启服务失败
```bash
# 问题：服务无法正常停止
# 解决：脚本会自动尝试强制停止

# 问题：端口被占用
# 解决：检查端口占用情况
netstat -an | grep 8001
lsof -i :8001

# 问题：Docker 服务异常
# 解决：重启 Docker 服务
sudo systemctl restart docker
```

### 多端点配置问题
```bash
# 问题：端点不可用
# 解决：运行端点验证
./verify-multi-endpoints.sh

# 问题：配置未生效
# 解决：检查 .env 文件
cat .env | grep DEEPINFRA_MIRRORS

# 问题：负载均衡不工作
# 解决：重启服务应用配置
./quick-start.sh # 选择选项 20
```

### 配置检测问题
```bash
# 问题：配置检测错误
# 解决：手动检查 .env 文件格式
grep -n "DEEPINFRA_MIRRORS" .env

# 问题：环境变量未加载
# 解决：确保 .env 文件格式正确
# 每行格式：KEY=VALUE（无空格）
```

## 🎯 最佳实践

### 1. 端点选择建议
- **生产环境**：使用官方多端点提高可用性
- **测试环境**：可以使用单端点节省资源
- **网络受限**：结合 WARP 代理使用

### 2. 配置管理建议
- 定期备份 `.env` 文件
- 使用版本控制管理配置变更
- 测试配置变更后及时验证

### 3. 监控建议
- 定期运行验证脚本检查服务状态
- 监控端点可用性和响应时间
- 关注服务日志中的错误信息

## 🚀 升级指南

### 从旧版本升级
1. **备份配置**：`cp .env .env.backup`
2. **停止服务**：`docker compose down`
3. **更新代码**：`git pull`
4. **重启服务**：使用选项 20 重启
5. **验证功能**：运行验证脚本

### 配置迁移
- 旧版本的配置会自动兼容
- 新功能需要重新配置多端点
- 建议使用交互式配置更新设置

---

**🎉 现在您可以享受更加智能和可靠的多端点配置体验！**
