# DeepInfra2API - 用户自主配置版本

一个高性能的 DeepInfra API 代理服务，支持多端点负载均衡、智能故障转移和 WARP 代理。本版本采用**用户自主配置模式**，每个服务版本独立部署和配置。

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

- **OpenAI 兼容**：完全兼容 OpenAI API 格式，支持 `/v1/chat/completions` 和 `/v1/models` 接口
- **多端点支持**：支持多个 DeepInfra 端点的负载均衡和故障转移
- **双语言实现**：提供 Deno (TypeScript) 和 Go 两个版本，满足不同性能需求
- **流式响应**：支持 Server-Sent Events (SSE) 流式输出和完整的思考内容处理
- **性能模式**：提供 fast/balanced/secure 三种性能模式，平衡速度与安全性
- **WARP 代理**：可选的 Cloudflare WARP 代理支持，增强网络连接稳定性
- **隐私保护**：默认不记录用户消息和响应内容，保护用户隐私
- **容器化部署**：完整的 Docker Compose 配置，支持多 Profile 部署

## 🏗️ 分布式配置架构

### 架构设计
- **Go 版本**：`go-version/` - 高性能 Go 实现
- **Deno 版本**：`deno-version/` - 现代 TypeScript 实现
- **独立配置**：每个版本都有独立的 `.env.example` 和 `docker-compose.yml`
- **用户自主**：用户完全控制配置和部署流程

```
Deepinfra2api/
├── go-version/             # Go 版本（生产推荐）
│   ├── .env.example       # Go 版本配置模板
│   ├── docker-compose.yml # Go 版本 Docker 配置
│   ├── main.go            # 主应用文件
│   ├── go.mod             # Go 模块配置
│   └── Dockerfile         # Go 版本容器配置
├── deno-version/          # Deno 版本（开发推荐）
│   ├── .env.example       # Deno 版本配置模板
│   ├── docker-compose.yml # Deno 版本 Docker 配置
│   ├── app.ts             # 主应用文件
│   ├── deno.json          # Deno 配置
│   └── Dockerfile         # Deno 版本容器配置
├── verify-multi-endpoints.sh  # 多端点验证工具（可选）
├── test-workers-endpoints.sh  # Workers 端点测试工具（可选）
└── README.md              # 使用说明
```

## 🚀 快速开始

### 选择服务版本

#### Go 版本（推荐生产环境）
```bash
cd go-version
cp .env.example .env
# 编辑 .env 文件配置您的参数
docker compose up -d
```

#### Deno 版本（推荐开发环境）
```bash
cd deno-version
cp .env.example .env
# 编辑 .env 文件配置您的参数
docker compose up -d
```

### 基础配置步骤

1. **复制配置文件**
   ```bash
   cp .env.example .env
   ```

2. **编辑配置文件**
   ```bash
   nano .env
   # 至少修改以下配置：
   # VALID_API_KEYS=your-api-key
   # PORT=8001  # 或其他端口
   ```

3. **启动服务**
   ```bash
   docker compose up -d
   ```

4. **验证服务**
   ```bash
   curl http://localhost:8001/health
   ```
11. Go 高并发 + WARP (1000并发)
12. Go 高并发完整版 (3000并发)

### 🔄 双版本部署
13. 双版本基础部署
14. 双版本 + 多端点负载均衡
15. 双版本 + WARP 代理
16. 双版本 + 多端点 + WARP 代理

### 🛠️ 管理操作
17. 测试部署
18. 查看服务状态
19. 停止所有服务

## ⚡ 高并发版本特性

Go 高并发版本提供企业级性能：

| 版本 | 并发连接数 | 内存需求 | 适用场景 |
|------|-----------|----------|----------|
| 基础版 (选项9) | 1000 | 2GB | 中小型应用 |
| 多端点版 (选项10) | 2000 | 4GB | 中大型应用 |
| WARP版 (选项11) | 1000 | 2GB | 网络受限环境 |
| 完整版 (选项12) | 3000 | 6GB | 企业级应用 |

### 高并发版本功能
- 🔒 **并发控制**：智能连接数限制，防止系统过载
- 📊 **实时监控**：`/status` 端点提供系统状态监控
- 💾 **内存管理**：智能内存使用监控和限制
- 🛡️ **降级机制**：过载时优雅处理请求

## 🌐 WARP 代理验证

部署 WARP 代理版本后，使用以下方法验证：

### 自动验证
```bash
# 运行 WARP 代理验证脚本
./verify-warp-proxy.sh
```

### 手动验证
```bash
# 1. 检查 WARP 容器状态
docker ps | grep deepinfra-warp

# 2. 验证 WARP 代理功能
docker exec deepinfra-warp curl -s --socks5-hostname 127.0.0.1:1080 https://cloudflare.com/cdn-cgi/trace

# 3. 检查 IP 地址变化
echo "服务器IP: $(curl -s ifconfig.me)"
echo "WARP IP: $(docker exec deepinfra-warp curl -s --proxy socks5://localhost:1080 ifconfig.me)"

# 4. 测试 API 访问
curl -H "Authorization: Bearer linux.do" http://localhost:8001/v1/models
```

## 🔧 故障排除

### 常见问题

#### 1. WARP 代理部署失败
**问题**：Docker 构建时出现网络连接错误
```
failed to fetch anonymous token: proxyconnect tcp: dial tcp: lookup deepinfra-warp
```

**解决方案**：
- 脚本已自动修复此问题，采用分阶段部署策略
- 如仍有问题，选择非 WARP 版本（选项 5、6、10）

#### 2. 外部访问失败
**问题**：从外网无法访问云服务器上的服务

**解决方案**：
```bash
# 检查防火墙设置
sudo ufw allow 8001/tcp  # Go 版本
sudo ufw allow 8000/tcp  # Deno 版本

# 检查云服务商安全组设置
# 确保开放相应端口的入站规则
```

#### 3. 高并发版本性能问题
**问题**：高并发版本响应缓慢或连接被拒绝

**解决方案**：
```bash
# 检查系统状态
curl http://localhost:8001/status

# 调整并发配置（在 .env 文件中）
MAX_CONCURRENT_CONNECTIONS=2000
MEMORY_LIMIT_MB=4096

# 重启服务
docker compose restart deepinfra-proxy-go
```

#### 4. 流式响应截断
**问题**：长响应被提前截断

**解决方案**：
- 已在 Go 版本中修复超时机制
- 使用高并发版本获得更好的流式响应处理

### 日志查看
```bash
# 查看服务状态
docker compose ps

# 查看应用日志
docker compose logs -f deepinfra-proxy-go
docker compose logs -f deepinfra-proxy-deno

# 查看 WARP 代理日志
docker compose logs -f deepinfra-warp
```

## 📖 API 使用示例

### 获取模型列表
```bash
curl -H "Authorization: Bearer linux.do" \
     http://localhost:8001/v1/models
```

### 聊天完成（非流式）
```bash
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [
      {"role": "user", "content": "Hello, how are you?"}
    ],
    "max_tokens": 100
  }'
```

### 聊天完成（流式）
```bash
curl -X POST http://localhost:8001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [
      {"role": "user", "content": "Write a short story"}
    ],
    "stream": true,
    "max_tokens": 500
  }'
```

### 高并发版本状态监控
```bash
# 查看系统状态
curl http://localhost:8001/status

# 返回示例
{
  "current_connections": 245,
  "max_connections": 1000,
  "memory_usage_mb": 156,
  "memory_limit_mb": 2048,
  "total_requests": 12450,
  "error_count": 23
}
```

## ⚙️ 配置说明

### 环境变量配置

主要配置项（在 `.env` 文件中）：

```bash
# 基础配置
PORT=8001                           # 服务端口
VALID_API_KEYS=linux.do            # API 密钥

# 性能配置
PERFORMANCE_MODE=balanced           # fast/balanced/secure
MAX_RETRIES=3                      # 最大重试次数
REQUEST_TIMEOUT=120000             # 请求超时（毫秒）

# 高并发配置（高并发版本）
MAX_CONCURRENT_CONNECTIONS=1000    # 最大并发连接数
STREAM_TIMEOUT=300000              # 流式响应超时
MEMORY_LIMIT_MB=2048               # 内存限制

# WARP 代理配置
HTTP_PROXY=http://deepinfra-warp:1080
HTTPS_PROXY=http://deepinfra-warp:1080

# 多端点配置
DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions
```

### 性能模式说明

| 模式 | 重试次数 | 超时时间 | 随机延迟 | 适用场景 |
|------|----------|----------|----------|----------|
| fast | 1 | 10秒 | 0-100ms | 快速响应 |
| balanced | 3 | 2分钟 | 100-500ms | 平衡性能 |
| secure | 5 | 1分钟 | 500-1500ms | 高可靠性 |

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 开发环境设置
```bash
# 克隆项目
git clone https://github.com/your-repo/deepinfra2api.git
cd deepinfra2api

# 开发模式启动
./quick-start.sh
# 选择相应的开发版本
```

### 提交规范
- 🐛 修复 bug
- ✨ 新功能
- 📚 文档更新
- 🔧 配置修改
- ⚡ 性能优化

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## ⚠️ 免责声明

本项目仅供学习和研究使用。使用者需要：
- 遵守当地法律法规
- 遵守相关服务提供商的使用条款
- 自行承担使用风险
- 获得必要的商业使用授权

---

**🌟 如果这个项目对您有帮助，请给个 Star！**

### 方式一：快速启动脚本（推荐）

最简单的部署方式，提供交互式菜单和自动化配置：

```bash
# 1. 克隆项目
git clone https://github.com/james-6-23/DeepInfra2API.git
cd DeepInfra2API

# 2. 运行快速启动脚本
chmod +x quick-start.sh
./quick-start.sh
```

**脚本功能特色**：
- 🎯 **15种部署选项**：涵盖 Deno/Go/双版本 × 基础/多端点/WARP/多端点+WARP 的所有组合
- 🔌 **智能端口管理**：自动检测端口冲突，支持自动分配或手动指定可用端口
- 🔄 **循环交互菜单**：支持连续操作，无需重复运行脚本
- 🧪 **内置测试功能**：一键测试部署结果，包括健康检查、API调用验证
- 📊 **实时状态监控**：显示服务状态、日志查看、容器管理
- ⚙️ **自动环境配置**：自动创建和更新 .env 配置文件

**快速启动脚本菜单选项**：

```
🎯 请选择部署方案:

📦 Deno 版本部署 (端口 8000) - 推荐用于开发
  1) Deno 基础版
  2) Deno + 多端点负载均衡  
  3) Deno + WARP 代理
  4) Deno + 多端点 + WARP 代理

🐹 Go 版本部署 (端口 8001) - 推荐用于生产
  5) Go 基础版
  6) Go + 多端点负载均衡
  7) Go + WARP 代理
  8) Go + 多端点 + WARP 代理

🔄 双版本部署
  9) 双版本基础部署
  10) 双版本 + 多端点负载均衡
  11) 双版本 + WARP 代理
  12) 双版本 + 多端点 + WARP 代理

🛠️ 管理操作
  13) 测试部署
  14) 查看服务状态
  15) 停止所有服务
```

### 方式二：Docker Compose 部署

根据项目规范，用户偏好直接使用 Docker Compose 进行部署：

```bash
# 1. 克隆项目
git clone https://github.com/james-6-23/DeepInfra2API.git
cd DeepInfra2API

# 2. 复制配置模板
cp .env.example .env

# 3. 编辑配置（可选，默认配置即可使用）
nano .env

# 4. 选择部署方式

# 启动 Deno 版本（适合开发环境）
docker compose --profile deno up -d --build

# 启动 Go 版本（适合生产环境）
docker compose --profile go up -d --build

# 启动双版本对比测试
docker compose --profile deno --profile go up -d --build

# 启动完整配置（双版本 + WARP 代理）
docker compose --profile warp --profile deno --profile go up -d --build
```

### 方式三：分步启动（避免跨 Profile 依赖）

当存在服务依赖关系时，应采用分步启动策略：

```bash
# 1. 先启动基础服务（WARP 代理）
docker compose --profile warp up -d --build

# 2. 等待 WARP 服务完全运行
docker compose logs -f warp
# 看到 "WARP tunnel connected" 类似信息后继续

# 3. 启动应用服务
docker compose --profile deno up -d --build
# 或
docker compose --profile go up -d --build
```

### 方式四：独立部署

```bash
# Deno 版本独立部署
cd deno-version
docker compose up -d --build

# Go 版本独立部署
cd go-version
docker compose up -d --build
```

## 🔧 API 使用指南

### 健康检查

```bash
# Deno 版本
curl http://localhost:8000/health

# Go 版本  
curl http://localhost:8001/health
```

### 获取模型列表

```bash
curl -H "Authorization: Bearer linux.do" \
     http://localhost:8000/v1/models
```

### 单轮对话

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [
      {"role": "user", "content": "你好，世界！"}
    ]
  }'
```

### 多轮对话

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1", 
    "messages": [
      {"role": "user", "content": "我想学习 Docker"},
      {"role": "assistant", "content": "Docker 是一个容器化平台，可以帮助你打包和部署应用。"},
      {"role": "user", "content": "能给我一个简单的例子吗？"}
    ]
  }'
```

### 流式对话

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-V3.1",
    "messages": [
      {"role": "user", "content": "请写一首关于技术的诗"}
    ],
    "stream": true,
    "temperature": 0.8
  }'
```

### 参数详解

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `model` | string | 必填 | 模型名称，见支持的模型列表 |
| `messages` | array | 必填 | 对话消息数组 |
| `stream` | boolean | false | 是否启用流式输出 |
| `temperature` | number | 0.7 | 创造性控制 (0.0-2.0，越高越有创意) |
| `max_tokens` | number | - | 最大输出 token 数量 |
| `top_p` | number | 1.0 | 核采样参数 (0.0-1.0) |
| `frequency_penalty` | number | 0.0 | 频率惩罚 (-2.0-2.0) |
| `presence_penalty` | number | 0.0 | 存在惩罚 (-2.0-2.0) |

### 消息角色说明

| 角色 | 说明 | 使用场景 |
|------|------|----------|
| `system` | 系统消息 | 设定 AI 的行为、角色和规则 |
| `user` | 用户消息 | 用户的问题、请求或指令 |
| `assistant` | AI 回复 | AI 的历史回复（用于上下文） |

### 不同模型使用示例

#### 推理模型 (DeepSeek-R1)
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-R1-0528-Turbo",
    "messages": [
      {"role": "user", "content": "解决这个数学问题：如果 x + 2y = 10 且 2x - y = 5，求 x 和 y 的值"}
    ],
    "temperature": 0.1
  }'
```

#### 代码生成 (Qwen-Coder)
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "Qwen/Qwen3-Coder-480B-A35B-Instruct-Turbo",
    "messages": [
      {"role": "user", "content": "写一个 Python 函数来计算斐波那契数列"}
    ],
    "temperature": 0.2
  }'
```

## 💻 编程语言示例

### Python 示例

#### 安装依赖
```bash
pip install requests openai
```

#### 基础对话
```python
import requests
import json

def chat_with_deepinfra(message, api_key="linux.do", base_url="http://localhost:8000"):
    """基础对话示例"""
    url = f"{base_url}/v1/chat/completions"

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }

    data = {
        "model": "deepseek-ai/DeepSeek-V3.1",
        "messages": [
            {"role": "user", "content": message}
        ],
        "temperature": 0.7,
        "max_tokens": 1000
    }

    try:
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        result = response.json()
        return result["choices"][0]["message"]["content"]
    except requests.exceptions.RequestException as e:
        return f"请求失败: {e}"
    except KeyError as e:
        return f"响应格式错误: {e}"

# 使用示例
if __name__ == "__main__":
    message = "你好，请介绍一下你自己"
    reply = chat_with_deepinfra(message)
    print(f"AI: {reply}")
```

#### 使用 OpenAI SDK
```python
import openai

# 配置客户端
client = openai.OpenAI(
    api_key="linux.do",
    base_url="http://localhost:8000/v1"
)

def chat_with_openai_sdk(message, model="deepseek-ai/DeepSeek-V3.1"):
    """使用 OpenAI SDK 进行对话"""
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "user", "content": message}
            ],
            temperature=0.7
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"对话失败: {e}"

# 使用示例
reply = chat_with_openai_sdk("什么是人工智能？")
print(f"AI: {reply}")
```

#### 流式对话
```python
import openai

client = openai.OpenAI(
    api_key="linux.do",
    base_url="http://localhost:8000/v1"
)

def stream_chat(message, model="deepseek-ai/DeepSeek-V3.1"):
    """流式对话示例"""
    try:
        stream = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": message}],
            stream=True,
            temperature=0.8
        )

        print("AI: ", end="", flush=True)
        for chunk in stream:
            if chunk.choices[0].delta.content is not None:
                print(chunk.choices[0].delta.content, end="", flush=True)
        print()  # 换行

    except Exception as e:
        print(f"流式对话失败: {e}")

# 使用示例
stream_chat("请给我讲一个关于编程的故事")
```

#### 多轮对话类
```python
class ChatBot:
    def __init__(self, api_key="linux.do", base_url="http://localhost:8000/v1"):
        self.client = openai.OpenAI(api_key=api_key, base_url=base_url)
        self.messages = []

    def set_system_prompt(self, prompt):
        """设置系统提示词"""
        self.messages = [{"role": "system", "content": prompt}]

    def chat(self, user_input, model="deepseek-ai/DeepSeek-V3.1"):
        """发送消息并获取回复"""
        self.messages.append({"role": "user", "content": user_input})

        try:
            response = self.client.chat.completions.create(
                model=model,
                messages=self.messages,
                temperature=0.7
            )

            assistant_reply = response.choices[0].message.content
            self.messages.append({"role": "assistant", "content": assistant_reply})

            return assistant_reply
        except Exception as e:
            return f"对话失败: {e}"

    def clear_history(self):
        """清除对话历史"""
        system_messages = [msg for msg in self.messages if msg["role"] == "system"]
        self.messages = system_messages

# 使用示例
bot = ChatBot()
bot.set_system_prompt("你是一个专业的编程助手，请用简洁明了的语言回答问题。")

print(bot.chat("什么是 Python？"))
print(bot.chat("请给我一个简单的例子"))
print(bot.chat("如何处理异常？"))
```

### JavaScript/Node.js 示例

#### 安装依赖
```bash
npm install openai axios
```

#### 基础对话
```javascript
const OpenAI = require('openai');

const client = new OpenAI({
  apiKey: 'linux.do',
  baseURL: 'http://localhost:8000/v1'
});

async function chatWithAI(message, model = 'deepseek-ai/DeepSeek-V3.1') {
  try {
    const response = await client.chat.completions.create({
      model: model,
      messages: [{ role: 'user', content: message }],
      temperature: 0.7
    });

    return response.choices[0].message.content;
  } catch (error) {
    console.error('对话失败:', error);
    return null;
  }
}

// 使用示例
chatWithAI('你好，请介绍一下你自己').then(reply => {
  console.log('AI:', reply);
});
```

#### 流式对话
```javascript
async function streamChat(message, model = 'deepseek-ai/DeepSeek-V3.1') {
  try {
    const stream = await client.chat.completions.create({
      model: model,
      messages: [{ role: 'user', content: message }],
      stream: true,
      temperature: 0.8
    });

    process.stdout.write('AI: ');
    for await (const chunk of stream) {
      const content = chunk.choices[0]?.delta?.content;
      if (content) {
        process.stdout.write(content);
      }
    }
    console.log(); // 换行
  } catch (error) {
    console.error('流式对话失败:', error);
  }
}

// 使用示例
streamChat('请给我讲一个关于 JavaScript 的故事');
```
    
    try:
        response = requests.post(url, headers=headers, json=data, timeout=60)
        response.raise_for_status()
        
        result = response.json()
        return result["choices"][0]["message"]["content"]
        
    except requests.exceptions.RequestException as e:
        print(f"请求错误: {e}")
        return None
    except KeyError as e:
        print(f"响应格式错误: {e}")
        return None

# 使用示例
if __name__ == "__main__":
    response = chat_with_deepinfra("解释一下什么是 API 代理")
    if response:
        print("AI 回复:", response)
```

#### 流式对话

```python
import requests
import json

def stream_chat_with_deepinfra(message, api_key="linux.do", base_url="http://localhost:8000"):
    """流式对话示例"""
    url = f"{base_url}/v1/chat/completions"
    
    headers = {
        "Content-Type": "application/json", 
        "Authorization": f"Bearer {api_key}"
    }
    
    data = {
        "model": "deepseek-ai/DeepSeek-V3.1",
        "messages": [
            {"role": "user", "content": message}
        ],
        "stream": True,
        "temperature": 0.7
    }
    
    try:
        response = requests.post(url, headers=headers, json=data, stream=True, timeout=60)
        response.raise_for_status()
        
        print("AI 回复:", end=" ", flush=True)
        
        for line in response.iter_lines():
            if line:
                line = line.decode('utf-8')
                if line.startswith('data: '):
                    data_str = line[6:]  # 移除 'data: ' 前缀
                    
                    if data_str.strip() == '[DONE]':
                        break
                        
                    try:
                        data_obj = json.loads(data_str)
                        if 'choices' in data_obj and data_obj['choices']:
                            delta = data_obj['choices'][0].get('delta', {})
                            content = delta.get('content', '')
                            if content:
                                print(content, end='', flush=True)
                    except json.JSONDecodeError:
                        continue
        
        print()  # 换行
        
    except requests.exceptions.RequestException as e:
        print(f"请求错误: {e}")

# 使用示例
if __name__ == "__main__":
    stream_chat_with_deepinfra("请详细介绍 Docker 的核心概念")
```

### JavaScript/Node.js 示例

```javascript
const axios = require('axios');

class DeepInfraClient {
    constructor(apiKey = 'linux.do', baseUrl = 'http://localhost:8000') {
        this.apiKey = apiKey;
        this.baseUrl = baseUrl;
        this.client = axios.create({
            baseURL: baseUrl,
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json'
            },
            timeout: 60000
        });
    }

    async chat(messages, model = 'deepseek-ai/DeepSeek-V3.1', options = {}) {
        try {
            const response = await this.client.post('/v1/chat/completions', {
                model,
                messages,
                ...options
            });
            
            return response.data.choices[0].message.content;
        } catch (error) {
            console.error('对话请求失败:', error.message);
            return null;
        }
    }
}

// 使用示例
async function main() {
    const client = new DeepInfraClient();
    
    const response = await client.chat([
        { role: 'user', content: '解释一下什么是 RESTful API' }
    ]);
    
    if (response) {
        console.log(response);
    }
}

main().catch(console.error);
```

## 📋 配置说明

### 环境变量配置

复制 `.env.example` 为 `.env` 并根据需要修改：

```bash
cp .env.example .env
```

#### 基础配置

```bash
# 服务配置
PORT=8000                                  # 服务端口
DOMAIN=deepinfra.kyx03.de                  # 域名（可选）

# API 密钥配置（逗号分隔多个密钥）
VALID_API_KEYS=linux.do

# 多端点配置（可选，逗号分隔）
DEEPINFRA_MIRRORS=https://api.deepinfra.com/v1/openai/chat/completions,https://api1.deepinfra.com/v1/openai/chat/completions
```

#### 性能模式配置

```bash
# 性能与安全平衡配置
PERFORMANCE_MODE=balanced  # 选项: fast, balanced, secure

# 平衡模式配置 (默认)
MAX_RETRIES=3                              # 最大重试次数
RETRY_DELAY=1000                           # 重试延迟（毫秒）
REQUEST_TIMEOUT=30000                      # 请求超时（毫秒）
RANDOM_DELAY_MIN=100                       # 最小随机延迟（毫秒）
RANDOM_DELAY_MAX=500                       # 最大随机延迟（毫秒）
```

#### WARP 代理配置

```bash
# WARP 配置（可选）
WARP_ENABLED=true                          # 启用 WARP 服务
# WARP_LICENSE_KEY=your-warp-plus-key      # WARP+ 许可证密钥（可选）

# 代理配置（当启用 WARP profile 时生效）
# HTTP_PROXY=http://deepinfra-warp:1080
# HTTPS_PROXY=http://deepinfra-warp:1080
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

## 🛠️ 快速启动脚本详细指南

### 脚本功能详解

**端口管理功能**：
- 🔍 自动检测端口冲突，支持 netstat、ss、lsof 等多种检测方式
- 🔢 自动分配可用端口（从 8000 开始扫描）
- ✏️ 手动指定端口（支持 1024-65535 范围验证）
- 📊 显示端口状态和占用情况

**部署配置功能**：
- 🌐 自动配置单端点或多端点负载均衡
- 🔒 WARP 代理集成，增强网络连接稳定性
- ⚙️ 自动更新 .env 环境变量配置
- 🔄 支持双版本同时部署进行对比测试

**测试与监控功能**：
- 🧪 一键测试部署结果，包括健康检查、模型列表、聊天 API
- 📊 实时显示服务状态和容器信息
- 📄 提供详细的日志查看命令
- 🛡️ 故障排除建议和解决方案

### 使用最佳实践

**新手用户推荐流程**：
```bash
# 1. 首次使用，选择简单配置
./quick-start.sh
# 选择: 1) Deno 基础版 或 5) Go 基础版

# 2. 测试部署是否成功
# 选择: 13) 测试部署

# 3. 如果需要更高稳定性，升级到多端点配置
# 选择: 2) Deno + 多端点 或 6) Go + 多端点
```

**生产环境推荐流程**：
```bash
# 1. 生产环境推荐使用 Go 版本 + 多端点 + WARP
./quick-start.sh
# 选择: 8) Go + 多端点 + WARP 代理

# 2. 等待 WARP 启动完成（约 30 秒）
# 选择: 14) 查看服务状态

# 3. 测试所有功能
# 选择: 13) 测试部署
```

**开发环境推荐流程**：
```bash
# 1. 开发环境优先选择 Deno 版本
./quick-start.sh
# 选择: 1) Deno 基础版

# 2. 如需对比测试，启动双版本
# 选择: 9) 双版本基础部署

# 3. 实时监控开发进度
# 选择: 14) 查看服务状态
```

### 常用操作命令

**直接命令启动**（绕过交互菜单）：
```bash
# 快速启动 Deno 基础版
echo "1" | ./quick-start.sh

# 快速启动 Go + 多端点 + WARP
echo "8" | ./quick-start.sh

# 快速测试部署
echo "13" | ./quick-start.sh
```

**管理命令**：
```bash
# 查看所有服务状态
docker compose ps

# 查看实时日志
docker compose logs -f deepinfra-proxy-deno
docker compose logs -f deepinfra-proxy-go
docker compose logs -f deepinfra-warp

# 停止所有服务
docker compose down

# 重启特定服务
docker compose restart deepinfra-proxy-go
```

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

# 停止所有服务
docker compose down
```

## 🔍 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 检查端口占用
   netstat -tuln | grep 8000
   # 修改 .env 文件中的端口配置
   
   # 或使用快速启动脚本的自动端口分配功能
   ./quick-start.sh
   # 选择任意部署选项，脚本会自动检测并解决端口冲突
   ```

2. **API 密钥无效**
   ```bash
   # 检查 .env 文件中的 VALID_API_KEYS 配置
   cat .env | grep VALID_API_KEYS
   
   # 使用快速启动脚本测试 API 密钥
   ./quick-start.sh
   # 选择: 13) 测试部署 - 会自动测试 API 调用
   ```

3. **容器启动失败**
   ```bash
   # 查看日志
   docker compose logs -f
   
   # 使用快速启动脚本查看状态
   ./quick-start.sh
   # 选择: 14) 查看服务状态
   ```

4. **快速启动脚本权限问题**
   ```bash
   # 给脚本添加执行权限
   chmod +x quick-start.sh
   
   # 如果仍然无法执行，检查文件格式
   file quick-start.sh
   # 应该显示为 POSIX shell script
   
   # Windows 用户在 Git Bash 或 WSL 中运行
   bash quick-start.sh
   ```

5. **WARP 代理连接失败**
   ```bash
   # 检查 WARP 服务状态
   docker compose logs deepinfra-warp
   
   # 重启 WARP 服务
   docker compose restart deepinfra-warp
   
   # 等待 30-60 秒让 WARP 完全启动
   # 使用快速启动脚本测试
   ./quick-start.sh
   # 选择: 13) 测试部署
   ```

### 网络连接问题
```bash
# 测试容器间网络
docker exec deepinfra-proxy-deno curl -f http://localhost:8000/health
docker exec deepinfra-proxy-go curl -f http://localhost:8000/health

# 测试 WARP 代理
docker exec deepinfra-warp curl --socks5-hostname 127.0.0.1:1080 https://cloudflare.com/cdn-cgi/trace

# 使用快速启动脚本进行自动测试
./quick-start.sh
# 选择: 13) 测试部署 - 包含完整的网络连接测试
```

### 性能问题排查
```bash
# 使用快速启动脚本查看资源使用
./quick-start.sh
# 选择: 14) 查看服务状态

# 手动查看资源使用
docker stats deepinfra-proxy-deno deepinfra-proxy-go deepinfra-warp

# 查看详细性能指标
docker exec deepinfra-proxy-go curl -s http://localhost:8000/health | jq .
```

### 快速启动脚本故障排除

**脚本无法运行**：
```bash
# 检查系统兼容性
# Linux/macOS:
bash --version

# Windows 用户需要使用 Git Bash 或 WSL
# 在 Git Bash 中运行:
bash quick-start.sh

# 在 WSL 中运行:
wsl bash quick-start.sh
```

**端口检测失败**：
```bash
# 脚本依赖以下工具之一：netstat, ss, lsof, nc
# Ubuntu/Debian 安装:
sudo apt-get install net-tools

# CentOS/RHEL 安装:
sudo yum install net-tools

# macOS 安装:
brew install netcat
```

**Docker 命令失败**：
```bash
# 检查 Docker 是否正常运行
docker --version
docker compose version

# 检查 Docker 服务状态
sudo systemctl status docker

# 启动 Docker 服务
sudo systemctl start docker
```

## 📄 最佳实践

### 初学者推荐流程

**第一次使用**：
1. 使用快速启动脚本进行初始部署
2. 选择 Deno 基础版进行学习和测试
3. 使用内置测试功能验证部署结果
4. 通过编程语言示例学习 API 调用

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
4. 使用快速启动脚本的双版本部署进行对比测试

### 部署方式选择指南

| 场景 | 推荐方式 | 原因 |
|------|----------|------|
| 初学者 | 快速启动脚本 | 交互式菜单，降低学习门槛 |
| 开发者 | Docker Compose | 精确控制，适合调试 |
| 运维人员 | 独立部署 | 简化的生产环境管理 |
| CI/CD | Docker Compose | 适合脚本化和自动化 |

### 错误处理
- 实现重试机制处理临时网络问题
- 监控 API 密钥有效性
- 设置合理的超时时间
- 记录详细的错误信息用于调试
- 使用快速启动脚本的测试功能定期验证服务状态

### 性能优化
- 根据负载选择合适的性能模式
- 使用多端点分散请求负载
- 适当调整重试参数和延迟设置
- 监控响应时间和错误率
- 使用快速启动脚本进行双版本性能对比

### 监控和维护

**日常监控**：
```bash
# 使用快速启动脚本进行定期检查
./quick-start.sh
# 选择: 13) 测试部署
# 选择: 14) 查看服务状态

# 手动监控命令
watch -n 30 'curl -s http://localhost:8000/health | jq .'
watch -n 30 'curl -s http://localhost:8001/health | jq .'
```

**资源监控**：
```bash
# 查看资源使用情况
docker stats deepinfra-proxy-deno deepinfra-proxy-go deepinfra-warp

# 查看磁盘使用
docker system df

# 清理无用资源
docker system prune -f
```

**安全维护**：
```bash
# 定期更新镜像
docker compose pull
docker compose up -d --build

# 检查安全漏洞
docker scout cves deepinfra2api-deno
docker scout cves deepinfra2api-go
```

## ⚖️ 法律声明

### 使用条款
1. **技术学习目的**：本项目专为技术学习、研究和教学而设计
2. **合规责任**：用户需自行确保使用行为符合相关法律法规
3. **风险自担**：使用本项目产生的任何后果由用户自行承担
4. **无担保声明**：本项目按"原样"提供，不提供任何明示或暗示的担保

## 🔍 故障排除

### 常见问题

#### 1. 连接失败
```bash
# 检查服务是否启动
curl http://localhost:8000/health

# 检查端口是否被占用
netstat -tlnp | grep :8000  # Linux
netstat -an | findstr :8000  # Windows
```

#### 2. API Key 无效
```bash
# 检查 API Key 配置
echo $VALID_API_KEYS

# 测试 API Key
curl -H "Authorization: Bearer linux.do" http://localhost:8000/health
```

#### 3. 模型不支持
```bash
# 查看支持的模型列表
curl http://localhost:8000/v1/models
```

#### 4. 流式响应中断
- **Deno 版本**: 通常稳定，如有问题检查网络连接
- **Go 版本 v2.0**: 已优化解决截断问题，如仍有问题请检查客户端实现

### 日志查看

#### Docker 部署
```bash
# 查看 Deno 版本日志
cd deno-version && docker-compose logs -f

# 查看 Go 版本日志
cd go-version && docker-compose logs -f

# 查看双版本日志
docker-compose logs -f
```

#### 直接运行
- Deno 版本：控制台直接输出
- Go 版本：控制台直接输出，支持结构化日志

## 🎯 最佳实践

### 生产环境建议

1. **选择合适的版本**
   - 开发/测试：Deno 版本（开发体验好）
   - 生产环境：Go 版本 v2.0（性能和稳定性更佳）

2. **性能模式配置**
   ```bash
   # 开发环境
   PERFORMANCE_MODE=fast

   # 生产环境
   PERFORMANCE_MODE=balanced

   # 高稳定性要求
   PERFORMANCE_MODE=secure
   ```

3. **API Key 管理**
   ```bash
   # 使用强密码
   VALID_API_KEYS=your-strong-key-1,your-strong-key-2

   # 定期轮换密钥
   ```

4. **监控和日志**
   ```bash
   # 启用详细日志
   ENABLE_DETAILED_LOGGING=true

   # 定期检查健康状态
   watch -n 30 'curl -s http://localhost:8000/health'
   ```

### 客户端最佳实践

1. **错误处理**
   - 始终包装 API 调用在 try-catch 中
   - 实现重试机制
   - 处理网络超时

2. **流式响应**
   - 使用 Go 版本 v2.0 获得最佳稳定性
   - 实现连接断开重连
   - 正确处理 [DONE] 标记

3. **性能优化**
   - 复用 HTTP 连接
   - 合理设置超时时间
   - 避免频繁的短连接

## 📊 性能基准

### 响应时间对比

| 场景 | Deno 版本 | Go 版本 v2.0 |
|------|-----------|--------------|
| 简单对话 | ~800ms | ~600ms |
| 长文本生成 | ~2000ms | ~1500ms |
| 流式响应 | 稳定 | 优化增强 |
| 并发处理 | 良好 | 卓越 |

### 资源使用

| 指标 | Deno 版本 | Go 版本 v2.0 |
|------|-----------|--------------|
| 内存占用 | ~50MB | ~15MB |
| CPU 使用 | 中等 | 低 |
| 启动时间 | ~2s | ~0.5s |
| Docker 镜像 | ~100MB | ~20MB |

## 🔄 更新日志

### v2.0.0 - 2025-01-02
- ✨ Go 版本重大优化，解决流式响应截断问题
- 🔧 数据块读取策略替代按行读取
- 🛡️ 增强错误恢复和安全数据发送
- ⚡ 动态缓冲区优化和连接状态检测
- 📊 完善的监控和日志系统

### v1.0.0 - 2024-12-20
- 🎉 初始版本发布
- 🦕 Deno/TypeScript 实现
- 🐹 Go 语言实现
- 🐳 Docker 容器化支持
- 💬 完整的 OpenAI 兼容 API

### 免责声明
- 本项目开发者不对使用本项目导致的任何直接或间接损失承担责任
- 用户应当基于自己的判断和风险评估来使用本项目
- 如因使用本项目违反第三方权利或相关法规，责任由用户自负

## 🤝 贡献

欢迎贡献代码、报告问题或提出改进建议！

### 贡献流程
1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 开发指南
- 遵循现有代码风格
- 添加适当的测试
- 更新相关文档
- 确保所有测试通过

## 📞 联系与支持

如果这个项目对你有帮助，请给它一个 ⭐️！

**技术交流**：
- **项目地址**: https://github.com/james-6-23/Deepinfra2api
- **问题反馈**: https://github.com/james-6-23/Deepinfra2api/issues
- **功能请求**: https://github.com/james-6-23/Deepinfra2api/discussions
- **技术讨论**: 通过 GitHub Issues 讨论技术问题

**注意**：我们只提供技术支持，不提供使用方面的法律建议。

## 📄 许可证

MIT License

## 🙏 致谢

- 感谢 [DeepInfra](https://deepinfra.com/) 提供优秀的 AI 模型服务
- 感谢 [Deno](https://deno.land/) 和 [Go](https://golang.org/) 社区
- 感谢所有贡献者和用户的支持

---

🚀 **Happy Coding!** 由 [Deno](https://deno.land/) + [Go](https://golang.org/) + [Docker](https://www.docker.com/) 强力驱动

**最终提醒**：使用本项目即表示您已充分理解并同意上述所有条款。请在合规的前提下，将其作为学习和研究工具使用。
