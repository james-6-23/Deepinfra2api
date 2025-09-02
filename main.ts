#!/usr/bin/env -S deno run --allow-net
// 这是专为 Deno Deploy 平台优化的入口文件

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

// 类型定义
interface ChatMessage {
  role: string;
  content: string;
}

interface ChatRequest {
  model: string;
  messages: ChatMessage[];
  stream?: boolean;
  temperature?: number;
  max_tokens?: number;
}

interface Delta {
  content?: string | null;
  reasoning_content?: string | null;
}

interface Choice {
  delta: Delta;
}

interface StreamResponse {
  choices: Choice[];
}

const DEEPINFRA_URL = "https://api.deepinfra.com/v1/openai/chat/completions";

// ✅ 自定义 API Key（你控制）
const VALID_API_KEYS = ["linux.do"];

const SUPPORTED_MODELS = [
  { id: "openai/gpt-oss-120b", object: "model" },
  { id: "moonshotai/Kimi-K2-Instruct", object: "model" },
  { id: "zai-org/GLM-4.5", object: "model" },
  { id: "Qwen/Qwen3-Coder-480B-A35B-Instruct-Turbo", object: "model" },
  { id: "deepseek-ai/DeepSeek-R1-0528-Turbo", object: "model" },
  { id: "deepseek-ai/DeepSeek-V3-0324-Turbo", object: "model" },
  { id: "meta-llama/Llama-4-Maverick-17B-128E-Instruct-Turbo", object: "model" },
  {id: "deepseek-ai/DeepSeek-V3.1", object: "model" }

];

console.log(`✅ Proxy server starting...`);

// Deno Deploy 兼容的处理函数
async function handler(req: Request): Promise<Response> {
  const url = new URL(req.url);

  // ✅ 模型列表接口
  if (req.method === "GET" && url.pathname === "/v1/models") {
    return new Response(JSON.stringify({
      object: "list",
      data: SUPPORTED_MODELS
    }), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });
  }

  // ✅ Chat completions 接口
  if (req.method === "POST" && url.pathname === "/v1/chat/completions") {
    const body = await req.text();
    const headers = new Headers(req.headers);

    // ✅ 验证你自定义的 API Key
    const auth = headers.get("Authorization");
    const key = auth?.replace("Bearer ", "").trim();
    if (!key || !VALID_API_KEYS.includes(key)) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" }
      });
    }

    let parsed: ChatRequest;
    try {
      parsed = JSON.parse(body) as ChatRequest;
    } catch (error) {
      return new Response(JSON.stringify({ error: "Invalid JSON format" }), {
        status: 400,
        headers: { "Content-Type": "application/json" }
      });
    }
    const isStream = parsed.stream === true;

    // ✅ 构造伪造请求头（模拟匿名访问）
    const forwardHeaders: HeadersInit = {
      "Content-Type": "application/json",
      "User-Agent": "Mozilla/5.0",
      "Origin": "https://deepinfra.com",
      "Referer": "https://deepinfra.com/",
      "x-deepinfra-source": "web-page"
    };

    let response: Response;
    try {
      response = await fetch(DEEPINFRA_URL, {
        method: "POST",
        headers: forwardHeaders,
        body
      });
    } catch (error) {
      console.error('请求 DeepInfra API 失败:', error);
      return new Response(JSON.stringify({ error: "External API request failed" }), {
        status: 502,
        headers: { "Content-Type": "application/json" }
      });
    }

    if (!isStream) {
      const result = await response.text();
      return new Response(result, {
        status: response.status,
        headers: { "Content-Type": "application/json" }
      });
    }

    // ✅ 流式响应处理（SSE）
    const stream = new ReadableStream({
      async start(controller) {
        try {
          const reader = response.body?.getReader();
          if (!reader) {
            controller.close();
            return;
          }
          
          const decoder = new TextDecoder();
          let isInThinkBlock = false;
          let bufferedThinkContent = "";
          let streamClosed = false;

          while (true) {
            try {
              const { done, value } = await reader.read();
              if (done || streamClosed) break;
              
              const chunk = decoder.decode(value);
              const lines = chunk.split("\n");
              
              for (const line of lines) {
                if (streamClosed) break;
                
                if (line.startsWith("data: ")) {
                  const jsonText = line.slice(6).trim();
                  
                  if (jsonText === "[DONE]") {
                    // 处理流结束
                    if (isInThinkBlock && bufferedThinkContent) {
                      try {
                        const output = `data: ${JSON.stringify({ choices: [{ delta: { content: `<think>${bufferedThinkContent}</think>` } }] })}\n\n`;
                        controller.enqueue(new TextEncoder().encode(output));
                      } catch (e) {
                        console.warn('发送思考内容失败:', e);
                      }
                    }
                    
                    try {
                      controller.enqueue(new TextEncoder().encode("data: [DONE]\n\n"));
                    } catch (e) {
                      console.warn('发送 DONE 失败:', e);
                    }
                    streamClosed = true;
                    break;
                  }
                  
                  if (jsonText) {
                    try {
                      const parsed = JSON.parse(jsonText) as StreamResponse;
                      const delta = parsed.choices?.[0]?.delta;
                      
                      if (delta) {
                        let contentToSend: string | null = null;
                        
                        // 处理思考内容
                        if (delta.reasoning_content !== undefined && delta.reasoning_content !== null) {
                          if (delta.reasoning_content) {
                            bufferedThinkContent += delta.reasoning_content;
                          }
                          isInThinkBlock = true;
                        }
                        // 处理正常内容
                        else if (delta.content !== undefined && delta.content !== null) {
                          if (isInThinkBlock) {
                            // 发送思考内容
                            if (bufferedThinkContent) {
                              try {
                                const thinkOutput = `data: ${JSON.stringify({ choices: [{ delta: { content: `<think>${bufferedThinkContent}</think>` } }] })}\n\n`;
                                controller.enqueue(new TextEncoder().encode(thinkOutput));
                              } catch (e) {
                                console.warn('发送思考内容失败:', e);
                              }
                              bufferedThinkContent = "";
                            }
                            isInThinkBlock = false;
                          }
                          contentToSend = delta.content;
                        }
                        
                        // 发送正常内容
                        if (contentToSend !== null) {
                          try {
                            const output = `data: ${JSON.stringify({ choices: [{ delta: { content: contentToSend } }] })}\n\n`;
                            controller.enqueue(new TextEncoder().encode(output));
                          } catch (e) {
                            console.warn('发送内容失败:', e);
                            streamClosed = true;
                            break;
                          }
                        }
                      }
                    } catch (parseError) {
                      // 静默忽略 JSON 解析错误
                    }
                  }
                }
              }
            } catch (readError) {
              console.warn('读取数据失败:', readError);
              streamClosed = true;
              break;
            }
          }
        } catch (error) {
          console.error('流处理错误:', error);
        } finally {
          try {
            controller.close();
          } catch (closeError) {
            // 静默忽略关闭错误
          }
        }
      }
    });

    return new Response(stream, {
      status: 200,
      headers: {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive"
      }
    });
  }

  return new Response("Not Found", { status: 404 });
}

// 使用 Deno Deploy 推荐的方式启动服务器
serve(handler);