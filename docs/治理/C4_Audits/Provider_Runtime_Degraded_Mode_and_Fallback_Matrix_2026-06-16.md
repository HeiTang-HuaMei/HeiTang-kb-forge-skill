# Provider Runtime Degraded Mode and Fallback Matrix

Date: 2026-06-16

Gate: `provider_runtime_production_grade_completion_and_ui_binding_gate`

Status: `provider_runtime_production_grade_accepted_ui_bound`

## 1. Purpose

This matrix defines what the product shows and does when Provider Runtime is available, unavailable, blocked, timed out, fallback-used, or cost-blocked.

Mock/offline provider evidence is allowed only for deterministic self-checks and degraded-mode proof. It must not be presented as production Provider output.

## 2. Runtime Availability Matrix

| Runtime capability | Evidence | Result |
|---|---|---|
| Provider | `official_openai` env-only profile | pass |
| `/models` or equivalent probe | `live_llm_acceptance_report.json` | pass, HTTP 200 |
| `/chat/completions` probe | `live_llm_acceptance_report.json` | pass, HTTP 200 |
| `/responses` probe | `live_llm_acceptance_report.json` | pass, HTTP 200 |
| Response safety | `live_llm_acceptance_report.json` | response hash committed; response text not committed |
| Secret safety | `audit_redaction_check_result.json` and UI bridge tests | API key redacted; raw secret display disallowed |
| Network opt-in | `provider-live-smoke --live --allow-network` evidence | explicit Owner/network opt-in required |

## 3. Degraded Mode Matrix

| User-facing status | Trigger | Product behavior | Local continuation | User message |
|---|---|---|---|---|
| `connected` | Live Provider probes pass | Provider Runtime state is `enabled_real` | Not degraded | Provider connected; external calls still require explicit opt-in |
| `unavailable` | Provider endpoint unavailable or HTTP provider error | Do not silently fail; keep local workbench usable | KB, local retrieval, document workflows continue | Provider unavailable; local capabilities continue |
| `missing_key` | API key/base/model env missing | Block external call and keep secret hidden | Local workflows continue | Secure env is missing; plaintext keys are never shown |
| `timeout` | Provider request timeout | Retry within policy and keep log id | Local workflows continue | Request timed out; retry with log id |
| `fallback_used` | Fallback path selected | Show fallback reason; do not call it production Provider output | Local degraded path continues | Fallback used; verify result class |
| `cost_blocked` | Cost/token guard blocks request | Stop external call before spend | Local workflows continue | Cost/token boundary exceeded |

## 3.1 Local / Offline Fallback Capability Statement

When Provider Runtime is unavailable, missing credentials, timed out, fallback-used, or cost-blocked, the product remains usable for local workbench capabilities that do not require external Provider calls:

- local Knowledge Base inspection and management over existing local artifacts;
- local retrieval and validation against existing local evidence only;
- document workflows from local knowledge and cached artifacts;
- reports, audit evidence, diagnostics, and repair suggestions;
- workspace setup, storage inspection, and local configuration review.

Mock/offline provider checks remain deterministic development or degraded-mode proof only. They must not be shown as production Provider output and must not be used to claim external Provider availability.

## 3.2 Retry / Timeout / Fallback / Cost UI State Notes

| UI state | Required display |
|---|---|
| `timeout` | Show timeout class, retry guidance, and a log id; retry only within configured timeout/retry policy. |
| `fallback_used` | Show fallback reason and result class; continue local workflow but do not present fallback output as live Provider output. |
| `cost_blocked` | Show cost/token boundary reason and stop the external call before spend; local workflows continue. |
| `unavailable` | Show Provider unavailable state and local degraded mode; do not silently fail. |
| `missing_key` | Show secure env setup boundary; never show or request plaintext API key in the UI bridge. |

## 4. Failure Mode Matrix

| Failure mode | Evidence | Required UI/Bridge behavior |
|---|---|---|
| Missing key | `provider_live_smoke_optin_missing_key/provider_live_smoke_result.json` | `disabled_boundary`, clear setup prompt, no secret echo |
| Invalid key | `fallback_invalid_key/provider_fallback_test_result.json` | Show invalid credential class, no retry storm |
| Timeout | `fallback_timeout/provider_fallback_test_result.json` | Show timeout, retry guidance, log id |
| Provider unavailable | `fallback_provider_error/provider_fallback_test_result.json` | Show unavailable state, local degraded mode |
| Rate limit | `fallback_rate_limit/provider_fallback_test_result.json` | Show rate-limit class and fallback policy |
| Unsupported model | `fallback_unsupported_model/provider_fallback_test_result.json` | Show model mismatch and config guidance |
| Cancelled | `fallback_cancelled/provider_fallback_test_result.json` | Show cancelled, no fallback, no retry |
| Cost/token blocked | `llm_cost_guard_result.json` | Show cost boundary, do not call Provider |
| Secret leak risk | `audit_redaction_check_result.json` and UI bridge secret test | Block request and redact output |

## 5. Rollback / Disable Switch

Provider Runtime can be disabled without code changes:

- unset Provider API key/base/model environment variables;
- unset Owner/network opt-in variables for live calls;
- keep UI state in local degraded mode;
- continue local KB, local retrieval over existing evidence, document generation from local artifacts, reports, and audit review.

The product must show an explicit unavailable/missing-key/cost-blocked state rather than silently failing.

## 6. Known Limitations

- This gate accepts Provider Runtime, not Agent Runtime.
- Memory Runtime, Collaboration Runtime, A2A, EXE packaging, tag, release, and final product release remain out of scope.
- Mock/offline Provider checks remain development/deterministic self-check evidence only.
- Real invalid-key/timeout/unavailable live faults are represented by deterministic fallback contracts, not by intentionally burning live credentials or destabilizing the external service.
