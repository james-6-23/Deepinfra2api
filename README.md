# DeepInfra2API

一个高性能的 DeepInfra API 代理服务，提供 OpenAI 兼容的接口，支持多端点负载均衡和故障转移。

> ⚠️ **重要免责声明**
> 
> 本项目仅供学习、研究和技术交流使用。使用本项目时，请用户自觉遵守以下条款：
> 
> 1. **学习用途**：本项目主要用于学习 API 代理技术、容器化部署、负载均衡等技术实践
> 2. **合规使用**：请确保您使用本项目时遵守当地法律法规及相关服务提供商的使用条款
> 3. **自担风险**：使用本项目产生的任何后果由使用者自行承担，开发者不承担任何责任
> 4. **商业使用**：如需商业使用，请确保获得相应的授权许可
> 5. **技术交流**：欢迎提出技术问题和改进建议，共同推进技术发展
> 
> **请在充分理解上述条款的基础上，负责任地使用本项目。**

## 🌟 特性

- **OpenAI 兼容**：完全兼容 OpenAI API 格式
- **多端点支持**：支持多个 DeepInfra 端点的负载均衡
- **故障转移**：自动故障检测和端点切换
- **流式响应**：支持 Server-Sent Events (SSE) 流式输出
- **双语言实现**：提供 Deno (TypeScript) 和 Go 两个版本
- **智能端口管理**：自动检测端口冲突并提供解决方案
- **隐私保护**：默认不记录用户消息和响应内容
- **模块化部署**：支持统一部署、独立部署、一键部署三种模式

## 🚀 快速开始

### 方式一：统一部署（推荐）

```bash
# 克隆项目
git clone https://github.com/james-6-23/DeepInfra2API.git
cd DeepInfra2API

# 运行统一启动脚本（15种部署选项）
chmod +x quick-start.sh
./quick-start.sh
```

**特点**：
- 🎯 15种部署选项（Deno/Go/双版本 × 基础/多端点/WARP/多端点+WARP + Linux一键部署）
- 🔧 智能端口配置向导，自动检测并解决端口冲突
- 🔄 循环菜单设计，支持连续操作和管理
- 📊 实时服务状态监控和日志查看
- 🛡️ 内置配置验证和安全检查

### 方式二：分版本独立部署

**Deno 版本（TypeScript）**：
```bash
cd deno-version
chmod +x deploy.sh
./deploy.sh
```

**Go 版本（高性能）**：
```bash
cd go-version
chmod +x deploy.sh
./deploy.sh
```

**特点**：
- 🎨 独立的 Docker Compose 配置
- ⚡ 简化的部署流程
- 🏭 适合生产环境单一版本部署
- 🔧 版本特定的优化配置

### 方式三：Linux 服务器一键部署

```
# 下载并运行一键部署脚本
curl -fsSL https://raw.githubusercontent.com/your-repo/DeepInfra2API/main/linux-deploy.sh | bash

# 或者下载后运行
wget https://raw.githubusercontent.com/your-repo/DeepInfra2API/main/linux-deploy.sh
chmod +x linux-deploy.sh
./linux-deploy.sh
```

**特点**：
- 🐧 自动检测 Linux 发行版（Ubuntu/Debian/CentOS/RHEL/Fedora/Arch）
- 📦 自动安装 Docker 和 Docker Compose V2
- 🚀 零配置，开箱即用，生产就绪
- 🔒 自动配置防火墙和安全策略
- 📊 内置服务监控和日志管理

### 方式四：配置文件快速启动

```
# 1. 复制配置模板
cp .env.example .env

# 2. 编辑配置（可选，默认配置即可使用）
nano .env

# 3. 选择启动方式
# Deno 版本（端口 8000）
docker compose --profile deno up -d --build

# Go 版本（端口 8001）
docker compose --profile go up -d --build

# 双版本对比部署
docker compose --profile deno --profile go up -d --build

# 完整部署（双版本 + WARP 代理）
docker compose --profile warp --profile deno --profile go up -d --build
```

## 🐳 Docker 部署方式

### 使用 Docker Compose（探荐）

**统一配置文件部署**：
```bash
# 复制配置模板
cp .env.example .env

# 启动 Deno 版本（端口 8000）
docker compose --profile deno up -d --build

# 启动 Go 版本（端口 8001）
docker compose --profile go up -d --build

# 启动双版本（对比测试）
docker compose --profile deno --profile go up -d --build

# 启动双版本 + WARP 代理（增强反封锁）
docker compose --profile warp --profile deno --profile go up -d --build

# 启动指定版本 + WARP
docker compose --profile warp --profile deno up -d --build
docker compose --profile warp --profile go up -d --build
```

**独立配置文件部署**：
```
# Deno 版本独立部署
cd deno-version
docker compose up -d --build

# Go 版本独立部署
cd go-version
docker compose up -d --build
```

### 使用传统 Docker 命令

**构建镜像**：
```
# 构建 Deno 版本
docker build -t deepinfra2api-deno ./deno-version

# 构建 Go 版本
docker build -t deepinfra2api-go ./go-version
```

**运行容器**：
```bash
# 运行 Deno 版本（端口 8000）
docker run -d \
  --name deepinfra-proxy-deno \
  -p 8000:8000 \
  -e VALID_API_KEYS=linux.do \
  -e ENABLE_DETAILED_LOGGING=true \
  -e LOG_USER_MESSAGES=false \
  -e LOG_RESPONSE_CONTENT=false \
  --restart unless-stopped \
  deepinfra2api-deno

# 运行 Go 版本（端口 8001）
docker run -d \
  --name deepinfra-proxy-go \
  -p 8001:8000 \
  -e VALID_API_KEYS=linux.do \
  -e ENABLE_DETAILED_LOGGING=true \
  -e LOG_USER_MESSAGES=false \
  -e LOG_RESPONSE_CONTENT=false \
  --restart unless-stopped \
  deepinfra2api-go
```

**使用环境文件**：
```bash
# 使用 .env 文件
docker run -d \
  --name deepinfra-proxy-deno \
  -p 8000:8000 \
  --env-file .env \
  --restart unless-stopped \
  deepinfra2api-deno
```

**多端点配置示例**：
```bash
# 启用多端点负载均衡
docker run -d \
  --name deepinfra-proxy-go \
  -p 8001:8000 \
  -e VALID_API_KEYS=linux.do \
  -e DEEPINFRA_MIRRORS="https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions" \
  -e PERFORMANCE_MODE=balanced \
  --restart unless-stopped \
  deepinfra2api-go
```

### Docker 管理命令

**服务状态查看**：
```bash
# 查看所有容器状态
docker compose ps

# 查看特定服务日志
docker compose logs -f deepinfra-proxy-deno
docker compose logs -f deepinfra-proxy-go
docker compose logs -f deepinfra-warp

# 实时监控资源使用
docker stats deepinfra-proxy-deno deepinfra-proxy-go deepinfra-warp
```

**服务重启与更新**：
```bash
# 重启特定服务
docker compose restart deepinfra-proxy-deno
docker compose restart deepinfra-proxy-go

# 更新服务（重新构建）
docker compose --profile deno down
docker compose --profile deno up -d --build

# 停止所有服务
docker compose down

# 停止特定profile
docker compose --profile deno down
docker compose --profile go down
docker compose --profile warp down
```

## 🔧 API 使用

### 基本请求

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [
      {"role": "user", "content": "Hello, world!"}
    ]
  }'
```

### 流式请求

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [
      {"role": "user", "content": "Hello, world!"}
    ],
    "stream": true
  }'
```

### 健康检查

```bash
curl http://localhost:8000/health
```

## 📊 版本对比与性能分析

### 版本特性对比

| 特性 | Deno 版本 | Go 版本 | 推荐场景 |
|------|-----------|-----------|----------|
| **开发语言** | TypeScript | Go | - |
| **内存占用** | ~50-80MB | ~15-25MB | 🏆 Go 胜出 |
| **启动时间** | ~2-3s | ~0.5-1s | 🏆 Go 胜出 |
| **并发性能** | 中等 | 高 | 🏆 Go 胜出 |
| **开发速度** | 快 | 中等 | 🏆 Deno 胜出 |
| **调试友好** | 高 | 中等 | 🏆 Deno 胜出 |
| **部署简易** | 高 | 中等 | 🏆 Deno 胜出 |
| **生产稳定** | 中等 | 高 | 🏆 Go 胜出 |
| **资源效率** | 中等 | 高 | 🏆 Go 胜出 |

### 性能基准测试（估算值）

| 指标 | Deno 版本 | Go 版本 | 提升比例 |
|------|-----------|-----------|----------|
| **请求延迟** | 50-100ms | 20-50ms | Go 快 40-60% |
| **并发处理** | 1000 req/s | 3000+ req/s | Go 快 3倍+ |
| **内存利用** | 100MB处理量 | 300MB处理量 | Go 效率提升3倍 |
| **CPU 使用** | 60-80% | 30-50% | Go 节约 30-40% |
| **启动时间** | 2-3秒 | 0.5-1秒 | Go 快 50-75% |

### 适用场景分析

**Deno 版本适合**：
- 💻 **开发环境**：快速原型开发、功能验证
- 🎓 **学习研究**：代码可读性高，适合学习 API 代理技术
- ⚡ **快速部署**：TypeScript 直接运行，无编译步骤
- 🔧 **功能迭代**：热加载、快速修改和测试
- 👍 **中小型项目**：日请求量 < 10万次的场景

**Go 版本适合**：
- 🏭 **生产环境**：高并发、低延迟、高可靠性要求
- 🚀 **高性能场景**：日请求量 > 100万次的大型应用
- 💰 **成本敏感**：优化服务器资源使用，降低运营成本
- 🔒 **企业级应用**：稳定性和可靠性要求较高
- 🌍 **全球分发**：需要部署在多个地区的CDN边缘节点

### 部署策略建议

**渐进式迁移方案**：
1. **阶段一**：使用 Deno 版本进行快速原型开发和功能验证
2. **阶段二**：双版本并行部署，进行性能对比测试
3. **阶段三**：生产环境迁移至 Go 版本，保留 Deno 版本作为备用

**容网级别建议**：
- **开发测试**：优先选择 Deno 版本
- **预生产**：双版本部署，性能对比
- **生产环境**：优先选择 Go 版本
- **灵灾部署**：同时部署两个版本，根据负载灵活切换

## 🔍 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 检查端口占用
   netstat -tuln | grep 8000
   # 修改 .env 文件中的端口配置
   ```

2. **API 密钥无效**
   ```bash
   # 检查 .env 文件中的 VALID_API_KEYS 配置
   ```

3. **容器启动失败**
   ```bash
   # 查看日志
   docker compose logs -f
   ```

## 📋 配置文件说明

### 环境变量配置 (.env)

本项目提供了完善的配置模板 `.env.example`，复制为 `.env` 即可使用。

```
# 复制配置模板
cp .env.example .env

# 编辑配置（可选，默认配置即可使用）
nano .env
```

#### 基础服务配置

```
# ===========================================
# 基础服务配置
# ===========================================

# 服务端口配置
PORT=8000                                  # 默认服务端口
DOMAIN=deepinfra.example.com               # 服务域名（可选）

# Docker 容器配置
BACKEND_HOST=deepinfra-proxy               # 容器内部主机名
BACKEND_PORT=8000                          # 容器内部端口
NGINX_PORT=80                              # Nginx 端口

# Docker Compose Profile 端口配置
DENO_PORT=8000                             # Deno 版本端口
GO_PORT=8001                               # Go 版本端口
```

#### 身份验证配置

```
# ===========================================
# API 密钥配置
# ===========================================

# API 密钥配置（逗号分隔多个key）
VALID_API_KEYS=linux.do                    # 示例密钥，请修改为实际密钥
# VALID_API_KEYS=key1,key2,key3           # 多密钥配置示例
```

#### 多端点负载均衡配置

```
# ===========================================
# 多端点配置（可选，逗号分隔）
# ===========================================

# 启用多端点可以提高可用性和稳定性
DEEPINFRA_MIRRORS="https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions"

# 或使用单一端点（默认）
# DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions
```

#### 性能与安全平衡配置

```
# ===========================================
# 性能与安全平衡配置
# ===========================================

PERFORMANCE_MODE=balanced                  # 性能模式：fast, balanced, secure

# 平衡模式配置 (PERFORMANCE_MODE=balanced) - 默认推荐
MAX_RETRIES=3                              # 最大重试次数
RETRY_DELAY=1000                           # 重试延迟（毫秒）
REQUEST_TIMEOUT=30000                      # 请求超时（毫秒）
RANDOM_DELAY_MIN=100                       # 最小随机延迟（毫秒）
RANDOM_DELAY_MAX=500                       # 最大随机延迟（毫秒）

# 快速模式配置 (PERFORMANCE_MODE=fast) - 适合开发测试
# MAX_RETRIES=1
# RETRY_DELAY=200
# REQUEST_TIMEOUT=10000
# RANDOM_DELAY_MIN=0
# RANDOM_DELAY_MAX=100

# 安全模式配置 (PERFORMANCE_MODE=secure) - 适合高风险环境
# MAX_RETRIES=5
# RETRY_DELAY=2000
# REQUEST_TIMEOUT=60000
# RANDOM_DELAY_MIN=500
# RANDOM_DELAY_MAX=1500
```

#### 日志与隐私配置

```
# ===========================================
# 日志与隐私配置（隐私保护优化）
# ===========================================

ENABLE_DETAILED_LOGGING=true               # 启用详细日志
LOG_USER_MESSAGES=false                    # 记录用户消息内容（默认关闭）
LOG_RESPONSE_CONTENT=false                 # 记录响应内容（默认关闭）
```

#### WARP 代理配置（可选）

```
# ===========================================
# WARP 代理配置（可选）
# ===========================================

# 代理配置（当启用 WARP profile 时生效）
# HTTP_PROXY=http://deepinfra-warp:1080
# HTTPS_PROXY=http://deepinfra-warp:1080

# WARP 服务配置
WARP_ENABLED=true                          # 启用 WARP 服务
# WARP_LICENSE_KEY=your-warp-plus-key      # WARP+ 许可证密钥（可选）
```

### 性能模式详细对比

| 模式 | 延迟增加 | 安全性 | 适用场景 | 推荐版本 | 配置特点 |
|------|----------|--------|----------|----------|----------|
| **fast** | +0-100ms | 低 | 开发测试、速度优先 | Deno | 最少延迟，最快响应 |
| **balanced** | +100-500ms | 中 | 生产环境推荐 | Go | 性能与安全平衡 |
| **secure** | +500-1500ms | 高 | 高风险环境、安全优先 | Go | 最大安全性，最高稳定性 |

### Docker Compose 配置说明

**根目录 docker-compose.yml**（统一部署）：
- 支持 profiles 配置：`deno`、`go`、`warp`
- 使用环境变量动态配置端口
- 包含健康检查和重启策略
- 统一网络配置

**独立版本配置文件**：
- `deno-version/docker-compose.yml`：Deno 版本独立配置
- `go-version/docker-compose.yml`：Go 版本独立配置
- 包含完整的服务定义和健康检查

### 部署脚本说明

**统一部署脚本**：
- `quick-start.sh`：15种部署选项，智能端口配置
- 支持循环菜单和连续操作
- 自动端口冲突检测和解决

**独立部署脚本**：
- `deno-version/deploy.sh`：Deno 版本独立部署
- `go-version/deploy.sh`：Go 版本独立部署
- 简化的部署流程，适合生产环境

**Linux 一键部署**：
- `linux-deploy.sh`：自动安装 Docker，支持多发行版
- 零配置部署，生产就绪

## ⚖️ 法律声明与责任条款

### 🔍 使用场景与限制

**适用场景**：
- 🎓 **学习研究**：API 代理技术、Docker 容器化、微服务架构学习
- 🛠️ **技术实验**：负载均衡、故障转移、流式响应处理技术验证
- 🔬 **开发测试**：本地开发环境搭建、接口兼容性测试
- 📚 **教学演示**：云原生技术、反向代理技术教学案例

**禁止用途**：
- ❌ 违反服务提供商使用条款的行为
- ❌ 恶意攻击、滥用或超出合理使用范围的行为
- ❌ 商业化使用（除非获得相应授权）
- ❌ 任何可能违反当地法律法规的行为

### 📋 使用条款

1. **技术学习目的**：本项目专为技术学习、研究和教学而设计
2. **合规责任**：用户需自行确保使用行为符合相关法律法规
3. **风险自担**：使用本项目产生的任何后果由用户自行承担
4. **无担保声明**：本项目按"原样"提供，不提供任何明示或暗示的担保
5. **及时更新**：请关注相关服务的使用条款变更

### 🛡️ 免责声明

**开发者声明**：
- 本项目开发者不对使用本项目导致的任何直接或间接损失承担责任
- 不对项目的适用性、可靠性、准确性做出保证
- 用户应当基于自己的判断和风险评估来使用本项目
- 如因使用本项目违反第三方权利或相关法规，责任由用户自负

**服务提供商权利**：
- 相关 API 服务提供商保留随时修改服务条款的权利
- 用户应当遵守原始服务提供商的所有使用条款和限制
- 建议用户直接查阅并遵循官方服务条款

### 🤝 开源贡献

**欢迎贡献**：
- 💡 技术改进建议和代码优化
- 🐛 问题报告和修复方案
- 📖 文档完善和使用案例分享
- 🔒 安全漏洞报告（请私密联系）

**贡献原则**：
- 确保代码质量和安全性
- 遵循项目的开源协议
- 保持技术中立，专注于技术实现

## 📞 联系与支持

**技术交流**：
- 通过 GitHub Issues 讨论技术问题
- 欢迎提交 Pull Request 改进项目
- 分享使用经验和最佳实践

**注意**：我们只提供技术支持，不提供使用方面的法律建议。请用户自行咨询相关法律专业人士。

## 📄 许可证

MIT License - 详见 LICENSE 文件

---

**最终提醒**：使用本项目即表示您已充分理解并同意上述所有条款。请在合规的前提下，将其作为学习和研究工具使用。
