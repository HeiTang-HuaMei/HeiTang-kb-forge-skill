# v2.6 Provider Governance

v2.6 新增 Preview 级 LLM Provider 治理能力，用于用户自配置 provider profile。产品不要求 official OpenAI 是唯一 live provider，也不内置或推荐任何非官方代理。

## Provider 覆盖

内置 registry 只覆盖 provider profile 类型：

* official_openai
* official_vendor
* openai_compatible_proxy
* local_model
* custom_http

每个 Provider 记录包含 adapter type、环境变量名、可选默认 base URL、超时、重试、能力标记、文档 URL、状态和风险说明。`openai_compatible_proxy` 是用户自配置边界，不等价于 `official_openai`。

## 命令

```powershell
python -m heitang_kb_forge.cli provider-list
python -m heitang_kb_forge.cli provider-registry-export --output .\tmp_v26\registry
python -m heitang_kb_forge.cli provider-config-validate --output .\tmp_v26\validate
python -m heitang_kb_forge.cli provider-health --output .\tmp_v26\health
python -m heitang_kb_forge.cli provider-security-audit --workspace .\tmp_v26_workspace --output .\tmp_v26\security
python -m heitang_kb_forge.cli provider-fallback-test --output .\tmp_v26\fallback --scenario timeout
python -m heitang_kb_forge.cli audit-redaction-check --output .\tmp_v26\redaction
python -m heitang_kb_forge.cli llm-cost-guard --output .\tmp_v26\cost --prompt-chars 13000 --output-tokens 5000
python -m heitang_kb_forge.cli provider-live-smoke --output .\tmp_v26\live
python -m heitang_kb_forge.cli llm-live-smoke --output .\tmp_v26\llm-live --provider mock
```

## 安全边界

Provider 凭据只允许通过环境变量提供。API key 值不能写入配置、输出、审计报告、日志或测试 fixture。真实 live call 必须显式传入 `--live` 和 `--allow-network`；默认命令和常规测试保持离线。Core 不保存 shared keys。

## Adapter 策略

Provider profiles 共用 redaction 和 opt-in live-smoke 策略。Official vendor、local model、OpenAI-compatible proxy、custom HTTP profiles 都必须由用户自行提供。第三方代理行为属于 user-managed，不得声称等价于官方 API。

## Fallback 与 Cost Guard

fallback tester 离线模拟 timeout、provider error、rate limit、invalid key、unsupported model。cost guard 检查 prompt length、output token limit 和 unknown pricing warning。

## 已知限制

Live smoke 是 Preview。v2.6 不宣称所有 Provider 都已真实 live-tested。生产级 multi-model routing 仍保留在 Roadmap/Reserved。
