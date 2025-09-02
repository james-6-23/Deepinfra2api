import json
import httpx
import uvicorn
from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse, StreamingResponse
from starlette.exceptions import HTTPException

DEEPINFRA_URL = "https://api.deepinfra.com/v1/openai/chat/completions"
PORT = 8000

# ✅ 自定义 API Key（你控制）
VALID_API_KEYS = {"linux.do"}

# ✅ 支持的模型列表
SUPPORTED_MODELS = [
    {"id": "openai/gpt-oss-120b", "object": "model"},
    {"id": "moonshotai/Kimi-K2-Instruct", "object": "model"},
    {"id": "zai-org/GLM-4.5", "object": "model"},
    {"id": "Qwen/Qwen3-Coder-480B-A35B-Instruct-Turbo", "object": "model"},
    {"id": "deepseek-ai/DeepSeek-R1-0528-Turbo", "object": "model"},
    {"id": "deepseek-ai/DeepSeek-V3-0324-Turbo", "object": "model"},
    {"id": "meta-llama/Llama-4-Maverick-17B-128E-Instruct-Turbo", "object": "model"},
]

# --- FastAPI 应用实例 ---
app = FastAPI()

# --- 路由定义 ---

@app.get("/v1/models")
async def list_models():
    """
    ✅ 模型列表接口
    返回支持的模型列表，与 OpenAI 的 /v1/models 接口格式兼容。
    """
    return JSONResponse(content={"object": "list", "data": SUPPORTED_MODELS})


@app.post("/v1/chat/completions")
async def chat_completions(request: Request):
    """
    ✅ Chat completions 接口
    代理请求到 DeepInfra，并处理流式和非流式响应。
    """
    # ✅ 验证你自定义的 API Key
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    key = auth_header.replace("Bearer ", "").strip()
    if key not in VALID_API_KEYS:
        raise HTTPException(status_code=401, detail="Unauthorized")

    # 获取原始请求体
    body_bytes = await request.body()
    try:
        body_json = json.loads(body_bytes)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON body")
        
    is_stream = body_json.get("stream", False)

    # ✅ 构造伪造请求头（模拟匿名访问）
    forward_headers = {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0",
        "Origin": "https://deepinfra.com",
        "Referer": "https://deepinfra.com/",
        "x-deepinfra-source": "web-page",
    }
    
    # 使用 httpx 异步转发请求
    async with httpx.AsyncClient() as client:
        try:
            # 使用 timeout=None 来支持长时间的流式连接
            response = await client.post(
                DEEPINFRA_URL,
                headers=forward_headers,
                content=body_bytes,
                timeout=None
            )
        except httpx.RequestError as e:
            raise HTTPException(status_code=500, detail=f"Error forwarding request: {e}")

    # --- 响应处理 ---
    
    # 1. 非流式响应
    if not is_stream:
        return Response(
            content=response.content,
            status_code=response.status_code,
            media_type="application/json"
        )
        
    # 2. ✅ 流式响应处理 (SSE)
    async def stream_generator():
        # 状态变量，用于合并连续的 think 块
        is_in_think_block = False
        buffered_think_content = ""
        
        # httpx 的 aiter_lines() 完美对应 Deno 的按行读取
        async for line in response.aiter_lines():
            if line.startswith("data: "):
                json_text = line[6:]
                
                if json_text == "[DONE]":
                    # 处理流结束：如果有缓存的思考内容，先发送
                    if is_in_think_block and buffered_think_content:
                        output = f'data: {json.dumps({"choices": [{"delta": {"content": f"<think>{buffered_think_content}</think>"}}]})}\n\n'
                        yield output
                        buffered_think_content = ""
                        is_in_think_block = False
                    break # 结束循环

                try:
                    parsed = json.loads(json_text)
                    delta = parsed.get("choices", [{}])[0].get("delta", {})

                    content_to_send = None
                    
                    # 检查是否是思考内容 (reasoning_content)
                    if delta.get("reasoning_content") is not None:
                        # 如果是思考内容，先缓冲起来，不立即发送
                        if delta["reasoning_content"]:
                            buffered_think_content += delta["reasoning_content"]
                        # 标记当前处于思考块中
                        is_in_think_block = True
                        
                    # 检查是否是正常内容 (content) 且当前不在思考块中
                    elif delta.get("content") is not None and not is_in_think_block:
                        content_to_send = delta["content"]
                        
                    # 如果遇到正常内容，但当前在思考块中，说明思考块结束
                    elif delta.get("content") is not None and is_in_think_block:
                        # 先发送已缓冲的思考内容
                        if buffered_think_content:
                            think_output = f'data: {json.dumps({"choices": [{"delta": {"content": f"<think>{buffered_think_content}</think>"}}]})}\n\n'
                            yield think_output
                            buffered_think_content = ""
                            is_in_think_block = False
                        
                        # 然后准备发送正常内容
                        content_to_send = delta["content"]

                    # 发送非思考内容
                    if content_to_send is not None:
                        output = f'data: {json.dumps({"choices": [{"delta": {"content": content_to_send}}]})}\n\n'
                        yield output
                        
                except (json.JSONDecodeError, IndexError):
                    # 忽略解析错误或数据结构不符的行
                    continue

        # 再次确保所有缓冲的内容都已发送
        if is_in_think_block and buffered_think_content:
            output = f'data: {json.dumps({"choices": [{"delta": {"content": f"<think>{buffered_think_content}</think>"}}]})}\n\n'
            yield output

        # 发送最后的 [DONE] 标记
        yield "data: [DONE]\n\n"

    return StreamingResponse(
        stream_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive"
        }
    )

if __name__ == "__main__":
    print(f"✅ Proxy server running at http://127.0.0.1:{PORT}")
    uvicorn.run(app, host="0.0.0.0", port=PORT)