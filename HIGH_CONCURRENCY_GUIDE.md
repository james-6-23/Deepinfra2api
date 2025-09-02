# 高并发部署指南

## 🚀 高并发优化总览

### 核心改进
1. **并发连接控制** - 防止系统过载
2. **智能资源管理** - 内存和连接时间限制
3. **实时监控** - 系统状态可视化
4. **降级策略** - 过载时的优雅处理

## 📊 并发能力评估

### 单实例并发能力

| 服务器配置 | 推荐并发数 | 内存需求 | 适用场景 |
|-----------|-----------|----------|----------|
| **2核4GB** | 500-1000 | 1-2GB | 小型应用 |
| **4核8GB** | 1000-2000 | 2-4GB | 中型应用 |
| **8核16GB** | 2000-5000 | 4-8GB | 大型应用 |
| **16核32GB** | 5000-10000 | 8-16GB | 企业级 |

### 用户类型影响分析

**轻度用户占比80%的场景**：
```
1000并发 = 800轻度 + 200重度
连接时间 = 800×10秒 + 200×120秒 = 32000秒
实际并发压力 ≈ 32000/60 = 533个等效连接
```

**重度用户占比30%的场景**：
```
1000并发 = 700轻度 + 300重度  
连接时间 = 700×10秒 + 300×120秒 = 43000秒
实际并发压力 ≈ 43000/60 = 717个等效连接
```

## 🔧 配置优化建议

### 基础配置（1000并发）
```env
MAX_CONCURRENT_CONNECTIONS=1000
STREAM_BUFFER_SIZE=16384
MEMORY_LIMIT_MB=2048
REQUEST_TIMEOUT=120000
STREAM_TIMEOUT=300000
```

### 中等负载配置（2000-5000并发）
```env
MAX_CONCURRENT_CONNECTIONS=3000
STREAM_BUFFER_SIZE=32768
MEMORY_LIMIT_MB=4096
REQUEST_TIMEOUT=90000
STREAM_TIMEOUT=240000
CONNECTION_CHECK_INTERVAL=30
```

### 高负载配置（5000+并发）
```env
MAX_CONCURRENT_CONNECTIONS=8000
STREAM_BUFFER_SIZE=65536
MEMORY_LIMIT_MB=8192
REQUEST_TIMEOUT=60000
STREAM_TIMEOUT=180000
CONNECTION_CHECK_INTERVAL=50
DISABLE_CONNECTION_CHECK=true
```

## 🏗️ 多实例部署架构

### 负载均衡方案
```yaml
# docker-compose-cluster.yml
version: '3.8'
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - deepinfra-1
      - deepinfra-2
      - deepinfra-3

  deepinfra-1:
    build: .
    environment:
      - MAX_CONCURRENT_CONNECTIONS=2000
      - PORT=8000
    
  deepinfra-2:
    build: .
    environment:
      - MAX_CONCURRENT_CONNECTIONS=2000
      - PORT=8000
      
  deepinfra-3:
    build: .
    environment:
      - MAX_CONCURRENT_CONNECTIONS=2000
      - PORT=8000
```

### Nginx 配置示例
```nginx
upstream deepinfra_backend {
    least_conn;
    server deepinfra-1:8000 max_fails=3 fail_timeout=30s;
    server deepinfra-2:8000 max_fails=3 fail_timeout=30s;
    server deepinfra-3:8000 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    
    location /v1/chat/completions {
        proxy_pass http://deepinfra_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_buffering off;
        proxy_read_timeout 600s;
    }
    
    location /status {
        proxy_pass http://deepinfra_backend;
    }
}
```

## 📈 监控和告警

### 状态监控端点
```bash
# 检查系统状态
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

### 关键监控指标
- **连接使用率**: current_connections / max_connections
- **内存使用率**: memory_usage_mb / memory_limit_mb  
- **错误率**: error_count / total_requests
- **响应时间**: 平均响应时间趋势

### 告警阈值建议
```bash
# 连接数告警
if [ connections_usage > 85% ]; then
    echo "WARNING: High connection usage"
fi

# 内存告警  
if [ memory_usage > 80% ]; then
    echo "WARNING: High memory usage"
fi

# 错误率告警
if [ error_rate > 5% ]; then
    echo "CRITICAL: High error rate"
fi
```

## 🛡️ 降级和容错策略

### 1. 连接限制降级
```go
// 当连接数达到90%时，开始拒绝新连接
if currentConnections > maxConnections * 0.9 {
    return "503 Service Unavailable"
}
```

### 2. 超时时间动态调整
```go
// 根据系统负载动态调整超时时间
if systemLoad > 80% {
    streamTimeout = streamTimeout * 0.8
}
```

### 3. 内存保护机制
```go
// 内存使用超过阈值时触发GC
if memoryUsage > memoryLimit * 0.85 {
    runtime.GC()
}
```

## 🧪 压力测试建议

### 测试工具
```bash
# 使用 wrk 进行压力测试
wrk -t12 -c1000 -d30s --timeout 60s \
  -s test-script.lua \
  http://localhost:8001/v1/chat/completions

# 使用 ab 进行简单测试  
ab -n 10000 -c 100 -k \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer linux.do" \
  -p test-payload.json \
  http://localhost:8001/v1/chat/completions
```

### 测试场景
1. **轻度负载**: 100并发，简单问答
2. **中度负载**: 500并发，混合请求
3. **重度负载**: 1000并发，长响应请求
4. **极限测试**: 2000+并发，压力测试

## 📋 部署检查清单

### 部署前检查
- [ ] 服务器资源充足（CPU、内存、磁盘）
- [ ] 网络带宽满足需求
- [ ] Docker 和 Docker Compose 版本兼容
- [ ] 环境变量配置正确
- [ ] 监控系统就绪

### 部署后验证
- [ ] 健康检查通过 (`/health`)
- [ ] 状态监控正常 (`/status`)
- [ ] 并发限制生效
- [ ] 内存使用在预期范围内
- [ ] 响应时间符合预期

### 运维监控
- [ ] 设置监控告警
- [ ] 配置日志收集
- [ ] 建立扩容策略
- [ ] 准备降级预案

## 🎯 总结

通过以上优化，Go 版本现在具备了：
- ✅ **可控的并发处理能力**
- ✅ **智能的资源管理**
- ✅ **实时的系统监控**
- ✅ **优雅的降级机制**

**推荐部署策略**：
1. 单实例先部署1000并发配置
2. 根据实际负载调整参数
3. 负载增长时采用多实例部署
4. 持续监控和优化
