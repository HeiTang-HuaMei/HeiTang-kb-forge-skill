# v2.6 Provider Governance

v2.6 adds Preview LLM provider governance for user-configured provider profiles. It does not require official OpenAI as the only live provider, and it does not bundle or recommend any unofficial proxy.

## Provider Coverage

The built-in registry covers provider profile types only:

* official_openai
* official_vendor
* openai_compatible_proxy
* local_model
* custom_http

Each provider record includes adapter type, env variable names, optional default base URL, timeout, retry, capability flags, docs URL, status, and risk notes. `openai_compatible_proxy` is a user-configured boundary and is not equivalent to `official_openai`.

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

Provider credentials are env-only. API key values must not be written to config, output, audit reports, logs, or test fixtures. Live provider calls require explicit `--live` and `--allow-network`; normal tests and default commands remain offline. No shared keys are stored.

## Adapter Strategy

Provider profiles share the same redaction and opt-in live-smoke policy. Official vendor, local model, OpenAI-compatible proxy, and custom HTTP profiles must be supplied by the user. Third-party proxy behavior is treated as user-managed and must not be claimed equivalent to official APIs.

## Fallback and Cost Guard

The fallback tester simulates timeout, provider error, rate limit, invalid key, and unsupported model cases without network calls. The cost guard checks prompt length, output token limits, and unknown pricing warnings.

## Known Limits

Live smoke is Preview. v2.6 does not claim all providers were live-tested. Production-grade multi-model routing remains reserved for the roadmap.
