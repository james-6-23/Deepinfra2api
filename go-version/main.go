package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

// 类型定义
type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type ChatRequest struct {
	Model       string        `json:"model"`
	Messages    []ChatMessage `json:"messages"`
	Stream      *bool         `json:"stream,omitempty"`
	Temperature *float64      `json:"temperature,omitempty"`
	MaxTokens   *int          `json:"max_tokens,omitempty"`
}

type Delta struct {
	Content          *string `json:"content,omitempty"`
	ReasoningContent *string `json:"reasoning_content,omitempty"`
}

type Choice struct {
	Delta Delta `json:"delta"`
}

type StreamResponse struct {
	Choices []Choice `json:"choices"`
}

type Model struct {
	ID     string `json:"id"`
	Object string `json:"object"`
}

type ModelsResponse struct {
	Object string  `json:"object"`
	Data   []Model `json:"data"`
}

type HealthStats struct {
	TotalRequests       int `json:"total_requests"`
	AverageResponseTime int `json:"average_response_time"`
	ErrorRate           int `json:"error_rate"`
}

type HealthConfig struct {
	MaxRetries     int    `json:"max_retries"`
	RetryDelay     int    `json:"retry_delay"`
	RequestTimeout int    `json:"request_timeout"`
	RandomDelay    string `json:"random_delay"`
}

type HealthResponse struct {
	Status          string       `json:"status"`
	Timestamp       string       `json:"timestamp"`
	PerformanceMode string       `json:"performance_mode"`
	Config          HealthConfig `json:"config"`
	Stats           HealthStats  `json:"stats"`
}

type ErrorResponse struct {
	Error              string `json:"error"`
	Details            string `json:"details,omitempty"`
	RetryAfter         int    `json:"retry_after,omitempty"`
	AvailableEndpoints int    `json:"available_endpoints,omitempty"`
	PerformanceMode    string `json:"performance_mode,omitempty"`
}

// 全局配置
var (
	deepinfraURL = "https://api.deepinfra.com/v1/openai/chat/completions"
	port         = getEnvInt("PORT", 8000)

	// 性能配置
	performanceMode = getEnv("PERFORMANCE_MODE", "balanced")
	maxRetries      int
	retryDelay      int
	requestTimeout  int
	randomDelayMin  int
	randomDelayMax  int

	// API 端点和密钥
	apiEndpoints []string
	validAPIKeys []string

	// 统计数据
	requestCount      int64
	totalResponseTime int64
	errorCount        int64

	// 支持的模型
	supportedModels = []Model{
		{ID: "openai/gpt-oss-120b", Object: "model"},
		{ID: "moonshotai/Kimi-K2-Instruct", Object: "model"},
		{ID: "zai-org/GLM-4.5", Object: "model"},
		{ID: "zai-org/GLM-4.5-Air", Object: "model"},
		{ID: "Qwen/Qwen3-Coder-480B-A35B-Instruct-Turbo", Object: "model"},
		{ID: "deepseek-ai/DeepSeek-R1-0528-Turbo", Object: "model"},
		{ID: "deepseek-ai/DeepSeek-V3-0324-Turbo", Object: "model"},
		{ID: "deepseek-ai/DeepSeek-V3.1", Object: "model"},
		{ID: "meta-llama/Llama-4-Maverick-17B-128E-Instruct-Turbo", Object: "model"},
	}

	// User-Agent 列表
	userAgents = []string{
		"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
		"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
		"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
		"Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0",
		"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0",
	}
)

// 工具函数
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getPerformanceConfig() {
	mode := strings.ToLower(performanceMode)

	switch mode {
	case "fast":
		maxRetries = getEnvInt("MAX_RETRIES", 1)
		retryDelay = getEnvInt("RETRY_DELAY", 200)
		requestTimeout = getEnvInt("REQUEST_TIMEOUT", 10000)
		randomDelayMin = getEnvInt("RANDOM_DELAY_MIN", 0)
		randomDelayMax = getEnvInt("RANDOM_DELAY_MAX", 100)
	case "secure":
		maxRetries = getEnvInt("MAX_RETRIES", 5)
		retryDelay = getEnvInt("RETRY_DELAY", 2000)
		requestTimeout = getEnvInt("REQUEST_TIMEOUT", 60000)
		randomDelayMin = getEnvInt("RANDOM_DELAY_MIN", 500)
		randomDelayMax = getEnvInt("RANDOM_DELAY_MAX", 1500)
	default: // balanced
		maxRetries = getEnvInt("MAX_RETRIES", 3)
		retryDelay = getEnvInt("RETRY_DELAY", 1000)
		requestTimeout = getEnvInt("REQUEST_TIMEOUT", 30000)
		randomDelayMin = getEnvInt("RANDOM_DELAY_MIN", 100)
		randomDelayMax = getEnvInt("RANDOM_DELAY_MAX", 500)
	}
}

func getAPIEndpoints() []string {
	mirrors := getEnv("DEEPINFRA_MIRRORS", "")
	if mirrors != "" {
		endpoints := strings.Split(mirrors, ",")
		for i, endpoint := range endpoints {
			endpoints[i] = strings.TrimSpace(endpoint)
		}
		return endpoints
	}
	return []string{deepinfraURL}
}

func getValidAPIKeys() []string {
	keys := getEnv("VALID_API_KEYS", "linux.do")
	keyList := strings.Split(keys, ",")
	for i, key := range keyList {
		keyList[i] = strings.TrimSpace(key)
	}
	return keyList
}

func randomDelay() {
	if randomDelayMax > randomDelayMin {
		delay := rand.Intn(randomDelayMax-randomDelayMin) + randomDelayMin
		time.Sleep(time.Duration(delay) * time.Millisecond)
	}
}

func getRandomUserAgent() string {
	return userAgents[rand.Intn(len(userAgents))]
}

// 带重试和多端点的请求函数
func fetchWithRetry(ctx context.Context, body []byte) (*http.Response, error) {
	var lastError error

	for endpointIndex, endpoint := range apiEndpoints {
		for i := 0; i < maxRetries; i++ {
			// 添加延迟
			if i > 0 || endpointIndex > 0 {
				delay := time.Duration(retryDelay*int(math.Pow(2, float64(i)))) * time.Millisecond
				time.Sleep(delay)
			}

			randomDelay()

			// 创建请求
			req, err := http.NewRequestWithContext(ctx, "POST", endpoint, bytes.NewReader(body))
			if err != nil {
				lastError = err
				continue
			}

			// 设置请求头
			req.Header.Set("Content-Type", "application/json")
			req.Header.Set("User-Agent", getRandomUserAgent())
			req.Header.Set("Accept", "text/event-stream, application/json, text/plain, */*")
			req.Header.Set("Accept-Language", "en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7")
			req.Header.Set("Accept-Encoding", "gzip, deflate, br")
			req.Header.Set("Origin", "https://deepinfra.com")
			req.Header.Set("Referer", "https://deepinfra.com/")
			req.Header.Set("Sec-CH-UA", `"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"`)
			req.Header.Set("Sec-CH-UA-Mobile", "?0")
			req.Header.Set("Sec-CH-UA-Platform", `"Windows"`)
			req.Header.Set("Sec-Fetch-Dest", "empty")
			req.Header.Set("Sec-Fetch-Mode", "cors")
			req.Header.Set("Sec-Fetch-Site", "same-origin")
			req.Header.Set("X-Requested-With", "XMLHttpRequest")
			req.Header.Set("Cache-Control", "no-cache")
			req.Header.Set("Pragma", "no-cache")

			log.Printf("尝试请求端点: %s (第%d个端点, 第%d次尝试)", endpoint, endpointIndex+1, i+1)

			// 发送请求
			client := &http.Client{
				Timeout: time.Duration(requestTimeout) * time.Millisecond,
			}

			resp, err := client.Do(req)
			if err != nil {
				lastError = err
				log.Printf("端点 %s 请求尝试 %d/%d 失败: %v", endpoint, i+1, maxRetries, err)
				continue
			}

			if resp.StatusCode == http.StatusOK {
				log.Printf("请求成功: %s", endpoint)
				return resp, nil
			}

			// 处理限流或封禁错误
			if resp.StatusCode == http.StatusTooManyRequests || resp.StatusCode == http.StatusForbidden {
				waitTime := time.Duration(math.Min(float64(retryDelay)*math.Pow(2, float64(i)), 10000)) * time.Millisecond
				log.Printf("端点 %s 被限流或封禁 (%d)，等待 %v 后重试...", endpoint, resp.StatusCode, waitTime)
				resp.Body.Close()
				time.Sleep(waitTime)
				continue
			}

			resp.Body.Close()
			lastError = fmt.Errorf("HTTP %d: %s", resp.StatusCode, resp.Status)
			log.Printf("端点 %s 请求尝试 %d/%d 失败: %v", endpoint, i+1, maxRetries, lastError)
		}
		log.Printf("端点 %s 所有重试都失败，尝试下一个端点", apiEndpoints[endpointIndex])
	}

	if lastError == nil {
		lastError = fmt.Errorf("所有端点和重试都失败")
	}
	return nil, lastError
}

// HTTP 处理函数
func healthHandler(w http.ResponseWriter, r *http.Request) {
	avgResponseTime := 0
	errorRate := 0
	if requestCount > 0 {
		avgResponseTime = int(totalResponseTime / requestCount)
		errorRate = int((errorCount * 100) / requestCount)
	}

	response := HealthResponse{
		Status:          "ok",
		Timestamp:       time.Now().Format(time.RFC3339),
		PerformanceMode: performanceMode,
		Config: HealthConfig{
			MaxRetries:     maxRetries,
			RetryDelay:     retryDelay,
			RequestTimeout: requestTimeout,
			RandomDelay:    fmt.Sprintf("%d-%dms", randomDelayMin, randomDelayMax),
		},
		Stats: HealthStats{
			TotalRequests:       int(requestCount),
			AverageResponseTime: avgResponseTime,
			ErrorRate:           errorRate,
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func modelsHandler(w http.ResponseWriter, r *http.Request) {
	response := ModelsResponse{
		Object: "list",
		Data:   supportedModels,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func chatHandler(w http.ResponseWriter, r *http.Request) {
	startTime := time.Now()
	requestCount++

	// 读取请求体
	body, err := io.ReadAll(r.Body)
	if err != nil {
		errorCount++
		http.Error(w, `{"error": "Failed to read request body"}`, http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// API Key 验证
	auth := r.Header.Get("Authorization")
	key := strings.TrimPrefix(auth, "Bearer ")
	key = strings.TrimSpace(key)

	validKey := false
	for _, validAPIKey := range validAPIKeys {
		if key == validAPIKey {
			validKey = true
			break
		}
	}

	if !validKey {
		errorCount++
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(ErrorResponse{Error: "Unauthorized"})
		return
	}

	// 解析请求体
	var chatReq ChatRequest
	if err := json.Unmarshal(body, &chatReq); err != nil {
		errorCount++
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(ErrorResponse{Error: "Invalid JSON format"})
		return
	}

	isStream := chatReq.Stream != nil && *chatReq.Stream

	// 发送请求到 DeepInfra API
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(requestTimeout)*time.Millisecond)
	defer cancel()

	resp, err := fetchWithRetry(ctx, body)
	if err != nil {
		errorCount++
		responseTime := time.Since(startTime)
		totalResponseTime += int64(responseTime.Milliseconds())

		log.Printf("DeepInfra API 所有端点请求失败: %v", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadGateway)
		json.NewEncoder(w).Encode(ErrorResponse{
			Error:              "External API request failed",
			Details:            err.Error(),
			RetryAfter:         60,
			AvailableEndpoints: len(apiEndpoints),
			PerformanceMode:    performanceMode,
		})
		return
	}
	defer resp.Body.Close()

	// 处理响应
	if !isStream {
		// 非流式响应
		responseBody, err := io.ReadAll(resp.Body)
		if err != nil {
			errorCount++
			http.Error(w, `{"error": "Failed to read response"}`, http.StatusInternalServerError)
			return
		}

		responseTime := time.Since(startTime)
		totalResponseTime += int64(responseTime.Milliseconds())
		log.Printf("✅ 请求完成: %v", responseTime)

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(resp.StatusCode)
		w.Write(responseBody)
		return
	}

	// 流式响应处理
	handleStreamResponse(w, resp)
}

// 流式响应处理
func handleStreamResponse(w http.ResponseWriter, resp *http.Response) {
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "Streaming unsupported", http.StatusInternalServerError)
		return
	}

	scanner := bufio.NewScanner(resp.Body)
	isInThinkBlock := false
	bufferedThinkContent := ""

	for scanner.Scan() {
		line := scanner.Text()

		if strings.HasPrefix(line, "data: ") {
			jsonText := strings.TrimSpace(line[6:])

			if jsonText == "[DONE]" {
				// 发送缓存的思考内容
				if isInThinkBlock && bufferedThinkContent != "" {
					thinkData := map[string]interface{}{
						"choices": []map[string]interface{}{
							{
								"delta": map[string]interface{}{
									"content": fmt.Sprintf("<think>%s</think>", bufferedThinkContent),
								},
							},
						},
					}
					if thinkJSON, err := json.Marshal(thinkData); err == nil {
						fmt.Fprintf(w, "data: %s\n\n", string(thinkJSON))
						flusher.Flush()
					}
				}

				fmt.Fprintf(w, "data: [DONE]\n\n")
				flusher.Flush()
				break
			}

			if jsonText != "" {
				var streamResp StreamResponse
				if err := json.Unmarshal([]byte(jsonText), &streamResp); err == nil {
					if len(streamResp.Choices) > 0 {
						delta := streamResp.Choices[0].Delta

						var contentToSend *string

						// 处理思考内容
						if delta.ReasoningContent != nil {
							if *delta.ReasoningContent != "" {
								bufferedThinkContent += *delta.ReasoningContent
							}
							isInThinkBlock = true
						} else if delta.Content != nil {
							// 处理正常内容
							if isInThinkBlock {
								// 发送思考内容
								if bufferedThinkContent != "" {
									thinkData := map[string]interface{}{
										"choices": []map[string]interface{}{
											{
												"delta": map[string]interface{}{
													"content": fmt.Sprintf("<think>%s</think>", bufferedThinkContent),
												},
											},
										},
									}
									if thinkJSON, err := json.Marshal(thinkData); err == nil {
										fmt.Fprintf(w, "data: %s\n\n", string(thinkJSON))
										flusher.Flush()
									}
									bufferedThinkContent = ""
								}
								isInThinkBlock = false
							}
							contentToSend = delta.Content
						}

						// 发送正常内容
						if contentToSend != nil {
							outputData := map[string]interface{}{
								"choices": []map[string]interface{}{
									{
										"delta": map[string]interface{}{
											"content": *contentToSend,
										},
									},
								},
							}
							if outputJSON, err := json.Marshal(outputData); err == nil {
								fmt.Fprintf(w, "data: %s\n\n", string(outputJSON))
								flusher.Flush()
							}
						}
					}
				}
			}
		}
	}
}

func main() {
	// 设置路由
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/v1/models", modelsHandler)
	http.HandleFunc("/v1/chat/completions", chatHandler)

	// 404 处理
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(ErrorResponse{Error: "Not Found"})
	})

	// 启动服务器
	addr := fmt.Sprintf(":%d", port)
	log.Printf("🌐 Server listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}

func init() {
	rand.Seed(time.Now().UnixNano())
	getPerformanceConfig()
	apiEndpoints = getAPIEndpoints()
	validAPIKeys = getValidAPIKeys()

	log.Printf("🚀 DeepInfra API Proxy started on port %d", port)
	log.Printf("⚡ Performance mode: %s", performanceMode)
	log.Printf("🔧 Config: retries=%d, delay=%dms, timeout=%dms", maxRetries, retryDelay, requestTimeout)
	log.Printf("⏱️  Random delay: %d-%dms", randomDelayMin, randomDelayMax)
}
