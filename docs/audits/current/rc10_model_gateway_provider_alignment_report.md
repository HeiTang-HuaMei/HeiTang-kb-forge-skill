# rc10 Model Gateway / API Relay Provider Alignment Report

## Scope

This Stage3 slice adds Model Gateway / API Relay Provider configuration to the hot-swappable provider plan.

It is not a new core module, not an Agent runtime, not a Tool runtime, not a KB backend, and not an OKF runtime.

The user-visible concept remains providerized capability configuration:

```text
Agent / Skill / Tool -> ProjectConfigProfile -> Provider Gateway -> OpenAI-compatible gateway or direct LLM provider
```

## Implemented Runtime Assets

- `ProjectConfigProfile.model_gateway_config_id`
- `config/provider_runtime_settings.json`
- `config/model_gateway/model_gateway_config.json`
- `config/model_gateway/model_gateway_test_report.json`
- `config/model_gateway/model_gateway_usage_report.json`
- `config/model_gateway/model_gateway_fallback_report.json`
- `config/model_gateway/model_gateway_reference_registry.json`
- `config/model_gateway/model_gateway_audit.jsonl`
- `config/config_test_log.jsonl`
- `config/project_config_runtime_status.json`
- `config/project_config_assets.json`

## ModelGatewayConfig Fields

- `gateway_id`
- `display_name`
- `gateway_type`
- `base_url`
- `api_key_ref`
- `admin_url`
- `supports_streaming`
- `supports_embeddings`
- `supports_fallback`
- `supports_usage_stats`
- `timeout_seconds`
- `retry_policy`
- `status`
- `last_test_at`
- `last_error`
- `masked_key_preview`

Supported gateway types are represented as configuration values:

- `direct`
- `vercel_relay`
- `cloudflare_relay`
- `local_relay`
- `custom_openai_compatible`

## Status Model

The runtime maps gateway test modes to user-facing status labels:

- `未配置`
- `已配置未测试`
- `连接成功`
- `连接失败`
- `鉴权失败`
- `超时`
- `额度不足`
- `上游不可用`
- `fallback 已触发`

Forbidden internal labels are not written to normal runtime status as user-facing states.

## Downstream Binding

Runtime status now exposes Model Gateway state to:

- `document_generation`
- `skill_factory`
- `agent_workbench`

Agent dialogue manifests also record:

- `model_gateway_config_id`
- `model_gateway_status`
- `model_gateway_route`

This provides runtime evidence that Agent execution reads the active profile gateway binding.

## Failure Degradation

Gateway failure does not block:

- local import
- document library
- local KB index
- Markdown generation

Gateway failure degrades:

- LLM summary
- Skill generation
- Agent dialogue

Failure reasons are written in Chinese in runtime status and config test logs.

## Secret Handling

- API keys are stored as `runtime_input_not_persisted` or `none`.
- UI/runtime assets use masked key previews only.
- Endpoint query strings and fragments are stripped before persistence.
- The legacy relay API key environment label is not used in logs.
- Test logs and exports do not write plaintext credentials.

## Reference Registry Boundary

The reference registry records API relay options only as references:

- AI Relay: `needs_verification`
- Vercel Relay Deployment: `reference_only`
- Cloudflare Relay Deployment: `reference_only`
- Local Relay Mode: `reference_only`

No external relay project is marked integrated or loaded.

## Validation

- `flutter analyze`
- `flutter test test\rc6_runtime_truth_blocker_repair_test.dart --concurrency=1`

The target runtime test covers:

- masked config persistence
- sanitized Base URL and admin URL
- success, auth failure, timeout, rate limit, upstream unavailable, and fallback statuses
- runtime status synchronization
- config assets
- config test audit log
- reference-only registry boundary

## Remaining Boundary

This slice does not call a real paid API. Real provider calls require explicit endpoint authorization and Stage3 continuation after Stage2 P0/P1/P2 runtime preflight is confirmed.
