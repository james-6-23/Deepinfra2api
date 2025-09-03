/**
 * 简易版 Cloudflare Workers - DeepInfra API 代理
 * 用于避免官方端点限流问题
 */

// 配置
const CONFIG = {
  // 目标 API 地址
  TARGET_HOST: 'api.deepinfra.com',
  
  // 支持的路径
  SUPPORTED_PATHS: ['/v1/models', '/v1/chat/completions', '/v1/completions'],
  
  // CORS 设置
  ENABLE_CORS: true,
  
  // 请求超时（毫秒）
  REQUEST_TIMEOUT: 30000,
  
  // 重试配置
  MAX_RETRIES: 2,
  RETRY_DELAY: 1000,
  
  // 缓存配置
  CACHE_TTL: 300, // 5分钟
};

// CORS 头部
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400',
};

// 错误响应
const ERROR_RESPONSES = {
  METHOD_NOT_ALLOWED: { error: 'Method not allowed', code: 405 },
  PATH_NOT_SUPPORTED: { error: 'Path not supported', code: 404 },
  UPSTREAM_ERROR: { error: 'Upstream service error', code: 502 },
  TIMEOUT_ERROR: { error: 'Request timeout', code: 504 },
  RATE_LIMIT_ERROR: { error: 'Rate limit exceeded', code: 429 },
};

/**
 * 主处理函数
 */
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

/**
 * 处理请求
 */
async function handleRequest(request) {
  try {
    // 处理 CORS 预检请求
    if (request.method === 'OPTIONS') {
      return handleCORS();
    }

    // 检查请求方法
    if (!['GET', 'POST'].includes(request.method)) {
      return createErrorResponse(ERROR_RESPONSES.METHOD_NOT_ALLOWED);
    }

    // 解析请求 URL
    const url = new URL(request.url);
    const path = url.pathname;

    // 检查路径是否支持
    if (!isPathSupported(path)) {
      return createErrorResponse(ERROR_RESPONSES.PATH_NOT_SUPPORTED);
    }

    // 检查缓存（仅对 GET 请求）
    if (request.method === 'GET') {
      const cachedResponse = await getFromCache(request);
      if (cachedResponse) {
        return addCORSHeaders(cachedResponse);
      }
    }

    // 转发请求到目标服务器
    const response = await forwardRequest(request, path);
    
    // 缓存响应（仅对成功的 GET 请求）
    if (request.method === 'GET' && response.ok) {
      await saveToCache(request, response.clone());
    }

    return addCORSHeaders(response);

  } catch (error) {
    console.error('Request handling error:', error);
    return createErrorResponse(ERROR_RESPONSES.UPSTREAM_ERROR);
  }
}

/**
 * 检查路径是否支持
 */
function isPathSupported(path) {
  return CONFIG.SUPPORTED_PATHS.some(supportedPath => 
    path.startsWith(supportedPath)
  );
}

/**
 * 转发请求到目标服务器
 */
async function forwardRequest(request, path) {
  const url = new URL(request.url);
  
  // 构建目标 URL
  const targetUrl = `https://${CONFIG.TARGET_HOST}${path}${url.search}`;
  
  // 复制请求头
  const headers = new Headers(request.headers);
  
  // 添加必要的头部
  headers.set('Host', CONFIG.TARGET_HOST);
  headers.set('User-Agent', 'DeepInfra2API-Worker/1.0');
  
  // 构建请求选项
  const requestOptions = {
    method: request.method,
    headers: headers,
    body: request.method === 'POST' ? await request.text() : undefined,
  };

  // 带重试的请求
  return await requestWithRetry(targetUrl, requestOptions);
}

/**
 * 带重试机制的请求
 */
async function requestWithRetry(url, options, retryCount = 0) {
  try {
    // 设置超时
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), CONFIG.REQUEST_TIMEOUT);
    
    const response = await fetch(url, {
      ...options,
      signal: controller.signal,
    });
    
    clearTimeout(timeoutId);

    // 检查响应状态
    if (response.status === 429 || response.status === 503) {
      // 限流或服务不可用，尝试重试
      if (retryCount < CONFIG.MAX_RETRIES) {
        await sleep(CONFIG.RETRY_DELAY * (retryCount + 1));
        return await requestWithRetry(url, options, retryCount + 1);
      } else {
        return createErrorResponse(ERROR_RESPONSES.RATE_LIMIT_ERROR);
      }
    }

    return response;

  } catch (error) {
    if (error.name === 'AbortError') {
      return createErrorResponse(ERROR_RESPONSES.TIMEOUT_ERROR);
    }

    // 网络错误，尝试重试
    if (retryCount < CONFIG.MAX_RETRIES) {
      await sleep(CONFIG.RETRY_DELAY * (retryCount + 1));
      return await requestWithRetry(url, options, retryCount + 1);
    }

    throw error;
  }
}

/**
 * 处理 CORS
 */
function handleCORS() {
  return new Response(null, {
    status: 200,
    headers: CORS_HEADERS,
  });
}

/**
 * 添加 CORS 头部
 */
function addCORSHeaders(response) {
  if (!CONFIG.ENABLE_CORS) {
    return response;
  }

  const newResponse = new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers,
  });

  Object.entries(CORS_HEADERS).forEach(([key, value]) => {
    newResponse.headers.set(key, value);
  });

  return newResponse;
}

/**
 * 创建错误响应
 */
function createErrorResponse(errorConfig) {
  const response = new Response(JSON.stringify({
    error: errorConfig.error,
    timestamp: new Date().toISOString(),
    worker: 'deepinfra2api-simple',
  }), {
    status: errorConfig.code,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
    },
  });

  return response;
}

/**
 * 从缓存获取响应
 */
async function getFromCache(request) {
  try {
    const cache = caches.default;
    const cacheKey = new Request(request.url, {
      method: 'GET',
      headers: request.headers,
    });
    
    return await cache.match(cacheKey);
  } catch (error) {
    console.error('Cache get error:', error);
    return null;
  }
}

/**
 * 保存响应到缓存
 */
async function saveToCache(request, response) {
  try {
    const cache = caches.default;
    const cacheKey = new Request(request.url, {
      method: 'GET',
      headers: request.headers,
    });
    
    // 设置缓存头部
    const cacheResponse = new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: {
        ...response.headers,
        'Cache-Control': `public, max-age=${CONFIG.CACHE_TTL}`,
      },
    });
    
    await cache.put(cacheKey, cacheResponse);
  } catch (error) {
    console.error('Cache save error:', error);
  }
}

/**
 * 延迟函数
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * 健康检查端点
 */
addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  
  if (url.pathname === '/health') {
    event.respondWith(new Response(JSON.stringify({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      worker: 'deepinfra2api-simple',
      version: '1.0.0',
    }), {
      headers: {
        'Content-Type': 'application/json',
        ...CORS_HEADERS,
      },
    }));
  }
});
