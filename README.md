# DeepInfra API 代理服务器

这是一个用 Deno 构建的 DeepInfra API 代理服务器，提供 OpenAI 兼容的接口。

## 功能特性

- 🔐 自定义 API Key 验证
- 📋 支持模型列表查询
- 💬 聊天完成接口（支持流式响应）
- 🧠 智能处理思考内容（reasoning_content）

## 运行要求

- Deno 1.30+

## 安装运行

### 开发模式（自动重启）
```bash
deno task dev
```

### 生产模式
```bash
deno task start
```

### 手动运行
```bash
deno run --allow-net index.ts
```

## API 使用

### 1. 获取模型列表
```bash
curl http://localhost:8000/v1/models
```

### 2. 聊天完成
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -d '{
    "model": "deepseek-ai/DeepSeek-R1-0528-Turbo",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": false
  }'
```

## 配置

- **端口**: 8000 (可在 index.ts 中修改)
- **API Key**: "linux.do" (可在 VALID_API_KEYS 数组中修改)
- **支持的模型**: 见代码中 SUPPORTED_MODELS 数组

## 注意事项

- 确保网络连接正常，能访问 DeepInfra API
- 代理服务器会自动处理思考内容，包装在 `<think>` 标签中