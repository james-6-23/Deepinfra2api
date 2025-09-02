# DeepInfra2API 部署指南

## 🏗️ 项目架构

本项目现在支持两种语言实现：

```
Deepinfra2api/
├── deno-version/           # Deno/TypeScript 版本
│   ├── app.ts             # 主应用文件
│   ├── deno.json          # Deno 配置
│   └── Dockerfile         # Deno 版本 Docker 配置
├── go-version/            # Go 版本
│   ├── main.go            # 主应用文件
│   ├── go.mod             # Go 模块配置
│   └── Dockerfile         # Go 版本 Docker 配置
├── docker-compose.yml     # 统一的 Docker Compose 配置
├── .env                   # 环境变量配置
└── warp-data/            # WARP 代理数据目录
```

## 🚀 快速部署

### 方案 1：部署 Deno 版本（推荐用于开发）

```bash
# 1. 启动 Deno 版本（端口 8000）
docker compose --profile deno up -d --build

# 2. 如果需要 WARP 代理
docker compose --profile warp --profile deno up -d --build

# 3. 测试服务
curl http://localhost:8000/health
```

### 方案 2：部署 Go 版本（推荐用于生产）

```bash
# 1. 启动 Go 版本（端口 8001）
docker compose --profile go up -d --build

# 2. 如果需要 WARP 代理
docker compose --profile warp --profile go up -d --build

# 3. 测试服务
curl http://localhost:8001/health
```

### 方案 3：同时部署两个版本

```bash
# 同时启动两个版本进行对比测试
docker compose --profile deno --profile go up -d --build

# 带 WARP 代理
docker compose --profile warp --profile deno --profile go up -d --build

# 测试两个版本
curl http://localhost:8000/health  # Deno 版本
curl http://localhost:8001/health  # Go 版本
```

## 🔧 配置说明

### 环境变量配置

编辑 `.env` 文件：

```bash
# 服务配置
DOMAIN=your.domain.com

# Docker 端口配置
DENO_PORT=8000    # Deno 版本端口
GO_PORT=8001      # Go 版本端口

# API Key 配置（逗号分隔多个key）
VALID_API_KEYS=your-api-key-1,your-api-key-2

# 多端点配置（可选，逗号分隔）
DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions

# 性能与安全平衡配置
PERFORMANCE_MODE=balanced  # 选项: fast, balanced, secure

# 平衡模式配置 (PERFORMANCE_MODE=balanced) - 默认
MAX_RETRIES=3
RETRY_DELAY=1000
REQUEST_TIMEOUT=30000
RANDOM_DELAY_MIN=100
RANDOM_DELAY_MAX=500

# 代理配置（可选）
HTTP_PROXY=http://deepinfra-warp:1080
HTTPS_PROXY=http://deepinfra-warp:1080

# WARP 配置（可选）
WARP_ENABLED=true
# WARP_LICENSE_KEY=your-warp-plus-key
```

### 性能模式对比

| 模式 | 延迟增加 | 安全性 | 适用场景 | 推荐版本 |
|------|----------|--------|----------|----------|
| **fast** | +0-100ms | 低 | 开发测试、速度优先 | Deno |
| **balanced** | +100-500ms | 中 | 生产环境推荐 | Go |
| **secure** | +500-1500ms | 高 | 高风险环境、安全优先 | Go |

## 📊 版本对比

### Deno 版本特点
- ✅ 开发速度快，TypeScript 原生支持
- ✅ 内置安全沙箱
- ✅ 现代 JavaScript/TypeScript 特性
- ❌ 内存占用相对较高
- ❌ 启动时间较长

### Go 版本特点
- ✅ 性能优异，内存占用低
- ✅ 编译后的二进制文件小
- ✅ 启动速度快
- ✅ 更适合生产环境
- ❌ 开发周期相对较长

## 🛠️ 管理命令

### 查看服务状态
```bash
# 查看所有容器状态
docker compose ps

# 查看特定版本日志
docker compose logs -f deepinfra-proxy-deno
docker compose logs -f deepinfra-proxy-go
docker compose logs -f deepinfra-warp
```

### 重启服务
```bash
# 重启 Deno 版本
docker compose restart deepinfra-proxy-deno

# 重启 Go 版本
docker compose restart deepinfra-proxy-go

# 重启 WARP 代理
docker compose restart deepinfra-warp
```

### 停止服务
```bash
# 停止所有服务
docker compose down

# 停止特定 profile
docker compose --profile deno down
docker compose --profile go down
docker compose --profile warp down
```

### 更新服务
```bash
# 更新 Deno 版本
docker compose --profile deno down
docker compose --profile deno up -d --build

# 更新 Go 版本
docker compose --profile go down
docker compose --profile go up -d --build
```

## 🔍 故障排除

### 构建失败
```bash
# 清理 Docker 缓存
docker builder prune -f

# 单独构建镜像
docker build -t deepinfra-proxy-deno ./deno-version
docker build -t deepinfra-proxy-go ./go-version
```

### 端口冲突
```bash
# 检查端口占用
netstat -tlnp | grep :8000
netstat -tlnp | grep :8001

# 修改 .env 文件中的端口配置
DENO_PORT=8002
GO_PORT=8003
```

### 网络连接问题
```bash
# 测试容器间网络
docker exec deepinfra-proxy-deno curl -f http://localhost:8000/health
docker exec deepinfra-proxy-go curl -f http://localhost:8000/health

# 测试 WARP 代理
docker exec deepinfra-warp curl --socks5-hostname 127.0.0.1:1080 https://cloudflare.com/cdn-cgi/trace
```

## 🎯 API 使用示例

### 健康检查
```bash
# Deno 版本
curl http://localhost:8000/health

# Go 版本
curl http://localhost:8001/health
```

### 获取模型列表
```bash
# Deno 版本
curl -H "Authorization: Bearer your-api-key" http://localhost:8000/v1/models

# Go 版本
curl -H "Authorization: Bearer your-api-key" http://localhost:8001/v1/models
```

### 聊天对话
```bash
# 非流式请求
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": false
  }'

# 流式请求
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": true
  }'
```

## 🎉 最佳实践

### 生产环境部署
1. 使用 Go 版本以获得更好的性能
2. 启用 WARP 代理增强反封锁能力
3. 配置多个 API 端点进行负载均衡
4. 使用 `balanced` 或 `secure` 性能模式
5. 定期监控服务健康状态

### 开发环境部署
1. 使用 Deno 版本以获得更快的开发体验
2. 使用 `fast` 性能模式减少延迟
3. 可以不启用 WARP 代理简化配置

### 监控和维护
```bash
# 定期检查服务状态
watch -n 30 'curl -s http://localhost:8000/health | jq .'
watch -n 30 'curl -s http://localhost:8001/health | jq .'

# 查看资源使用情况
docker stats deepinfra-proxy-deno deepinfra-proxy-go deepinfra-warp
```
