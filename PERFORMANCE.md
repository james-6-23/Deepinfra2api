# ⚡ 性能模式对比

本项目支持三种性能模式，可以在速度和安全性之间进行平衡。

## 🎯 性能模式对比

| 模式 | 延迟增加 | 安全性 | 适用场景 |
|------|----------|--------|----------|
| **Fast** | +0-100ms | 低 | 开发测试、速度优先 |
| **Balanced** | +100-500ms | 中 | 生产环境推荐 |
| **Secure** | +500-1500ms | 高 | 高风险环境、安全优先 |

## 📊 详细配置对比

### Fast 模式 (最快速度)
```bash
PERFORMANCE_MODE=fast
MAX_RETRIES=1              # 减少重试次数
RETRY_DELAY=200           # 快速重试
REQUEST_TIMEOUT=10000     # 10秒超时
RANDOM_DELAY_MIN=0        # 无随机延迟
RANDOM_DELAY_MAX=100      # 最小延迟
```

**特点**:
- ✅ 最快响应速度
- ✅ 适合开发测试
- ❌ 容易被检测
- ❌ 封锁风险高

### Balanced 模式 (推荐默认)
```bash
PERFORMANCE_MODE=balanced
MAX_RETRIES=3             # 适中重试
RETRY_DELAY=1000         # 1秒重试间隔
REQUEST_TIMEOUT=30000    # 30秒超时
RANDOM_DELAY_MIN=100     # 适中延迟
RANDOM_DELAY_MAX=500     # 合理范围
```

**特点**:
- ✅ 速度与安全平衡
- ✅ 生产环境推荐
- ✅ 合理的延迟时间
- ✅ 较好的稳定性

### Secure 模式 (最高安全)
```bash
PERFORMANCE_MODE=secure
MAX_RETRIES=5             # 更多重试
RETRY_DELAY=2000         # 较长重试间隔
REQUEST_TIMEOUT=60000    # 60秒超时
RANDOM_DELAY_MIN=500     # 较长延迟
RANDOM_DELAY_MAX=1500    # 更安全范围
```

**特点**:
- ✅ 最高安全性
- ✅ 最强反封锁能力
- ✅ 适合高风险环境
- ❌ 响应较慢

## 🔧 WARP 代理性能影响

### 不使用 WARP
```bash
WARP_ENABLED=false
```
- **延迟**: 0ms 额外延迟
- **安全性**: 依赖服务器IP
- **速度**: 最快

### 使用 WARP
```bash
WARP_ENABLED=true
```
- **延迟**: +50-200ms (通过 Cloudflare 网络)
- **安全性**: IP 隐藏，路由优化
- **速度**: 可能因路由优化而提升

## 📈 性能监控

访问 `/health` 端点查看实时性能统计：

```json
{
  "status": "ok",
  "performance_mode": "balanced",
  "stats": {
    "total_requests": 1250,
    "average_response_time": 890,
    "error_rate": 2
  }
}
```

## 🚀 推荐配置

### 开发环境
```bash
PERFORMANCE_MODE=fast
WARP_ENABLED=false
```

### 生产环境
```bash
PERFORMANCE_MODE=balanced
WARP_ENABLED=true
```

### 高风险环境
```bash
PERFORMANCE_MODE=secure
WARP_ENABLED=true
WARP_LICENSE_KEY=your-warp-plus-key
```

## 🎯 实际测试数据

基于内部测试的平均响应时间：

| 场景 | Fast模式 | Balanced模式 | Secure模式 |
|------|----------|--------------|------------|
| 简单对话 | 1.2s | 1.8s | 2.5s |
| 长文本 | 3.5s | 4.2s | 5.8s |
| 流式响应 | +0.1s | +0.3s | +0.7s |

**注意**: 实际性能取决于网络环境、服务器位置和API负载。