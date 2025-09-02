# 🚀 Go 高并发版本选项说明

## 新增选项概览

quick-start.sh 脚本现已新增 4 个高并发 Go 版本选项：

| 选项 | 名称 | 并发能力 | 适用场景 | 配置特点 |
|------|------|----------|----------|----------|
| **9** | Go 高并发基础版 | 1000并发 | 中小型应用 | 平衡性能与稳定性 |
| **10** | Go 高并发 + 多端点 | 2000并发 | 中大型应用 | 负载均衡 + 高并发 |
| **11** | Go 高并发 + WARP | 1000并发 | 网络受限环境 | WARP代理 + 高并发 |
| **12** | Go 高并发完整版 | 3000并发 | 企业级应用 | 最高性能配置 |

## 详细配置说明

### 选项 9: Go 高并发基础版 (1000并发)
```bash
# 基础高并发配置
MAX_CONCURRENT_CONNECTIONS=1000
STREAM_BUFFER_SIZE=16384        # 16KB
MEMORY_LIMIT_MB=2048           # 2GB
REQUEST_TIMEOUT=120000         # 2分钟
STREAM_TIMEOUT=300000          # 5分钟
DISABLE_CONNECTION_CHECK=false
CONNECTION_CHECK_INTERVAL=20
```

**适用场景**：
- 中小型应用
- 日活用户 1000-5000
- 服务器配置：4核8GB

### 选项 10: Go 高并发 + 多端点 (2000并发)
```bash
# 中等高并发配置 + 多端点负载均衡
MAX_CONCURRENT_CONNECTIONS=2000
STREAM_BUFFER_SIZE=32768        # 32KB
MEMORY_LIMIT_MB=4096           # 4GB
REQUEST_TIMEOUT=90000          # 1.5分钟
STREAM_TIMEOUT=240000          # 4分钟
CONNECTION_CHECK_INTERVAL=30
```

**适用场景**：
- 中大型应用
- 日活用户 5000-20000
- 服务器配置：8核16GB
- 需要高可用性

### 选项 11: Go 高并发 + WARP (1000并发)
```bash
# 基础高并发配置 + WARP 代理
# 配置同选项9，但启用 WARP 代理
WARP_ENABLED=true
```

**适用场景**：
- 网络环境受限
- 需要代理访问
- 对网络稳定性要求高

### 选项 12: Go 高并发完整版 (3000并发)
```bash
# 最高性能配置
MAX_CONCURRENT_CONNECTIONS=3000
STREAM_BUFFER_SIZE=65536        # 64KB
MEMORY_LIMIT_MB=6144           # 6GB
REQUEST_TIMEOUT=60000          # 1分钟
STREAM_TIMEOUT=180000          # 3分钟
DISABLE_CONNECTION_CHECK=true   # 禁用连接检测以提高性能
CONNECTION_CHECK_INTERVAL=50
```

**适用场景**：
- 企业级应用
- 日活用户 20000+
- 服务器配置：16核32GB
- 极高性能要求

## 使用方法

### 1. 启动高并发版本
```bash
./quick-start.sh
# 选择选项 9、10、11 或 12
```

### 2. 验证部署
```bash
# 检查服务状态
curl http://localhost:8001/health

# 检查系统监控
curl http://localhost:8001/status
```

### 3. 性能测试
```bash
# 运行高并发测试脚本
./test-high-concurrency.sh
```

## 监控和管理

### 系统状态监控
高并发版本提供了 `/status` 端点用于实时监控：

```json
{
  "current_connections": 245,
  "max_connections": 1000,
  "memory_usage_mb": 156,
  "memory_limit_mb": 2048,
  "total_requests": 12450,
  "error_count": 23
}
```

### 关键指标
- **连接使用率**: `current_connections / max_connections`
- **内存使用率**: `memory_usage_mb / memory_limit_mb`
- **错误率**: `error_count / total_requests`

### 告警阈值建议
- 连接使用率 > 85%：考虑扩容
- 内存使用率 > 80%：监控内存泄漏
- 错误率 > 5%：检查系统健康状态

## 性能对比

| 版本 | 并发数 | 内存使用 | 响应时间 | 适用规模 |
|------|--------|----------|----------|----------|
| 标准Go版本 | 500 | 1GB | 正常 | 小型 |
| 高并发基础版 | 1000 | 2GB | 正常 | 中型 |
| 高并发中等版 | 2000 | 4GB | 快速 | 大型 |
| 高并发完整版 | 3000 | 6GB | 极快 | 企业级 |

## 故障排除

### 常见问题

1. **连接数达到上限**
   ```
   错误: "Server too busy, please try again later"
   解决: 增加 MAX_CONCURRENT_CONNECTIONS 或部署多实例
   ```

2. **内存使用过高**
   ```
   现象: 系统响应变慢
   解决: 增加 MEMORY_LIMIT_MB 或优化请求频率
   ```

3. **响应超时**
   ```
   现象: 长响应被截断
   解决: 检查 STREAM_TIMEOUT 配置
   ```

### 性能调优建议

1. **根据实际负载调整配置**
   - 监控实际并发数和内存使用
   - 逐步调整参数

2. **多实例部署**
   - 单实例达到瓶颈时考虑多实例
   - 使用负载均衡器分发请求

3. **定期监控**
   - 设置监控告警
   - 定期检查系统状态

## 升级路径

### 从标准版本升级
1. 停止当前服务：选择选项 19
2. 选择合适的高并发版本：选项 9-12
3. 验证部署：运行测试脚本

### 配置迁移
现有的 `.env` 配置会被自动更新，无需手动修改。

## 总结

高并发版本提供了：
- ✅ **可扩展的并发处理能力**
- ✅ **实时系统监控**
- ✅ **智能资源管理**
- ✅ **优雅的降级机制**
- ✅ **简单的部署流程**

选择合适的高并发版本，让您的 API 代理服务轻松应对高并发挑战！🚀
