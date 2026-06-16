# Provider Runtime Gate Scope Freeze

Date: 2026-06-16

Status: `provider_runtime_gate_scope_frozen_pending_owner_review`

Scope: planning and acceptance-boundary freeze only. This document does not authorize implementation, Core changes, UI changes, Campaign 5, Campaign 6, Campaign 7, Post-9 runtime work, commit, push, tag, release, or external runtime installation.

Suggested future location after Owner confirms repository layout: `docs/campaigns/campaign_4_capability_gap_completion/provider_runtime_gate_scope_freeze.md`.

## 1. Goal Definition

Provider Runtime Gate establishes the minimum formally accepted provider runtime boundary required before Campaign 6 Agent Foundation can depend on external or local model providers.

The Gate must prove that provider use is explicit, configurable, observable, cancellable, failure-tolerant, redacted, and offline-safe. It must not turn any Agent Runtime, Memory Runtime, A2A, Collaboration, Sandbox, or Post-9 capability into an available feature.

The Gate distinguishes these states:

- `contract_ready`: profile schema, validation, security rules, and offline behavior are defined and tested.
- `experimental_live_smoke`: an opt-in provider call proves credentials and network path can work for one configured provider.
- `formal_provider_runtime`: accepted runtime contract covering profile loading, Secret injection, opt-in network, timeout, retry, fallback, cancel, health check, live smoke, redaction, error normalization, cost/token evidence, audit evidence, and offline degradation.
- `agent_runtime`: out of scope; not created by this Gate.

## 2. In Scope

- Provider profile schema and validation.
- Provider registry read/list/validate behavior.
- Endpoint, model, provider type, and stage selection fields.
- Secret reference by environment variable or approved secret handle.
- Redaction for logs, UI, reports, errors, and audit artifacts.
- Explicit opt-in network switch.
- Offline default behavior.
- Request timeout policy.
- Retry policy with bounded attempts.
- Fallback provider or fallback-to-offline policy.
- Cancellation contract.
- Error normalization.
- Health check contract.
- Opt-in live smoke contract.
- Cost and token usage evidence fields.
- Local model configuration boundary.
- Provider disabled state and unavailable behavior.
- UI state rules for removing yellow `disabled_boundary` only after Owner acceptance.
- Acceptance command matrix and test matrix.

## 3. Out of Scope

- Agent creation, editing, saving, versioning, running, session tracing, or orchestration.
- Campaign 6 Agent Foundation.
- Campaign 7 configuration engineering beyond fields required to freeze this Gate.
- Memory Runtime, Collaboration Runtime, A2A, Agent Teams, Subagent, Computer Use, Sandbox, Graphify, or Knowledge Graph Storage Runtime.
- Default network access.
- Default external provider enablement.
- Secret storage in plaintext files.
- Installing or bundling unapproved external runtimes.
- Treating `provider-live-smoke`, mock harnesses, or skipped integration tests as formal Provider Runtime acceptance.
- UI yellow marker removal before `provider_runtime_gate_accepted_by_owner`.

## 4. Provider Profile Minimum Fields

Minimum profile object:

```yaml
provider_id: local_unique_id
provider_type: openai_compatible | local_http | local_model | mock | custom_http
display_name: Human readable name
enabled: false
network_opt_in: false
endpoint: https://example.invalid/v1
model: model-name
stage: draft | validation | generation | retrieval | agent_foundation
api_key_env: HEITANG_PROVIDER_API_KEY
timeout_ms: 30000
retry:
  max_attempts: 2
  backoff_ms: 500
fallback:
  mode: disabled | offline_only | provider_id
  provider_id: null
cost_tracking:
  currency: USD
  prompt_token_unit_cost: null
  completion_token_unit_cost: null
redaction:
  redact_request_body: true
  redact_response_body: false
audit:
  write_request_id: true
  write_token_usage: true
  write_cost_estimate: true
```

Required validation:

- `provider_id` is stable, unique, and file-name safe.
- `enabled` defaults to `false`.
- `network_opt_in` defaults to `false`.
- External HTTP providers require both `enabled=true` and `network_opt_in=true`.
- `api_key_env` is a variable name only, never a literal key.
- `endpoint` must not contain credentials.
- `timeout_ms` must be bounded.
- retry attempts must be bounded.
- fallback must never silently switch to an external provider without opt-in.

## 5. Secret Injection And Redaction Rules

Secret rules:

- Secrets are referenced by environment variable name or approved OS secret handle only.
- Secrets are injected at request execution time only.
- Secrets are never persisted into provider profiles, logs, reports, screenshots, UI state, test snapshots, or audit bundles.
- UI may show `configured`, `missing`, or masked form such as `sk-************`; it must not show raw values.
- Validation must fail profiles that contain likely literal secrets in `endpoint`, `model`, `api_key_env`, headers, logs, or saved reports.
- Failed credential errors must be normalized without echoing provider response bodies that may include sensitive material.

Redaction must cover:

- request headers
- request body fields that can contain prompts or personal data
- response body fields when configured
- exception messages
- debug logs
- audit evidence
- Flutter UI diagnostics
- CLI output

## 6. Opt-In Network Switch Rules

Network defaults:

- Global network default: off.
- Per-provider `network_opt_in`: false by default.
- Per-run network consent: required for live smoke and real external calls.
- CI/test default: offline unless integration opt-in is explicitly set.

An external provider call is allowed only when all are true:

- provider profile validates
- provider `enabled=true`
- provider `network_opt_in=true`
- run command passes explicit live/network flag
- required Secret reference resolves
- redaction is active
- audit output path is configured

Local model providers still require explicit enablement, but may not require network opt-in if they use a local-only endpoint. Local endpoints must still be classified and audited.

## 7. Timeout / Retry / Fallback / Cancel Strategy

Timeout:

- default timeout: 30 seconds
- maximum accepted timeout: bounded by Owner-approved test value
- timeout returns normalized `provider_timeout`
- timeout must include request id, provider id, model, elapsed ms, and redacted context

Retry:

- default retry attempts: 0 or 1 retry after the initial attempt
- retry only for retryable classes: timeout, 429/rate limit, transient 5xx, temporary connection reset
- no retry for invalid credential, permission denied, malformed request, disabled provider, missing Secret, or network not opted in
- retry must preserve cancellation

Fallback:

- fallback is explicit and declared in the profile
- fallback to another external provider requires that target provider also passes opt-in rules
- offline fallback may return `provider_offline_degraded` with local-only behavior
- fallback must be visible in audit evidence

Cancel:

- every provider request receives a cancellable task id
- cancel must stop waiting, normalize result as `cancelled`, and avoid writing partial unredacted output
- UI cancel can become enabled only after Bridge/task cancellation is confirmed in the accepted implementation phase

## 8. Health Check Vs Live Smoke

Health check:

- validates configuration shape
- checks Secret presence without printing it
- checks endpoint reachability only when network opt-in is true
- may run offline for local profile validation
- does not prove generation quality
- does not prove formal Provider Runtime acceptance by itself

Live smoke:

- performs one minimal opt-in provider call
- requires explicit live and network flags
- writes redacted request/response metadata
- records latency, status, provider id, model, token/cost fields when available
- can prove a configured provider path works once
- still does not equal formal Provider Runtime unless the full runtime test matrix passes and Owner accepts the Gate

Formal Provider Runtime:

- includes profile validation, health, live smoke, timeout, retry, fallback, cancel, invalid credential, unavailable provider, offline behavior, redaction, cost/token, audit, Windows compatibility, and UI state rules.

## 9. Degradation Strategy

Offline:

- Provider features remain disabled or local-only.
- UI keeps yellow `disabled_boundary`.
- commands return `provider_offline_degraded` or equivalent normalized status.
- no network attempt is made.
- local deterministic workflows continue when they do not require provider calls.

Invalid credential:

- no retry.
- normalized status: `provider_invalid_credential`.
- Secret is never printed.
- UI shows actionable message: credential missing/invalid, check Secret configuration.
- audit stores provider id, model, request id, timestamp, redacted error class.

Provider unavailable:

- retry only if retry policy allows transient failure.
- fallback only if explicitly configured and accepted by opt-in rules.
- normalized status: `provider_unavailable` or `provider_fallback_used`.
- UI must not mark provider as connected.
- failed live smoke cannot remove yellow markers.

Provider disabled:

- no request attempted.
- normalized status: `provider_disabled`.
- UI remains `disabled_boundary`.

## 10. UI State Transition From Yellow To `enabled_real`

Yellow markers may be removed only after all conditions are true:

1. Provider Runtime Gate implementation is explicitly authorized by Owner.
2. Full Provider Runtime test matrix passes.
3. Secret leakage scan passes.
4. Opt-in live smoke passes for at least one approved provider profile.
5. Offline, invalid credential, unavailable provider, timeout, retry, fallback, and cancel evidence exists.
6. Owner accepts the Gate with status `provider_runtime_gate_accepted_by_owner`.
7. UI receives accepted runtime status from Core/Bridge or approved evidence file.

Allowed UI changes after acceptance:

- Provider configuration actions may move from `disabled_boundary` to `enabled_real`.
- Provider health check may become enabled.
- Provider live smoke may become enabled only behind explicit opt-in.
- Provider connection status may show connected only for a validated active profile.
- Secret display remains masked or status-only.

Still yellow or hidden after Provider Gate:

- Agent Runtime
- Agent sessions
- Memory Runtime
- Collaboration Runtime
- A2A
- Sandbox
- Graphify
- Post-9 orchestration

## 11. Acceptance Commands And Test Matrix

Existing command candidates to audit during implementation planning:

- `provider-list`
- `provider-config-validate`
- `provider-registry-export`
- `provider-readiness`
- `provider-security-audit`
- `provider-live-smoke`
- `provider-fallback-test`
- `llm-live-smoke`
- `audit-redaction-check`
- `llm-cost-guard`

Final command names may change only with Owner-approved implementation scope. This freeze document does not require command changes.

Minimum acceptance matrix:

| Area | Required evidence | Required result |
|---|---|---|
| Profile schema | valid and invalid profile tests | invalid fields fail closed |
| Secret handling | literal-secret scan and env-only injection tests | no raw Secret in files, logs, UI, reports |
| Network consent | no opt-in, provider opt-in only, run opt-in only, both opt-ins | external call only when all required opt-ins are true |
| Health check | offline profile check, missing Secret, reachable endpoint when opted in | normalized health statuses |
| Live smoke | opt-in smoke with redacted evidence | smoke evidence exists but is not called formal runtime alone |
| Timeout | forced slow provider | `provider_timeout`, bounded elapsed time |
| Retry | transient 429/5xx/connection reset | bounded retry count, audit trail |
| Fallback | unavailable primary with configured fallback | explicit fallback evidence or offline degradation |
| Cancel | cancelled in-flight request | `cancelled`, no partial unredacted output |
| Invalid credential | wrong Secret | no retry, no Secret echo, normalized failure |
| Provider unavailable | unreachable endpoint | normalized unavailable/fallback/offline behavior |
| Cost/token | provider returns usage or local estimate | token/cost fields recorded or marked unavailable |
| Redaction | logs, reports, exceptions, UI diagnostics | no raw Secret or unsafe payload leak |
| Windows compatibility | paths, env vars, process behavior | passes on Windows desktop target |
| UI state | yellow marker transition tests | yellow removed only after accepted evidence |
| Overclaim scan | Provider/Agent/Memory/A2A forbidden claim scan | no forbidden claim |

Suggested verification command set for the future implementation phase:

```powershell
python -m pytest tests -q
python -m pytest tests/test_provider* -q
python -m pytest tests/test_*redaction* tests/test_*secret* -q
python -m pytest tests/test_*cost* tests/test_*fallback* -q
python -m heitang_kb_forge.cli provider-config-validate --output <out>
python -m heitang_kb_forge.cli provider-readiness --workspace <workspace> --output <out>
python -m heitang_kb_forge.cli provider-security-audit --workspace <workspace> --output <out>
python -m heitang_kb_forge.cli provider-fallback-test --output <out> --scenario timeout
python -m heitang_kb_forge.cli provider-live-smoke --output <out> --provider-id <id> --live --allow-network
rg -n "sk-[A-Za-z0-9]|api_key|authorization bearer token pattern|Provider Runtime complete|Agent Runtime complete|Memory Runtime complete|A2A complete" .
git diff --check
```

Live or integration commands must be skipped unless Owner explicitly authorizes network use and provides a safe credential path.

## 12. Claims Not Allowed

Do not claim:

- Provider Runtime complete before Owner accepts this Gate.
- live smoke equals formal Provider Runtime.
- mock/offline harness equals real provider runtime.
- provider is connected when only a profile exists.
- network is enabled by default.
- Secret is stored or shown safely if raw values are present anywhere.
- Agent Runtime is complete.
- Campaign 6 is open or complete.
- Campaign 7 completed Provider Runtime.
- Memory Runtime, Collaboration Runtime, A2A, Sandbox, Agent Teams, Subagent, Computer Use, or Graphify is available.
- Final Release, EXE packaging, GitHub Release, tag, or stable runtime is complete.

## Stop Point

Stop status: `provider_runtime_gate_scope_frozen_pending_owner_review`

Next safe action: Owner reviews this scope freeze. Implementation must not begin until Owner explicitly authorizes Provider Runtime Gate implementation.
