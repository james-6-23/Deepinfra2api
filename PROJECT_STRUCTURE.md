# 项目结构说明

## 📁 目录结构

```
Deepinfra2api/
├── deno-version/              # Deno/TypeScript 版本
│   ├── app.ts                # 主应用文件
│   ├── deno.json             # Deno 配置
│   └── Dockerfile            # Deno 版本 Docker 配置
├── go-version/               # Go 版本
│   ├── main.go               # 主应用文件
│   ├── go.mod                # Go 模块配置
│   └── Dockerfile            # Go 版本 Docker 配置
├── docker-compose.yml        # 统一的 Docker Compose 配置
├── .env                      # 环境变量配置
├── .env.example              # 环境变量配置模板
├── quick-start.sh            # 快速启动脚本
├── test-deployment.sh        # 自动化测试脚本
├── DEPLOYMENT_GUIDE.md       # 详细部署指南
├── README.md                 # 项目说明文档
└── PROJECT_STRUCTURE.md      # 本文件
```

## 🎯 版本说明

### Deno 版本 (`deno-version/`)
- **语言**: TypeScript
- **端口**: 8000
- **特点**: 现代化开发体验，适合快速开发
- **启动**: `docker compose --profile deno up -d --build`

### Go 版本 (`go-version/`)
- **语言**: Go
- **端口**: 8001
- **特点**: 高性能，低内存占用，适合生产环境
- **启动**: `docker compose --profile go up -d --build`

## 🚀 快速开始

1. **复制配置文件**:
   ```bash
   cp .env.example .env
   ```

2. **选择启动方式**:
   ```bash
   # 使用快速启动脚本（推荐）
   chmod +x quick-start.sh
   ./quick-start.sh
   
   # 或手动启动
   docker compose --profile deno up -d --build  # Deno 版本
   docker compose --profile go up -d --build    # Go 版本
   ```

3. **测试部署**:
   ```bash
   chmod +x test-deployment.sh
   ./test-deployment.sh
   ```

## 📚 文档说明

- **README.md**: 项目概述和基本使用说明
- **DEPLOYMENT_GUIDE.md**: 详细的部署指南，包含所有配置选项
- **PROJECT_STRUCTURE.md**: 本文件，项目结构说明

## 🔧 配置文件

- **.env**: 运行时环境变量配置
- **docker-compose.yml**: Docker 服务编排配置，支持多种 profile
- **deno-version/deno.json**: Deno 运行时配置
- **go-version/go.mod**: Go 模块依赖配置

## 🛠️ 工具脚本

- **quick-start.sh**: 交互式快速启动脚本
- **test-deployment.sh**: 自动化测试脚本，验证部署是否成功

## 🌐 服务端点

### Deno 版本 (端口 8000)
- 健康检查: `http://localhost:8000/health`
- 模型列表: `http://localhost:8000/v1/models`
- 聊天接口: `http://localhost:8000/v1/chat/completions`

### Go 版本 (端口 8001)
- 健康检查: `http://localhost:8001/health`
- 模型列表: `http://localhost:8001/v1/models`
- 聊天接口: `http://localhost:8001/v1/chat/completions`

## 🎛️ Docker Profiles

- `deno`: 启动 Deno 版本
- `go`: 启动 Go 版本
- `warp`: 启动 WARP 代理（可与其他 profile 组合）

组合示例：
```bash
docker compose --profile warp --profile deno --profile go up -d --build
```
