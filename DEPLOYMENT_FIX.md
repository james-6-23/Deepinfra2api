# Docker 部署问题修复方案

## 🔍 问题分析

**错误现象**：
```
failed to authorize: failed to fetch anonymous token: Get "https://auth.docker.io/token?scope=repository%3Adenoland%2Fdeno%3Apull&service=registry.docker.io": proxyconnect tcp: dial tcp: lookup deepinfra-warp on 183.60.83.19:53: no such host
```

**根本原因**：
1. Docker 在构建 `deepinfra-proxy` 镜像时，错误地尝试通过 `deepinfra-warp` 容器进行 DNS 解析
2. 构建阶段的网络配置与运行时网络配置冲突
3. DNS 服务器配置问题导致域名解析失败

## 🛠️ 已修复的文件

### 1. docker-compose.yml
**修改内容**：
- 在 `deepinfra-proxy` 服务的 `build` 配置中添加 `network: host`
- 这确保构建过程使用主机网络，避免 DNS 解析问题

### 2. Dockerfile
**修改内容**：
- 调整了环境变量设置顺序
- 添加了 `deno.json` 文件复制
- 优化了构建步骤

### 3. daemon.json（新增）
**用途**：修复 Docker daemon 的 DNS 配置
**位置**：需要复制到 `C:\ProgramData\docker\config\daemon.json`
**内容**：配置了可靠的 DNS 服务器（8.8.8.8, 8.8.4.4, 1.1.1.1）

### 4. .env（已创建）
**用途**：从 `.env.example` 复制的环境变量配置文件

## 🚀 部署步骤

### 步骤 1：安装 Docker daemon 配置
```bash
# Windows 系统
mkdir "C:\ProgramData\docker\config" 2>nul
copy daemon.json "C:\ProgramData\docker\config\daemon.json"

# Linux 系统
sudo mkdir -p /etc/docker
sudo cp daemon.json /etc/docker/daemon.json
```

### 步骤 2：重启 Docker 服务
```bash
# Windows (Docker Desktop)
# 右键 Docker Desktop 图标 -> Restart

# Linux
sudo systemctl restart docker
```

### 步骤 3：部署服务
```bash
# 方案 A：分步骤启动（推荐）
docker compose --profile warp up -d
# 等待 30 秒让 WARP 完全启动
docker compose --profile app up -d --build

# 方案 B：一次性启动
docker compose --profile warp --profile app up -d --build
```

### 步骤 4：验证部署
```bash
# 检查容器状态
docker compose ps

# 检查日志
docker compose logs -f

# 测试服务
curl http://localhost/health
```

## 🔧 故障排除

### 如果仍然出现 DNS 问题：
1. 检查 daemon.json 是否正确安装
2. 确认 Docker 服务已重启
3. 尝试清理 Docker 缓存：
   ```bash
   docker system prune -a
   ```

### 如果构建仍然失败：
1. 单独构建镜像：
   ```bash
   docker build -t deepinfra-proxy .
   ```
2. 然后启动服务：
   ```bash
   docker compose --profile warp --profile app up -d
   ```

### 网络连接测试：
```bash
# 测试容器间网络
docker exec deepinfra-nginx ping deepinfra-proxy

# 测试 WARP 代理
docker exec deepinfra-warp curl --socks5-hostname 127.0.0.1:1080 https://cloudflare.com/cdn-cgi/trace
```

## 📋 配置文件说明

- **docker-compose.yml**: 主要的服务编排配置，已修复构建网络问题
- **Dockerfile**: 应用镜像构建配置，已优化构建步骤
- **daemon.json**: Docker daemon DNS 配置，解决域名解析问题
- **.env**: 环境变量配置，控制服务行为
- **nginx.conf**: Nginx 反向代理配置，无需修改

## ✅ 预期结果

修复后，执行 `docker compose --profile warp --profile app up -d --build` 应该能够：
1. 成功拉取所有基础镜像
2. 成功构建 deepinfra-proxy 镜像
3. 启动所有服务容器
4. 通过 `docker ps` 看到运行中的容器
5. 通过 `curl http://localhost/health` 访问服务
