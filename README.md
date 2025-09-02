# DeepInfra API 代理服务器

🚀 一个用 Deno + Docker + Nginx 构建的 DeepInfra API 代理服务器，提供 OpenAI 兼容的接口。

## ✨ 功能特性

- 🔐 自定义 API Key 验证
- 📋 支持模型列表查询
- 💬 聊天完成接口（支持流式响应）
- 🧠 智能处理思考内容（reasoning_content）
- 🐳 Docker 容器化部署
- 🔒 Nginx 反向代理
- 🌐 CORS 跨域支持
- 📊 健康检查接口
- 🚀 多端点负载均衡
- 🛡️ 反封锁机制（WARP 代理）
- ⚡ 性能模式配置

## 🚀 快速部署

### 方法一：直接使用 Docker Compose（推荐）

```bash
# 1. 复制配置文件
cp .env.example .env

# 2. 编辑配置（可选）
nano .env  # 或使用其他编辑器

# 3. 启动基础模式（仅 API 代理）
docker compose --profile app up -d --build

# 或启动完整模式（包含 WARP 代理）
docker compose --profile warp --profile app up -d --build
```

### 方法二：手动步骤

```bash
# 1. 查看服务状态
docker compose ps

# 2. 查看日志
docker compose logs -f

# 3. 测试服务
curl http://localhost/health
```

## 📋 部署前准备

### 1. 环境配置
复制并修改环境变量文件：
```bash
cp .env.example .env
vim .env  # 或使用其他编辑器
```

主要配置项：
- `DOMAIN`: 你的域名 
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

## 🌐 API 接口使用指南

### 🎆 健康检查
```bash
# HTTP (本地测试)
curl http://deepinfra.kyx03.de/health

# HTTPS (通过 Cloudflare)
curl https://deepinfra.kyx03.de/health
```

### 📋 获取模型列表
```bash
# 基础请求
curl https://deepinfra.kyx03.de/v1/models

# 带 API Key
curl -H "Authorization: Bearer linux.do" https://deepinfra.kyx03.de/v1/models
```

### 💬 聊天对话使用指南

#### 🚀 基础对话示例

**单轮对话**：
```bash
curl -X POST https://deepinfra.kyx03.de/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [
      {"role": "user", "content": "你好，请介绍一下你自己"}
    ],
    "stream": false,
    "temperature": 0.7,
    "max_tokens": 1000
  }'
```

**多轮对话**：
```bash
curl -X POST https://deepinfra.kyx03.de/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [
      {"role": "system", "content": "你是一个专业的编程助手"},
      {"role": "user", "content": "请帮我写一个 Python 函数来计算斐波那契数列"},
      {"role": "assistant", "content": "好的，我来帮你写一个斐波那契数列的函数..."},
      {"role": "user", "content": "请加上详细的注释和错误处理"}
    ],
    "stream": false,
    "temperature": 0.3
  }'
```

#### 🌊 流式对话示例

**实时流式输出**：
```bash
curl -X POST https://deepinfra.kyx03.de/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-R1-0528-Turbo",
    "messages": [
      {"role": "user", "content": "请给我讲一个关于人工智能发展的故事"}
    ],
    "stream": true,
    "temperature": 0.8,
    "max_tokens": 2000
  }'
```

#### 🛠️ 不同模型使用示例

**中文对话** (GLM-4.5)：
```bash
curl -X POST https://deepinfra.kyx03.de/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "zai-org/GLM-4.5",
    "messages": [
      {"role": "user", "content": "请用中文解释一下量子计算的基本原理"}
    ],
    "stream": false
  }'
```

**代码生成** (Qwen-Coder)：
```bash
curl -X POST https://deepinfra.kyx03.de/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "Qwen/Qwen3-Coder-480B-A35B-Instruct-Turbo",
    "messages": [
      {"role": "user", "content": "写一个 React 组件，实现一个可以搜索和筛选的用户列表"}
    ],
    "stream": false,
    "temperature": 0.2
  }'
```

**推理任务** (DeepSeek-R1)：
```bash
curl -X POST https://deepinfra.kyx03.de/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-R1-0528-Turbo",
    "messages": [
      {"role": "user", "content": "在一个 8x8 的棋盘上，你有 8 个相同的车子。你需要将它们放置在棋盘上，使得任意两个车子都不能相互攻击。请问有多少种不同的放置方法？"}
    ],
    "stream": false,
    "temperature": 0.1
  }'
```

#### 📊 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `model` | string | 必填 | 模型名称 |
| `messages` | array | 必填 | 对话消息列表 |
| `stream` | boolean | false | 是否流式输出 |
| `temperature` | number | 0.7 | 随机性 (0.0-2.0) |
| `max_tokens` | number | - | 最大输出长度 |
| `top_p` | number | 1.0 | 核采样 (0.0-1.0) |
| `frequency_penalty` | number | 0.0 | 频率惩罚 (-2.0-2.0) |
| `presence_penalty` | number | 0.0 | 存在惩罚 (-2.0-2.0) |

#### 📝 消息角色说明

| 角色 | 说明 | 使用场景 |
|------|------|----------|
| `system` | 系统消息 | 设定 AI 的行为和角色 |
| `user` | 用户消息 | 用户的问题或请求 |
| `assistant` | AI 回复 | AI 的历史回复（用于上下文） |

#### 🔄 响应格式

**非流式响应**：
```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1677652288,
  "model": "deepseek-ai/DeepSeek-V3.1",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "你好！我是..."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 9,
    "completion_tokens": 12,
    "total_tokens": 21
  }
}
```

**流式响应**：
```
data: {"choices": [{"delta": {"content": "你"}}]}

data: {"choices": [{"delta": {"content": "好"}}]}

data: {"choices": [{"delta": {"content": "！"}}]}

data: [DONE]
```

## 💻 编程语言使用示例

### 🐍 Python 示例

**安装依赖**：
```bash
pip install openai  # 或 pip install requests
```

**使用 OpenAI SDK**：
```python
import openai

# 配置 API
client = openai.OpenAI(
    api_key="linux.do",
    base_url="https://deepinfra.kyx03.de/v1"
)

# 单轮对话
response = client.chat.completions.create(
    model="deepseek-ai/DeepSeek-V3.1",
    messages=[
        {"role": "user", "content": "你好，请介绍一下你自己"}
    ],
    temperature=0.7
)

print(response.choices[0].message.content)

# 流式对话
stream = client.chat.completions.create(
    model="deepseek-ai/DeepSeek-V3.1",
    messages=[
        {"role": "user", "content": "请给我讲一个故事"}
    ],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content is not None:
        print(chunk.choices[0].delta.content, end="")
```

**使用 requests 库**：
```python
import requests
import json

def chat_with_ai(message, model="deepseek-ai/DeepSeek-V3.1"):
    url = "https://deepinfra.kyx03.de/v1/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer linux.do"
    }
    data = {
        "model": model,
        "messages": [{"role": "user", "content": message}],
        "stream": False
    }
    
    response = requests.post(url, headers=headers, json=data)
    if response.status_code == 200:
        return response.json()["choices"][0]["message"]["content"]
    else:
        return f"错误: {response.status_code} - {response.text}"

# 使用示例
result = chat_with_ai("你好，请解释一下机器学习")
print(result)
```

### 🔥 JavaScript/Node.js 示例

**安装依赖**：
```bash
npm install openai  # 或 yarn add openai
```

**使用 OpenAI SDK**：
```javascript
import OpenAI from 'openai';

const client = new OpenAI({
  apiKey: 'linux.do',
  baseURL: 'https://deepinfra.kyx03.de/v1'
});

// 异步对话
async function chatWithAI(message) {
  try {
    const response = await client.chat.completions.create({
      model: 'deepseek-ai/DeepSeek-V3.1',
      messages: [{ role: 'user', content: message }],
      temperature: 0.7
    });
    
    return response.choices[0].message.content;
  } catch (error) {
    console.error('请求失败:', error);
    return null;
  }
}

// 流式对话
async function streamChat(message) {
  try {
    const stream = await client.chat.completions.create({
      model: 'deepseek-ai/DeepSeek-V3.1',
      messages: [{ role: 'user', content: message }],
      stream: true
    });
    
    for await (const chunk of stream) {
      const content = chunk.choices[0]?.delta?.content;
      if (content) {
        process.stdout.write(content);
      }
    }
  } catch (error) {
    console.error('流式请求失败:', error);
  }
}

// 使用示例
chatWithAI('你好，请介绍一下人工智能').then(console.log);
streamChat('请给我讲一个关于AI的故事');
```

### 🤖 多轮对话示例

**Python 多轮对话类**：
```python
class ChatBot:
    def __init__(self, api_key="linux.do", base_url="https://deepinfra.kyx03.de/v1"):
        self.client = openai.OpenAI(api_key=api_key, base_url=base_url)
        self.messages = []
        
    def set_system_prompt(self, prompt):
        """设置系统提示词"""
        self.messages = [{"role": "system", "content": prompt}]
        
    def chat(self, user_input, model="deepseek-ai/DeepSeek-V3.1"):
        """发送消息并获取回复"""
        self.messages.append({"role": "user", "content": user_input})
        
        response = self.client.chat.completions.create(
            model=model,
            messages=self.messages,
            temperature=0.7
        )
        
        assistant_reply = response.choices[0].message.content
        self.messages.append({"role": "assistant", "content": assistant_reply})
        
        return assistant_reply
    
    def clear_history(self):
        """清除对话历史"""
        self.messages = [msg for msg in self.messages if msg["role"] == "system"]

# 使用示例
bot = ChatBot()
bot.set_system_prompt("你是一个专业的编程助手，请用简洁明了的语言回答问题。")

print(bot.chat("什么是 Python？"))
print(bot.chat("请给我一个简单的例子"))
print(bot.chat("如何处理异常？"))
```

### 🌐 前端网页示例

**HTML + JavaScript**：
```html
<!DOCTYPE html>
<html>
<head>
    <title>DeepInfra 聊天机器人</title>
    <style>
        .chat-container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .message { margin: 10px 0; padding: 10px; border-radius: 5px; }
        .user-message { background: #e3f2fd; text-align: right; }
        .bot-message { background: #f1f8e9; }
        #input { width: 80%; padding: 10px; }
        #send { padding: 10px 20px; }
    </style>
</head>
<body>
    <div class="chat-container">
        <div id="messages"></div>
        <input type="text" id="input" placeholder="输入你的消息...">
        <button id="send">发送</button>
    </div>

    <script>
        const messagesDiv = document.getElementById('messages');
        const input = document.getElementById('input');
        const sendBtn = document.getElementById('send');
        
        async function sendMessage() {
            const message = input.value.trim();
            if (!message) return;
            
            // 显示用户消息
            addMessage(message, 'user');
            input.value = '';
            
            try {
                const response = await fetch('https://deepinfra.kyx03.de/v1/chat/completions', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer linux.do'
                    },
                    body: JSON.stringify({
                        model: 'deepseek-ai/DeepSeek-V3.1',
                        messages: [{ role: 'user', content: message }],
                        stream: false
                    })
                });
                
                const data = await response.json();
                const reply = data.choices[0].message.content;
                addMessage(reply, 'bot');
            } catch (error) {
                addMessage('抱歉，发生了错误：' + error.message, 'bot');
            }
        }
        
        function addMessage(text, sender) {
            const div = document.createElement('div');
            div.className = `message ${sender}-message`;
            div.textContent = text;
            messagesDiv.appendChild(div);
            messagesDiv.scrollTop = messagesDiv.scrollHeight;
        }
        
        sendBtn.addEventListener('click', sendMessage);
        input.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') sendMessage();
        });
    </script>
</body>
</html>
```

## 🔧 配置说明

### 📝 环境变量配置
所有配置都通过 `.env` 文件管理，主要配置项：

```bash
# 服务配置
DOMAIN=your.domain.com     # 你的域名
PORT=8000                      # 后端服务端口
NGINX_PORT=80                  # Nginx 端口

# Docker 容器配置
BACKEND_HOST= deepinfra-proxy   # 后端容器名
BACKEND_PORT=8000              # 后端容器端口

# API Key 配置
VALID_API_KEYS=  # API 密钥（逗号分隔多个）

# 多端点配置（可选）
DEEPINFRA_MIRRORS=url1,url2,url3  # 镜像端点（逗号分隔）

# 性能模式
PERFORMANCE_MODE=balanced      # fast/balanced/secure

# 高级配置
MAX_RETRIES=3                  # 最大重试次数
RETRY_DELAY=1000              # 重试延迟(ms)
REQUEST_TIMEOUT=30000         # 请求超时(ms)

# WARP 代理配置
WARP_ENABLED=true             # 是否启用 WARP
WARP_LICENSE_KEY=your-key     # WARP+ 许可证(可选)
```

### 📊 部署模式
支持两种部署模式：

1. **基础模式**: 仅部署 API 代理服务
   ```bash
   docker compose --profile app up -d --build
   ```

2. **完整模式**: 包含 WARP 代理，更强的反封锁能力
   ```bash
   docker compose --profile warp --profile app up -d --build
   ```

### 🎆 性能模式
支持三种性能模式：

| 模式 | 延迟增加 | 安全性 | 适用场景 |
|------|----------|--------|----------|
| **fast** | +0-100ms | 低 | 开发测试、速度优先 |
| **balanced** | +100-500ms | 中 | 生产环境推荐 |
| **secure** | +500-1500ms | 高 | 高风险环境、安全优先 |

### 🌐 多端点配置
支持多个 API 端点进行负载均衡和故障转移：

```bash
# 在 .env 文件中配置
DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions
```

工作原理：
- 🔄 **顺序尝试**: 按配置顺序依次尝试每个端点
- 🚑 **故障转移**: 当前端点失败时自动切换到下一个
- 🔁 **重试机制**: 每个端点都有独立的重试次数
- ⏱️ **智能等待**: 遇到限流错误时会增加等待时间

### 🚀 支持的模型
当前支持以下模型：

| 模型名称 | 类型 | 描述 |
|------------|------|------|
| `deepseek-ai/DeepSeek-V3.1` | 通用 | DeepSeek 最新模型 |
| `deepseek-ai/DeepSeek-R1-0528-Turbo` | 推理 | 推理能力强化版本 |
| `openai/gpt-oss-120b` | 通用 | GPT 开源模型 |
| `zai-org/GLM-4.5` | 中文 | GLM 中文优化模型 |
| `zai-org/GLM-4.5-Air` | 中文 | GLM 轻量版 |
| `moonshotai/Kimi-K2-Instruct` | 通用 | Kimi 指令调优模型 |
| `Qwen/Qwen3-Coder-480B-A35B-Instruct-Turbo` | 代码 | 通义千问代码模型 |
| `meta-llama/Llama-4-Maverick-17B-128E-Instruct-Turbo` | 通用 | Llama 4 指令模型 |

## 📊 管理命令

### 日常管理
```bash
# 查看服务状态
docker compose ps

# 查看所有日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f deepinfra-proxy
docker compose logs -f nginx
docker compose logs -f warp

# 重启服务
docker compose restart

# 停止服务
docker compose down

# 更新服务
docker compose down
docker compose --profile app up -d --build
```

### 故障排查
```bash
# 查看容器详细信息
docker compose ps -a

# 查看资源使用情况
docker stats

# 进入容器调试
docker exec -it deepinfra-proxy sh
docker exec -it deepinfra-nginx sh

# 测试内部网络
docker exec deepinfra-nginx ping deepinfra-proxy

# 测试后端服务
curl http://localhost:8000/health
```

## 🛠️ 本地开发

## 🛫️ 本地开发

```bash
# 安装 Deno
curl -fsSL https://deno.land/install.sh | sh

# 运行开发服务器
deno task dev

# 或直接运行（需要网络和环境变量权限）
deno run --allow-net --allow-env app.ts

# Windows 系统下安装 Deno
iwr https://deno.land/install.ps1 -useb | iex
```

## 📁 项目结构

```
.
├── app.ts              # 主应用文件（唯一 TypeScript 文件）
├── docker-compose.yml  # Docker Compose 配置
├── Dockerfile          # Docker 构建文件
├── nginx.conf          # Nginx 反向代理配置
├── deno.json           # Deno 运行时配置
├── .env.example        # 环境变量配置模板
├── .dockerignore       # Docker 忽略文件
├── .gitignore          # Git 忽略文件
└── README.md           # 项目说明文档
```

### 🔍 文件说明

## 🛡️ 防封锁策略

为了应对可能的 IP 封锁问题，项目内置了多种防护机制：

### 1. 智能请求伪装
- 随机 User-Agent 轮换
- 真实浏览器请求头模拟
- 随机请求延迟 (100-1500ms)

### 2. 自动重试机制
- 失败自动重试 (1-5 次)
- 指数退避算法
- 429/403 错误智能等待

### 3. 多端点支持
在 `.env` 文件中配置：
```bash
DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions,https://api2.deepinfra.com/v1/openai/chat/completions
```

### 4. WARP 代理支持
使用 Cloudflare WARP 隐藏真实 IP：
```bash
# 启用 WARP 代理
WARP_ENABLED=true
WARP_LICENSE_KEY=your-warp-plus-key  # 可选，提高速度

# 运行完整模式
docker compose --profile warp --profile app up -d --build
```

### 5. Cloudflare 防护
项目使用 Cloudflare 作为 CDN 和 SSL 提供商：
- **SSL 证书**: 由 Cloudflare 自动管理
- **HTTPS 重定向**: 在 Cloudflare 控制面板中设置
- **DDoS 防护**: 自动开启
- **Bot 检测绕过**: 智能防火墙

## 🔍 故障排除

### 服务启动失败
```bash
# 查看详细日志
docker compose logs deepinfra-proxy

# 检查端口占用
netstat -tlnp | grep :80
# Windows 下
netstat -an | findstr :80
```

### SSL 证书问题
此项目使用 Cloudflare 管理 SSL 证书，如遇到 HTTPS 问题：
1. 登录 Cloudflare 控制面板
2. 检查 SSL/TLS 设置
3. 确保加密模式为 "Flexible" 或 "Full"

### 网络连接问题
```bash
# 测试容器间网络
docker exec deepinfra-nginx ping deepinfra-proxy

# 测试后端服务
curl http://localhost:8000/health

# 检查 WARP 状态
docker exec deepinfra-warp curl --socks5-hostname 127.0.0.1:1080 https://cloudflare.com/cdn-cgi/trace
```

### API 请求失败
```bash
# 检查 API Key 配置
echo $VALID_API_KEYS

# 测试健康检查
curl -H "Authorization: Bearer your-api-key" http://localhost/health

# 查看错误日志
docker compose logs deepinfra-proxy | grep ERROR
```

## 🎆 最佳实践

### 生产环境部署
```bash
# 1. 使用强密码的 API Key
VALID_API_KEYS=complex-key-1,complex-key-2

# 2. 启用多端点和 WARP
PERFORMANCE_MODE=balanced
DEEPINFRA_MIRRORS=url1,url2,url3
WARP_ENABLED=true

# 3. 限制访问 IP（在 Cloudflare 中配置）
```

### 性能优化
```bash
# 快速模式（开发环境）
PERFORMANCE_MODE=fast
WARP_ENABLED=false

# 安全模式（高风险环境）
PERFORMANCE_MODE=secure
WARP_ENABLED=true
WARP_LICENSE_KEY=your-warp-plus-key
```

### 监控和日志
```bash
# 定期检查服务状态
watch -n 30 'curl -s http://localhost/health | jq .'

# 日志轮转（避免日志文件过大）
docker compose logs --tail=1000 -f
```

## 🎉 更新日志

### v2.0.0 - 2025-01-03
- ✨ 简化项目结构，保留单一 TypeScript 文件
- 🚀 移除部署脚本依赖，直接使用 Docker Compose
- 🛡️ 集成 Cloudflare WARP 反封锁机制
- 🌐 支持多端点负载均衡和故障转移
- ⚡ 添加三种性能模式（fast/balanced/secure）
- 📊 优化错误处理和日志输出
- 📁 更新文档和使用说明

### v1.0.0 - 2024-12-20
- 🎉 初始版本发布
- 🚀 DeepInfra API 代理基础功能
- 🐳 Docker 容器化部署
- 💬 支持流式和非流式响应

## 🤝 贡献

欢迎贡献代码、报告问题或提出改进建议！

1. Fork 这个仓库
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 📜 许可证

该项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 📞 支持

如果你觉得这个项目有用，请给它一个 ⭐️！

有问题或需要帮助？请在 [Issues](https://github.com/your-username/deepinfra2api/issues) 中提出。

---

🚀 **Happy Coding!** 由 [Deno](https://deno.land/) + [Docker](https://www.docker.com/) + [Cloudflare](https://www.cloudflare.com/) 驱动

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