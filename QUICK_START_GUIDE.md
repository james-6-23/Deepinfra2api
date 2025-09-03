# DeepInfra2API 快速开始指南

## 🎯 选择您的版本

### Go 版本（推荐生产环境）
- **优势**：高性能、低内存占用、优秀并发处理
- **端口**：8001
- **适用**：生产环境、高并发场景

### Deno 版本（推荐开发环境）
- **优势**：快速启动、现代 TypeScript、内置安全性
- **端口**：8000
- **适用**：开发环境、快速原型、轻量级部署

## 🚀 5分钟快速部署

### Go 版本部署
```bash
# 1. 进入目录
cd go-version

# 2. 复制配置
cp .env.example .env

# 3. 编辑配置（必须修改 API 密钥）
nano .env
# 修改：VALID_API_KEYS=your-actual-api-key

# 4. 启动服务
docker compose up -d

# 5. 验证服务
curl http://localhost:8001/health
```

### Deno 版本部署
```bash
# 1. 进入目录
cd deno-version

# 2. 复制配置
cp .env.example .env

# 3. 编辑配置（必须修改 API 密钥）
nano .env
# 修改：VALID_API_KEYS=your-actual-api-key

# 4. 启动服务
docker compose up -d

# 5. 验证服务
curl http://localhost:8000/health
```

## ⚙️ 基础配置

### 必须修改的配置
```env
# API 密钥（必须修改）
VALID_API_KEYS=your-actual-api-key

# 服务端口（可选修改）
PORT=8001  # Go 版本
PORT=8000  # Deno 版本
```

### 默认配置（开箱即用）
```env
# 端点配置（默认官方单端点）
DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions

# 性能模式（平衡模式）
PERFORMANCE_MODE=balanced

# 并发设置（适中配置）
MAX_CONCURRENT_CONNECTIONS=1000
```

## 🔧 高级配置（可选）

### 启用多端点负载均衡
```env
# 注释掉单端点配置
# DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions

# 启用多端点配置
DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions
```

### 启用 WARP 代理
```env
# 启用 WARP
WARP_ENABLED=true
HTTP_PROXY=http://deepinfra-warp:1080
HTTPS_PROXY=http://deepinfra-warp:1080

# 启动时包含 WARP
docker compose --profile warp up -d
```

### 高性能配置
```env
# 高性能模式
PERFORMANCE_MODE=fast

# 高并发设置
MAX_CONCURRENT_CONNECTIONS=2000
MEMORY_LIMIT_MB=4096
ENABLE_CONNECTION_POOLING=true
```

## 🧪 测试您的部署

### 健康检查
```bash
# Go 版本
curl http://localhost:8001/health

# Deno 版本
curl http://localhost:8000/health

# 预期响应：{"status":"healthy","timestamp":"..."}
```

### API 功能测试
```bash
# 获取模型列表
curl -H "Authorization: Bearer your-api-key" \
     http://localhost:8001/v1/models

# 聊天 API 测试
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'
```

## 🔄 服务管理

### 查看状态
```bash
# 查看容器状态
docker compose ps

# 查看日志
docker compose logs -f

# 查看资源使用
docker stats
```

### 重启服务（应用配置变更）
```bash
# 重启服务
docker compose restart

# 重新构建并启动
docker compose up -d --build
```

### 停止服务
```bash
# 停止服务
docker compose down

# 停止并删除数据
docker compose down -v
```

## 🛠️ 常见问题

### 1. 服务无法启动
```bash
# 检查端口是否被占用
netstat -tulpn | grep :8001

# 检查配置文件
cat .env

# 查看详细错误
docker compose logs
```

### 2. API 请求失败
```bash
# 检查 API 密钥
grep VALID_API_KEYS .env

# 测试健康检查
curl http://localhost:8001/health

# 查看请求日志
docker compose logs -f
```

### 3. 端口冲突
```bash
# 修改端口配置
nano .env
# 修改 PORT=8002

# 重启服务
docker compose up -d
```

### 4. 忘记复制配置文件
```bash
# 错误：No such file or directory: .env
# 解决：
cp .env.example .env
```

## 📊 性能建议

### 开发环境
```env
PERFORMANCE_MODE=balanced
MAX_CONCURRENT_CONNECTIONS=500
MEMORY_LIMIT_MB=1024
```

### 生产环境
```env
PERFORMANCE_MODE=fast
MAX_CONCURRENT_CONNECTIONS=2000
MEMORY_LIMIT_MB=4096
ENABLE_CONNECTION_POOLING=true
```

### 高可用环境
```env
# 多端点 + WARP 代理
DEEPINFRA_MIRRORS=https://worker1.workers.dev/v1/openai/chat/completions,https://worker2.workers.dev/v1/openai/chat/completions,https://api.deepinfra.com/v1/openai/chat/completions
WARP_ENABLED=true
ENDPOINT_HEALTH_CHECK=true
```

## 🎯 下一步

1. **选择版本**：根据需求选择 Go 或 Deno 版本
2. **基础部署**：复制配置文件并修改 API 密钥
3. **功能测试**：验证基础 API 功能
4. **高级配置**：根据需要启用多端点、WARP 等功能
5. **性能调优**：根据负载调整并发和性能参数

## 🔗 相关资源

- **验证工具**：`./verify-multi-endpoints.sh` - 多端点验证
- **Workers 测试**：`./test-workers-endpoints.sh` - Workers 端点测试
- **详细文档**：`README.md` - 完整使用说明
- **架构指南**：`ARCHITECTURE_RESTRUCTURE_GUIDE.md` - 架构说明

---

**🎉 开始使用您的 DeepInfra2API 服务吧！**
