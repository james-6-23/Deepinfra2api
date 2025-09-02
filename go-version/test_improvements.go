package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// 测试用的聊天请求
type TestChatRequest struct {
	Model    string        `json:"model"`
	Messages []TestMessage `json:"messages"`
	Stream   bool          `json:"stream"`
}

type TestMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// 测试流式响应处理的改进效果
func main() {
	fmt.Println("🧪 测试 Go 版本流式响应处理改进效果")
	fmt.Println("=" * 50)

	// 测试用例1：正常对话
	fmt.Println("\n📝 测试用例1：正常对话")
	testNormalChat()

	// 测试用例2：长文本响应（模拟 roo code 场景）
	fmt.Println("\n📝 测试用例2：长文本响应")
	testLongResponse()

	// 测试用例3：复杂推理内容
	fmt.Println("\n📝 测试用例3：复杂推理内容")
	testComplexReasoning()

	fmt.Println("\n✅ 所有测试完成")
}

func testNormalChat() {
	request := TestChatRequest{
		Model: "deepseek-ai/DeepSeek-V3.1",
		Messages: []TestMessage{
			{Role: "user", Content: "Hello, how are you?"},
		},
		Stream: true,
	}

	sendTestRequest(request, "normal_chat")
}

func testLongResponse() {
	request := TestChatRequest{
		Model: "deepseek-ai/DeepSeek-V3.1",
		Messages: []TestMessage{
			{Role: "user", Content: "请详细解释什么是机器学习，包括其历史、原理、应用和未来发展趋势。请提供一个全面的回答。"},
		},
		Stream: true,
	}

	sendTestRequest(request, "long_response")
}

func testComplexReasoning() {
	request := TestChatRequest{
		Model: "deepseek-ai/DeepSeek-R1-0528-Turbo",
		Messages: []TestMessage{
			{Role: "user", Content: "解决这个数学问题：如果一个圆的面积是 50 平方厘米，那么它的周长是多少？请详细展示你的推理过程。"},
		},
		Stream: true,
	}

	sendTestRequest(request, "complex_reasoning")
}

func sendTestRequest(request TestChatRequest, testName string) {
	fmt.Printf("发送测试请求: %s\n", testName)

	// 序列化请求
	jsonData, err := json.Marshal(request)
	if err != nil {
		fmt.Printf("❌ JSON 序列化失败: %v\n", err)
		return
	}

	// 创建 HTTP 请求
	req, err := http.NewRequest("POST", "http://localhost:8000/v1/chat/completions", bytes.NewBuffer(jsonData))
	if err != nil {
		fmt.Printf("❌ 创建请求失败: %v\n", err)
		return
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer linux.do")

	// 发送请求
	client := &http.Client{Timeout: 60 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("❌ 发送请求失败: %v\n", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		fmt.Printf("❌ 响应状态码错误: %d\n", resp.StatusCode)
		return
	}

	// 读取流式响应
	fmt.Printf("📡 开始接收流式响应...\n")
	
	buffer := make([]byte, 1024)
	totalBytes := 0
	chunkCount := 0
	eventCount := 0
	errorCount := 0
	
	for {
		n, err := resp.Body.Read(buffer)
		if n > 0 {
			chunkCount++
			totalBytes += n
			chunk := string(buffer[:n])
			
			// 统计事件数量
			lines := strings.Split(chunk, "\n")
			for _, line := range lines {
				if strings.HasPrefix(line, "data: ") {
					eventCount++
					jsonText := strings.TrimSpace(line[6:])
					if jsonText != "" && jsonText != "[DONE]" {
						// 尝试解析 JSON 来检测错误
						var testResp map[string]interface{}
						if err := json.Unmarshal([]byte(jsonText), &testResp); err != nil {
							errorCount++
							fmt.Printf("⚠️  JSON 解析错误: %v\n", err)
						}
					}
				}
			}
		}
		
		if err != nil {
			if err == io.EOF {
				break
			}
			fmt.Printf("❌ 读取响应失败: %v\n", err)
			break
		}
	}

	// 输出统计信息
	fmt.Printf("📊 测试结果统计:\n")
	fmt.Printf("   • 总字节数: %d\n", totalBytes)
	fmt.Printf("   • 数据块数: %d\n", chunkCount)
	fmt.Printf("   • SSE 事件数: %d\n", eventCount)
	fmt.Printf("   • JSON 解析错误: %d\n", errorCount)
	
	if errorCount == 0 {
		fmt.Printf("✅ 测试通过：无截断问题\n")
	} else {
		fmt.Printf("❌ 测试失败：发现 %d 个截断问题\n", errorCount)
	}
	
	fmt.Println()
}
