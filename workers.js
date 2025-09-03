// DeepInfra API 代理 - 优化版 Cloudflare Workers
// 支持负载均衡、错误处理、安全性和性能优化

// 配置常量
const CONFIG = {
  // 目标 API 服务器
  TARGET_HOST: 'api.deepinfra.com',
  
  // 支持的路径前缀
  SUPPORTED_PATHS: ['/v1/'],
  
  // 认证配置（可选）
  AUTH_ENABLED: false,
  AUTH_TOKEN: 'Bearer your-secret-token',
  
  // 请求头设置
  USER_AGENTS: [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0'
  ],
  
  // 超时设置（毫秒）
  TIMEOUT: 30000,
  
  // 最大重定向次数
  MAX_REDIRECTS: 3,
  
  // 响应大小限制（字节）
  MAX_RESPONSE_SIZE: 50 * 1024 * 1024, // 50MB
  
  // 是否启用 CORS
  ENABLE_CORS: true,
  
  // 是否启用压缩
  ENABLE_COMPRESSION: true
};

// 需要移除的请求头
const HEADERS_TO_REMOVE = [
  'host',
  'cf-ray',
  'cf-visitor',
  'cf-connecting-ip',
  'cf-ipcountry',
  'cf-request-id',
  'cf-cache-status',
  'x-real-ip',
  'x-forwarded-for',
  'x-forwarded-proto',
  'x-forwarded-host',
  'x-forwarded-port',
  'x-original-forwarded-for'
];

// 需要移除的响应头
const RESPONSE_HEADERS_TO_REMOVE = [
  'server',
  'x-powered-by',
  'cf-ray',
  'cf-cache-status',
  'expect-ct',
  'report-to',
  'nel'
];

// 需要保留的响应头
const HEADERS_TO_KEEP = [
  'content-type',
  'content-length',
  'content-encoding',
  'transfer-encoding',
  'connection',
  'cache-control',
  'expires',
  'etag',
  'last-modified',
  'pragma',
  'vary',
  'access-control-allow-origin',
  'access-control-allow-methods',
  'access-control-allow-headers',
  'access-control-expose-headers',
  'access-control-max-age'
];

// 日志级别
const LOG_LEVEL = {
  INFO: 'INFO',
  WARN: 'WARN',
  ERROR: 'ERROR'
};

// 日志记录函数
function log(level, message, data = {}) {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    level,
    message,
    ...data
  };
  
  // 在生产环境中，您可能想将日志发送到日志服务
  console.log(JSON.stringify(logEntry));
}

// 随机选择 User-Agent
function getRandomUserAgent() {
  return CONFIG.USER_AGENTS[Math.floor(Math.random() * CONFIG.USER_AGENTS.length)];
}

// 检查路径是否支持
function isPathSupported(pathname) {
  return CONFIG.SUPPORTED_PATHS.some(prefix => pathname.startsWith(prefix));
}

// 验证认证
function validateAuth(request) {
  if (!CONFIG.AUTH_ENABLED) {
    return true;
  }
  
  const authHeader = request.headers.get('Authorization');
  return authHeader === CONFIG.AUTH_TOKEN;
}

// 清理请求头
function cleanRequestHeaders(headers) {
  const cleanedHeaders = new Headers();
  
  for (const [key, value] of headers.entries()) {
    const lowerKey = key.toLowerCase();
    if (!HEADERS_TO_REMOVE.includes(lowerKey)) {
      cleanedHeaders.set(key, value);
    }
  }
  
  // 设置必要的头信息
  cleanedHeaders.set('Host', CONFIG.TARGET_HOST);
  cleanedHeaders.set('User-Agent', getRandomUserAgent());
  
  // 设置接受编码
  if (CONFIG.ENABLE_COMPRESSION) {
    cleanedHeaders.set('Accept-Encoding', 'gzip, deflate, br');
  }
  
  return cleanedHeaders;
}

// 清理响应头
function cleanResponseHeaders(headers) {
  const cleanedHeaders = new Headers();
  
  for (const [key, value] of headers.entries()) {
    const lowerKey = key.toLowerCase();
    if (!RESPONSE_HEADERS_TO_REMOVE.includes(lowerKey) && 
        (HEADERS_TO_KEEP.includes(lowerKey) || lowerKey.startsWith('access-control-'))) {
      cleanedHeaders.set(key, value);
    }
  }
  
  // 添加 CORS 头
  if (CONFIG.ENABLE_CORS) {
    cleanedHeaders.set('Access-Control-Allow-Origin', '*');
    cleanedHeaders.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    cleanedHeaders.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
    cleanedHeaders.set('Access-Control-Max-Age', '86400');
  }
  
  return cleanedHeaders;
}

// 处理 OPTIONS 请求（CORS 预检）
function handleOptionsRequest() {
  const headers = new Headers();
  headers.set('Access-Control-Allow-Origin', '*');
  headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
  headers.set('Access-Control-Max-Age', '86400');
  
  return new Response(null, {
    status: 204,
    headers
  });
}

// 处理错误响应
function handleErrorResponse(error, status = 500) {
  log(LOG_LEVEL.ERROR, 'Proxy error', { error: error.message, stack: error.stack });
  
  const errorResponse = {
    error: 'Proxy Error',
    message: error.message,
    status: status,
    timestamp: new Date().toISOString()
  };
  
  return new Response(JSON.stringify(errorResponse), {
    status: status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

// 主请求处理函数
async function handleRequest(request) {
  try {
    const url = new URL(request.url);
    const method = request.method;
    
    // 记录请求信息
    log(LOG_LEVEL.INFO, 'Incoming request', {
      method,
      url: url.pathname,
      userAgent: request.headers.get('User-Agent'),
      ip: request.headers.get('CF-Connecting-IP') || 'unknown'
    });
    
    // 处理 CORS 预检请求
    if (method === 'OPTIONS') {
      return handleOptionsRequest();
    }
    
    // 检查路径是否支持
    if (!isPathSupported(url.pathname)) {
      return handleErrorResponse(new Error(`Path not supported: ${url.pathname}`), 404);
    }
    
    // 验证认证
    if (!validateAuth(request)) {
      return handleErrorResponse(new Error('Unauthorized'), 401);
    }
    
    // 构造目标 URL
    const targetUrl = new URL(url.pathname + url.search, `https://${CONFIG.TARGET_HOST}`);
    
    // 清理请求头
    const cleanedHeaders = cleanRequestHeaders(request.headers);
    
    // 创建新请求
    const requestInit = {
      method: method,
      headers: cleanedHeaders,
      redirect: 'manual'
    };
    
    // 添加请求体（如果有）
    if (method !== 'GET' && method !== 'HEAD') {
      const contentType = cleanedHeaders.get('Content-Type');
      if (contentType && contentType.includes('application/json')) {
        const body = await request.text();
        requestInit.body = body;
      } else {
        requestInit.body = request.body;
      }
    }
    
    // 设置超时
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), CONFIG.TIMEOUT);
    
    // 记录目标请求
    log(LOG_LEVEL.INFO, 'Forwarding request', {
      targetUrl: targetUrl.toString(),
      method: method,
      headers: Object.fromEntries(cleanedHeaders.entries())
    });
    
    // 发送请求
    const response = await fetch(targetUrl.toString(), {
      ...requestInit,
      signal: controller.signal
    });
    
    clearTimeout(timeoutId);
    
    // 检查响应大小
    const contentLength = response.headers.get('Content-Length');
    if (contentLength && parseInt(contentLength) > CONFIG.MAX_RESPONSE_SIZE) {
      return handleErrorResponse(new Error('Response too large'), 413);
    }
    
    // 清理响应头
    const cleanedResponseHeaders = cleanResponseHeaders(response.headers);
    
    // 创建新响应
    const responseBody = response.body;
    
    // 记录响应信息
    log(LOG_LEVEL.INFO, 'Response received', {
      status: response.status,
      statusText: response.statusText,
      headers: Object.fromEntries(cleanedResponseHeaders.entries())
    });
    
    return new Response(responseBody, {
      status: response.status,
      statusText: response.statusText,
      headers: cleanedResponseHeaders
    });
    
  } catch (error) {
    // 处理超时错误
    if (error.name === 'AbortError') {
      return handleErrorResponse(new Error('Request timeout'), 504);
    }
    
    // 处理其他错误
    return handleErrorResponse(error, 500);
  }
}

// 事件监听器
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request).catch(error => {
    console.error('Unhandled error:', error);
    return handleErrorResponse(error, 500);
  }));
});

// 导出函数（用于测试）
if (typeof module !== 'undefined') {
  module.exports = {
    handleRequest,
    isPathSupported,
    validateAuth,
    cleanRequestHeaders,
    cleanResponseHeaders,
    CONFIG
  };
}