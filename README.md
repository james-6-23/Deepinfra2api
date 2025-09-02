# DeepInfra API 代理服务器

这是一个用 Deno 构建的 DeepInfra API 代理服务器，提供 OpenAI 兼容的接口。

## 功能特性

- 🔐 自定义 API Key 验证
- 📋 支持模型列表查询
- 💬 聊天完成接口（支持流式响应）
- 🧠 智能处理思考内容（reasoning_content）
- ☁️ 支持 Deno Deploy 部署

## 运行要求

- Deno 1.30+

## 本地开发

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

## Deno Deploy 部署

### 方法一：使用 main.ts（推荐）
1. 在 Deno Deploy 项目中设置入口点为 `main.ts`
2. 确保项目根目录包含 `deno.json` 配置文件
3. 直接部署，无需额外配置

### 方法二：使用 index.ts
1. 确保 `deno.json` 不包含 `allowJs` 选项
2. 服务器会自动使用环境变量 `PORT`
3. 在 Deno Deploy 项目设置中指定入口点为 `index.ts`

### 部署注意事项
- Deno Deploy 会自动提供 `PORT` 环境变量
- 不支持某些编译器选项（如 `allowJs`）
- 建议使用 `main.ts` 作为入口点以获得最佳兼容性

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