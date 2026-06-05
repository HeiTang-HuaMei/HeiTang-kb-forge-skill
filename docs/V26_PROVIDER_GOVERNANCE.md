# v2.6 Provider Governance

v2.6 adds Preview LLM provider governance for domestic and international providers.

## Provider Coverage

The built-in registry covers:

* openai
* anthropic
* gemini
* openrouter
* openai_compatible_generic
* qwen_dashscope
* deepseek
* kimi_moonshot
* zhipu_glm
* baidu_qianfan
* tencent_hunyuan
* minimax
* volcengine_doubao

Each provider record includes region, adapter type, env variable names, default base URL, timeout, retry, capability flags, docs URL, status, and risk notes.

## Commands

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

## Security Boundary

Provider credentials are env-only. API key values must not be written to config, output, audit reports, logs, or test fixtures. Live provider calls require explicit `--live` and `--allow-network`; normal tests and default commands remain offline.

## Adapter Strategy

OpenAI-compatible providers share the OpenAI-compatible adapter contract. Anthropic and Gemini are config adapters in v2.6. Providers that are not fully live implemented are still validated as config-only registry entries.

## Fallback and Cost Guard

The fallback tester simulates timeout, provider error, rate limit, invalid key, and unsupported model cases without network calls. The cost guard checks prompt length, output token limits, and unknown pricing warnings.

## Known Limits

Live smoke is Preview. v2.6 does not claim all providers were live-tested. Production-grade multi-model routing remains reserved for the roadmap.
