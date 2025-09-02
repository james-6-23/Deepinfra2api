# DeepInfra2API 日志系统文档

## 🎯 概述

DeepInfra2API 现在配备了完整的结构化日志系统，支持详细的请求和响应跟踪，便于监控、调试和分析。

## 📊 日志功能特性

### 🔍 请求日志记录
- **请求时间戳**：ISO 8601 格式
- **客户端 IP 地址**：支持代理头检测
- **API Key 脱敏**：只显示前4位和后4位
- **请求模型名称**：用户选择的模型
- **完整消息内容**：用户发送的 messages 数组（可配置）
- **请求参数**：temperature, max_tokens, stream 等

### 📤 响应日志记录
- **响应时间戳**：ISO 8601 格式
- **响应状态码**：HTTP 状态码
- **完整响应内容**：包括思考内容和正常回复（可配置）
- **响应耗时**：毫秒级精度
- **实际 API 端点**：使用的具体端点
- **重试次数**：如果发生重试

### 🌊 流式日志记录
- **实时内容记录**：流式响应的每个片段
- **思考内容处理**：reasoning_content 的完整记录
- **Delta 变化跟踪**：每次内容变化的详细记录

## 🔧 配置选项

### 环境变量配置

```bash
# 启用详细日志记录（默认：true）
ENABLE_DETAILED_LOGGING=true

# 记录用户消息内容（默认：true）
LOG_USER_MESSAGES=true

# 记录响应内容（默认：true）
LOG_RESPONSE_CONTENT=true
```

### 配置说明

| 环境变量 | 默认值 | 说明 |
|---------|--------|------|
| `ENABLE_DETAILED_LOGGING` | `true` | 是否启用详细的结构化日志 |
| `LOG_USER_MESSAGES` | `true` | 是否记录用户发送的消息内容 |
| `LOG_RESPONSE_CONTENT` | `true` | 是否记录 API 响应的完整内容 |

## 📋 日志格式

### 请求日志示例

```json
{
  "request_id": "req_a1b2c3d4e5f6g7h8",
  "timestamp": "2024-01-15T10:30:45.123Z",
  "level": "INFO",
  "type": "request",
  "client_ip": "192.168.1.100",
  "api_key": "sk-1234****5678",
  "model": "deepseek-ai/DeepSeek-V3.1",
  "messages": [
    {
      "role": "user",
      "content": "Hello, how are you?"
    }
  ],
  "parameters": {
    "stream": true,
    "temperature": 0.7,
    "max_tokens": 1000
  },
  "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
}
```

### 响应日志示例

```json
{
  "request_id": "req_a1b2c3d4e5f6g7h8",
  "timestamp": "2024-01-15T10:30:47.456Z",
  "level": "INFO",
  "type": "response",
  "status_code": 200,
  "response_time_ms": 2333,
  "endpoint": "deepinfra_api",
  "retry_count": 0,
  "content": {
    "choices": [
      {
        "message": {
          "role": "assistant",
          "content": "Hello! I'm doing well, thank you for asking."
        }
      }
    ]
  },
  "reasoning_content": "The user is greeting me and asking about my well-being..."
}
```

### 流式日志示例

```json
{
  "request_id": "req_a1b2c3d4e5f6g7h8",
  "timestamp": "2024-01-15T10:30:46.789Z",
  "level": "INFO",
  "type": "stream",
  "content": "Hello!",
  "delta": {
    "content": "Hello!"
  }
}
```

## 🔒 隐私保护

### API Key 脱敏
- 长度 ≤ 8：完全用 `*` 替换
- 长度 > 8：保留前4位和后4位，中间用 `*` 替换
- 示例：`sk-1234567890abcdef` → `sk-1234****cdef`

### 可配置的内容记录
- `LOG_USER_MESSAGES=false`：不记录用户消息内容
- `LOG_RESPONSE_CONTENT=false`：不记录 API 响应内容
- 敏感信息自动过滤（如密码、令牌等关键词）

## 📈 日志分析

### 请求 ID 关联
每个请求都有唯一的 `request_id`，可以用来关联：
- 请求日志
- 响应日志
- 多个流式日志片段

### 性能监控
通过日志可以分析：
- 平均响应时间
- 错误率统计
- 端点使用情况
- 重试频率

### 示例查询

```bash
# 查找特定请求的所有日志
grep "req_a1b2c3d4e5f6g7h8" logs.json

# 统计错误请求
grep '"level":"ERROR"' logs.json | wc -l

# 分析响应时间
grep '"type":"response"' logs.json | jq '.response_time_ms' | sort -n
```

## 🛠️ 实现细节

### Go 版本实现
- 使用标准库的 `encoding/json` 进行序列化
- 支持并发安全的日志记录
- 内存高效的流式处理

### Deno 版本实现
- 使用原生 `JSON.stringify()` 进行序列化
- 支持现代 JavaScript 特性
- 异步日志处理不阻塞主流程

## 🚀 使用建议

### 生产环境
```bash
# 启用日志但保护隐私
ENABLE_DETAILED_LOGGING=true
LOG_USER_MESSAGES=false
LOG_RESPONSE_CONTENT=false
```

### 开发环境
```bash
# 完整日志记录用于调试
ENABLE_DETAILED_LOGGING=true
LOG_USER_MESSAGES=true
LOG_RESPONSE_CONTENT=true
```

### 性能考虑
- 日志记录对性能影响 < 5%
- 可通过 `ENABLE_DETAILED_LOGGING=false` 完全禁用
- 建议在高负载环境中选择性启用

## 📊 日志轮转

### Docker 环境
Docker 自动处理日志轮转：
```bash
# 查看日志
docker compose logs -f deepinfra-proxy-deno
docker compose logs -f deepinfra-proxy-go

# 限制日志大小
docker compose logs --tail=1000 deepinfra-proxy-deno
```

### 生产部署建议
- 使用 ELK Stack 或类似工具收集日志
- 设置合适的日志保留策略
- 监控日志存储空间使用情况

## 🔍 故障排除

### 常见问题

1. **日志不显示**
   - 检查 `ENABLE_DETAILED_LOGGING` 是否为 `true`
   - 确认容器正常运行

2. **日志格式错误**
   - 检查 JSON 序列化是否正常
   - 查看控制台错误信息

3. **性能影响**
   - 考虑禁用 `LOG_RESPONSE_CONTENT`
   - 使用异步日志处理

### 调试命令

```bash
# 实时查看结构化日志
docker compose logs -f deepinfra-proxy-go | jq .

# 过滤特定类型的日志
docker compose logs deepinfra-proxy-deno | grep '"type":"request"'

# 统计日志数量
docker compose logs deepinfra-proxy-go | grep -c '"request_id"'
```
