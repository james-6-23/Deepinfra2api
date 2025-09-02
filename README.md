# DeepInfra API 代理服务器

🚀 一个用 Deno + Docker + Nginx 构建的 DeepInfra API 代理服务器，提供 OpenAI 兼容的接口。

## ✨ 功能特性

- 🔐 自定义 API Key 验证
- 📋 支持模型列表查询
- 💬 聊天完成接口（支持流式响应）
- 🧠 智能处理思考内容（reasoning_content）
- 🐳 Docker 容器化部署
- 🔒 Nginx HTTPS 反向代理
- 🌐 CORS 跨域支持
- 📊 健康检查接口

## 🚀 快速部署

### 方法一：一键部署脚本

```bash
# 给脚本执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

### 方法二：手动部署

```bash
# 1. 构建并启动服务
docker compose up -d --build

# 2. 查看服务状态
docker compose ps

# 3. 查看日志
docker compose logs -f
```

## 📋 部署前准备

### 1. 环境配置
复制并修改环境变量文件：
```bash
cp .env.example .env
vim .env  # 或使用其他编辑器
```

主要配置项：
- `DOMAIN`: 你的域名 (默认: deepinfra.kyx03.de)
- `PORT`: 后端服务端口 (默认: 8000)
- `NGINX_PORT`: Nginx 端口 (默认: 80)
- `VALID_API_KEYS`: API 密钥 (逗号分隔)

### 2. 域名解析
确保你的域名已正确解析到服务器 IP

### 3. 防火墙设置
开放配置的 Nginx 端口：
```bash
sudo ufw allow ${NGINX_PORT:-80}
```

### 4. Cloudflare 配置
- SSL/TLS 加密模式设置为 "Flexible" 或 "Full"
- 开启 "Always Use HTTPS" (可选)
- 配置 DNS 解析到服务器 IP

## 🌐 API 接口

### 健康检查
```bash
# HTTP (本地测试)
curl http://deepinfra.kyx03.de/health

# HTTPS (通过 Cloudflare)
curl https://deepinfra.kyx03.de/health
```

### 获取模型列表
```bash
curl https://deepinfra.kyx03.de/v1/models
```

### 聊天完成
```bash
curl -X POST https://deepinfra.kyx03.de/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": false
  }'
```

## 🔧 配置说明

### 📝 环境变量配置
所有配置都通过 `.env` 文件管理，主要配置项：

```bash
# 服务配置
DOMAIN=your-domain.com          # 你的域名
PORT=8000                       # 后端服务端口
NGINX_PORT=80                   # Nginx 端口

# API Key 配置
VALID_API_KEYS=key1,key2,key3   # 多个 API Key

# 高级配置
MAX_RETRIES=3                   # 最大重试次数
RETRY_DELAY=1000               # 重试延迟(ms)
REQUEST_TIMEOUT=30000          # 请求超时(ms)

# WARP 代理配置
WARP_ENABLED=true              # 是否启用 WARP
WARP_LICENSE_KEY=your-key      # WARP+ 许可证(可选)

# 多端点配置
DEEPINFRA_MIRRORS=url1,url2    # 镜像端点(可选)
```

### 📊 部署模式
支持两种部署模式：

1. **基础模式**: 仅部署 API 代理服务
2. **完整模式**: 包含 WARP 代理，更强的反封锁能力

部署时可以选择模式

### 支持的模型
当前支持以下模型：
- `deepseek-ai/DeepSeek-V3.1`
- `deepseek-ai/DeepSeek-R1-0528-Turbo`
- `openai/gpt-oss-120b`
- `zai-org/GLM-4.5`
- 等等...

## 📊 管理命令

```bash
# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f deepinfra-proxy
docker compose logs -f nginx

# 重启服务
docker compose restart

# 停止服务
docker compose down

# 更新服务
docker compose down
docker compose up -d --build
```

## 🛠️ 本地开发

```bash
# 安装 Deno
curl -fsSL https://deno.land/install.sh | sh

# 运行开发服务器
deno task dev

# 或直接运行
deno run --allow-net --allow-env app.ts
```

## 📁 项目结构

```
.
├── app.ts              # 主应用文件
├── Dockerfile          # Docker 构建文件
├── docker-compose.yml  # Docker Compose 配置
├── nginx.conf         # Nginx 简单反向代理配置
├── deploy.sh          # 一键部署脚本
├── deno.json          # Deno 配置
└── .dockerignore      # Docker 忽略文件
```

## 🛑 防封锁策略

为了应对可能的 IP 封锁问题，项目内置了多种防护机制：

### 1. 智能请求伪装
- 随机 User-Agent 轮换
- 真实浏览器请求头模拟
- 随机请求延迟 (500-1500ms)

### 2. 自动重试机制
- 失败自动重试 (3 次)
- 指数退避算法
- 429/403 错误智能等待

### 3. 多端点支持
在 `docker-compose.yml` 中添加环境变量：
```yaml
environment:
  - DEEPINFRA_MIRRORS=https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions
```

### 4. 代理支持
配置 HTTP/HTTPS 代理：
```yaml
environment:
  - HTTP_PROXY=http://proxy-server:port
  - HTTPS_PROXY=http://proxy-server:port
```

### 5. Cloudflare 防护
- CDN 加速隐藏真实 IP
- DDoS 防护
- 智能防火墙
- Bot 检测绕过

此项目使用 Cloudflare 作为 CDN 和 SSL 提供商：

1. **SSL 证书**: 由 Cloudflare 自动管理，无需手动配置
2. **HTTPS 重定向**: 在 Cloudflare 控制面板中设置
3. **缓存策略**: 可选配置 API 响应缓存
4. **防护功能**: DDoS 防护、防火墙等

## 🔍 故障排除

### 服务启动失败
```bash
# 查看详细日志
docker compose logs deepinfra-proxy

# 检查端口占用
sudo netstat -tlnp | grep :80
```

### SSL 证书问题
此项目使用 Cloudflare 管理 SSL 证书，如遇到 HTTPS 问题：
```bash
# 检查 Cloudflare SSL 设置
# 1. 登录 Cloudflare 控制面板
# 2. 检查 SSL/TLS 设置
# 3. 确保加密模式为 "Flexible" 或 "Full"
```

### 网络连接问题
```bash
# 测试容器间网络
docker exec deepinfra-nginx ping deepinfra-proxy

# 测试后端服务
curl http://localhost:8000/health
```