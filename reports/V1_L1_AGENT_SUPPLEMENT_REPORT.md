# V1 L1 Agent Supplement Report

Generated: 2026-06-30

## 1. Scope

This report confirms Agent evidence includes friendly unconfigured-model handling, no internal error exposure, and explicit LLM live-smoke condition handling.

## 2. Test Input

Agent package evidence:

`output/v1_l1_backend_deepwater/agent_screenshots/`

Packaged UI refresh screenshot:

`output/v1_l1_backend_deepwater/post_fix_refresh_screenshots/phase12_08_agent_failure_state_refresh.png`

## 3. Execution Path

Existing L1 Agent paths:

- `python -m heitang_kb_forge.cli generate-agent ...`
- local fake-provider Agent ask path
- openai-compatible placeholder rerun after repair
- packaged UI Agent failure-state refresh

Supplement LLM condition commands:

`python -m heitang_kb_forge.cli llm-live-smoke --output output/v1_l1_final_capability/agent_llm_smoke --provider openai-compatible --model owner-configured-model --base-url-env HEITANG_LLM_BASE_URL --api-key-env HEITANG_LLM_API_KEY --allow-network`

`python -m heitang_kb_forge.cli provider-live-smoke --output output/v1_l1_final_capability/provider_live_smoke --provider-id openai_compatible_generic --live --allow-network`

Logs:

- `reports/v1_l1_final_capability_logs/agent_llm_live_smoke.log`
- `reports/v1_l1_final_capability_logs/agent_llm_live_smoke_retry.log`
- `reports/v1_l1_final_capability_logs/provider_live_smoke.log`

## 4. Evidence Paths

Existing Agent evidence:

- `reports/V1_L1_BACKEND_DEEPWATER_AGENT_RUNTIME_REPORT.md`
- `output/v1_l1_backend_deepwater/agent_screenshots/agent_fake_ask/answer_report.json`
- `output/v1_l1_backend_deepwater/agent_screenshots/agent_openai_placeholder_rerun/answer.md`
- `output/v1_l1_backend_deepwater/agent_screenshots/agent_openai_placeholder_rerun/answer_report.json`
- `output/v1_l1_backend_deepwater/post_fix_refresh_screenshots/phase12_08_agent_failure_state_refresh.png`

Supplement LLM condition evidence:

- `output/v1_l1_final_capability/agent_llm_smoke/llm_live_smoke_result.json`
- `output/v1_l1_final_capability/agent_llm_smoke/llm_live_smoke_report.md`
- `output/v1_l1_final_capability/agent_llm_smoke_retry/llm_live_smoke_result.json`
- `output/v1_l1_final_capability/agent_llm_smoke_retry/llm_live_smoke_report.md`
- `output/v1_l1_final_capability/provider_live_smoke/provider_live_smoke_result.json`
- `output/v1_l1_final_capability/provider_live_smoke/provider_live_smoke_report.md`

## 5. Observed Values

| Check | Result |
| --- | --- |
| No assistant created / no model configured friendly state | pass |
| User-facing prompt | pass, packaged UI shows `请先配置模型服务` |
| Core friendly message | pass, "Model service is not configured..." |
| Provider / Adapter / stack trace exposure | not observed in packaged UI refresh |
| Fake-provider local Agent ask | pass with citations |
| Live LLM smoke if available | not available to CLI automation environment |
| External service retry | executed once after initial unavailable result |
| External service condition handling | pass, live-smoke and retry results explicitly record `external_service_unavailable` equivalent condition and do not fake pass |
| Secret leakage | not observed |

## 6. LLM Smoke Boundary

The CLI automation environment did not expose `HEITANG_LLM_BASE_URL` or `HEITANG_LLM_API_KEY`.

The first live-smoke attempt and one retry both recorded provider base URL / API key env as not configured for this automation process. This is classified as `external_service_unavailable` for the automated CLI path.

Therefore this supplement does not claim a real external LLM call passed. It records the condition explicitly as external service unavailable to this automation path and keeps the friendly unconfigured failure-state as the V1.0 evidence.

This does not override any Owner-side UI configuration fact. It only records what the local automated evidence path could verify.

## 7. Result

Status:

pass

Risk:

P0 = 0, P1 = 0, P2 = 1, P3 = 0

P2 item:

live external LLM smoke should be rerun when live credentials are intentionally exposed to the CLI/package validation environment.

Fix required:

No.

## 8. Safety Checks

`capability_chain_status.json` diff:

empty

ready-claim scan:

clean / non-claim only after classification
