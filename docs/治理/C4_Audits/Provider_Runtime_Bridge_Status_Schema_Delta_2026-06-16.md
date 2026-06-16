# Provider Runtime Bridge Status Schema Delta

Date: 2026-06-16

Gate: `provider_runtime_bridge_status_schema_delta_gate`

Result: `provider_runtime_bridge_status_schema_delta_partial_live_smoke_still_missing`

Scope: delta over UI/Bridge status schema and Provider Runtime behavior matrix only. No Provider Runtime rewrite, new Provider connection, dependency change, yellow marker removal, Campaign 6/7/8/9 work, tag, release, push, or commit was performed.

## 1. Summary

This Gate closes the specific UI/Bridge contract gap recorded by `Provider_Runtime_Formal_Acceptance_Report_2026-06-16.md`: there is now a frozen Provider Runtime bridge status schema and behavior matrix that maps existing provider command evidence into `accepted`, `warning_boundary`, `blocked`, `partial`, or `failed` semantics.

Provider Runtime is still not finally accepted by this Gate because approved real opt-in live provider smoke remains missing. UI yellow Provider markers must remain `disabled_boundary` until Owner accepts this delta and a final reacceptance or live-smoke decision Gate passes.

## 2. Inputs Reused

- `Provider_Runtime_Formal_Acceptance_Report_2026-06-16.md`
- `kb-forge-skill/artifacts/audits/provider_runtime_formal_acceptance_2026-06-16`
- Existing provider command evidence from `provider-config-validate`, `provider-readiness`, `provider-security-audit`, `audit-redaction-check`, `provider-fallback-test`, `llm-cost-guard`, `provider-live-smoke`, and `llm-live-smoke`
- Existing UI contract fixture `kb-forge-skill-ui/web/workbench/flutter_app/assets/contracts/p1_core_contract_fixture.json`
- Existing bridge code `kb-forge-skill-ui/web/workbench/flutter_app/lib/core_bridge/local_core_bridge.dart`
- Existing Provider UI boundary text in `kb-forge-skill-ui/web/workbench/flutter_app/lib/main.dart`

## 3. Changed Files

- `kb-forge-skill-ui/web/workbench/flutter_app/assets/contracts/provider_runtime_bridge_status_schema_delta_2026_06_16.json`
- `kb-forge-skill-ui/web/workbench/flutter_app/test/provider_runtime_bridge_status_schema_delta_test.dart`
- `kb-forge-skill-ui/web/workbench/flutter_app/pubspec.yaml`
- `Provider_Runtime_Bridge_Status_Schema_Delta_2026-06-16.md`

## 4. Status Schema

| Bridge status | UI state allowed by this Gate | Meaning |
|---|---|---|
| `accepted` | `display_only` or future accepted binding | Existing evidence is sufficient for the named local command or boundary. It does not prove full external Provider Runtime acceptance alone. |
| `warning_boundary` | `display_only` | Command completed with intentional warning semantics, such as cost guard or no-network live-smoke boundary. |
| `blocked` | `disabled_boundary` | Execution must stop because secret, network opt-in, or configuration prerequisites are missing or unsafe. |
| `partial` | `disabled_boundary` or `display_only` | Existing command evidence is reusable but does not prove the full live runtime path. |
| `failed` | `disabled_boundary` | Contract, security, or command evidence is missing or explicitly failed. |

UI marker policy frozen by this Gate:

- Provider yellow marker removal allowed: no.
- Current UI state: `disabled_boundary`.
- Post-delta UI state: `disabled_boundary`.
- `enabled_real` requires final Provider acceptance evidence and explicit Owner authorization.

## 5. Runtime Behavior Matrix

| Required item | Existing command evidence | Bridge status | UI state | Evidence |
|---|---|---|---|---|
| Provider config schema validation | `provider-config-validate` | `accepted` | `display_only` | `outputs/provider_config_validate_default/provider_config_validate_result.json` |
| Provider registry / profile readiness | `provider-registry-export`, `provider-list`, `provider-health`, `provider-readiness` | `accepted` | `display_only` | `outputs/provider_health/provider_health_result.json` |
| Secret redaction / leak prevention | `provider-security-audit`, `audit-redaction-check` | `accepted` | `display_only` | `outputs/audit_redaction_check/audit_redaction_check_result.json` |
| Missing key behavior | `provider-live-smoke --live --allow-network` without configured key/base URL | `blocked` | `disabled_boundary` | `outputs/provider_live_smoke_optin_missing_key/provider_live_smoke_result.json` |
| Invalid key behavior | `provider-fallback-test --scenario invalid_key` | `partial` | `disabled_boundary` | `outputs/fallback_invalid_key/provider_fallback_test_result.json` |
| Timeout behavior | `provider-fallback-test --scenario timeout` | `partial` | `disabled_boundary` | `outputs/fallback_timeout/provider_fallback_test_result.json` |
| Provider unavailable behavior | `provider-fallback-test --scenario provider_error` | `partial` | `disabled_boundary` | `outputs/fallback_provider_error/provider_fallback_test_result.json` |
| Fallback behavior | `provider-fallback-test` scenarios | `accepted` for simulation evidence | `display_only` | `outputs/fallback_rate_limit/provider_fallback_test_result.json` |
| Cost / token guard behavior | `llm-cost-guard` | `warning_boundary` | `display_only` | `outputs/llm_cost_guard/llm_cost_guard_result.json` |
| Live smoke opt-in boundary | `provider-live-smoke`, `llm-live-smoke --provider mock` | `partial` | `disabled_boundary` | `outputs/provider_live_smoke_no_optin/provider_live_smoke_result.json` |
| UI/Bridge status contract evidence | New schema fixture and bridge tests | `accepted` | `disabled_boundary` | `provider_runtime_bridge_status_schema_delta_2026_06_16.json` |
| Overclaim scan | Static scan over delta files and boundary text | `accepted` | `display_only` | Validation logs |

## 6. Bridge Binding Rules

- UI bridge requests must not carry provider secrets in environment variables or command arguments.
- Network calls require explicit opt-in.
- Live smoke evidence is not formal runtime acceptance by itself.
- Raw secrets must never be displayed.
- Existing Provider UI entries stay yellow / `disabled_boundary`.
- Future UI binding may display accepted local evidence only after Owner accepts this delta.
- Future `enabled_real` requires final Provider Runtime reacceptance and explicit Owner authorization.

## 7. Tests Added

`provider_runtime_bridge_status_schema_delta_test.dart` verifies:

- the delta result remains `provider_runtime_bridge_status_schema_delta_partial_live_smoke_still_missing`;
- the schema fixture is bundled for future UI consumption;
- runtime rewrite, new Provider connection, dependency addition, and yellow marker removal are all false;
- the behavior matrix covers all required acceptance items;
- missing-key and live-smoke paths remain `disabled_boundary`;
- existing Provider actions in the UI contract do not become executable bridge requests;
- the local bridge rejects Provider secret environment variables;
- the schema fixture does not claim completed Provider, Agent, Memory, Collaboration, or A2A runtime families.

## 8. Commands Executed

| Command | Result | Exit code | Log path |
|---|---:|---:|---|
| `flutter test test/provider_runtime_bridge_status_schema_delta_test.dart --concurrency=1` | blocked before test suite load by local websocket/proxy 502 | 1 | `kb-forge-skill-ui/web/workbench/flutter_app/provider_runtime_bridge_status_schema_delta_test.log` |
| `dart format test/provider_runtime_bridge_status_schema_delta_test.dart` | pass | 0 | `kb-forge-skill-ui/web/workbench/flutter_app/provider_runtime_bridge_status_schema_delta_format.log` |
| `NO_PROXY=localhost,127.0.0.1,::1 flutter test test/provider_runtime_bridge_status_schema_delta_test.dart --concurrency=1` | pass, 5 tests | 0 | `kb-forge-skill-ui/web/workbench/flutter_app/provider_runtime_bridge_status_schema_delta_test_no_proxy.log` |
| `dart format test/provider_runtime_bridge_status_schema_delta_test.dart` | pass | 0 | `kb-forge-skill-ui/web/workbench/flutter_app/provider_runtime_bridge_status_schema_delta_format_final3.log` |
| `NO_PROXY=localhost,127.0.0.1,::1 flutter analyze` | pass | 0 | `kb-forge-skill-ui/web/workbench/flutter_app/provider_runtime_bridge_status_schema_delta_analyze_final3.log` |
| `NO_PROXY=localhost,127.0.0.1,::1 flutter test test/provider_runtime_bridge_status_schema_delta_test.dart --concurrency=1` | pass, 6 tests | 0 | `kb-forge-skill-ui/web/workbench/flutter_app/provider_runtime_bridge_status_schema_delta_test_final4.log` |
| `python schema/report validation script` | pass | 0 | `Provider_Runtime_Bridge_Status_Schema_Delta_validation_final2.log` |
| `rg overclaim scan` | pass, no hits | 0 | `Provider_Runtime_Bridge_Status_Schema_Delta_overclaim_scan_final3.log` |
| `git diff --check` | pass with pre-existing CRLF warnings only | 0 | `kb-forge-skill-ui/provider_runtime_bridge_status_schema_delta_diff_check_final3.log` |

## 9. Known Gaps

- Approved real external provider live smoke was not run in this Gate.
- The previous Formal Acceptance Gate recorded two provider/LLM pytest subsets blocked by legacy evidence JSON parse errors; this delta does not resolve that legacy pytest configuration blocker.
- Timeout, invalid credential, unavailable provider, and fallback remain accepted only as existing simulation or boundary evidence unless Owner accepts that scope in final reacceptance.
- Cancellation behavior is still not covered by the provider command evidence from the previous Gate.
- UI yellow markers are intentionally unchanged.

## 10. Acceptance Decision

Accepted state selected from the allowed outcomes:

`provider_runtime_bridge_status_schema_delta_partial_live_smoke_still_missing`

Rationale:

- The UI/Bridge status schema and runtime behavior matrix gap is addressed.
- The local bridge secret boundary remains enforced.
- Existing Provider UI contract actions remain non-executable while yellow markers are present.
- Approved real opt-in live provider smoke is still missing, so this Gate cannot claim readiness to remove yellow markers.

## 11. Next Required Gate

Next required Gate:

`provider_runtime_final_reacceptance_or_live_smoke_owner_decision_gate`

Owner decisions required:

- Decide whether approved real opt-in live provider smoke is required before final Provider acceptance.
- Decide whether existing fallback simulations are acceptable for timeout, invalid key, unavailable provider, and fallback behavior, or whether real endpoint evidence is required.
- Decide whether the legacy pytest configuration blocker must be fixed before final Provider acceptance.
- After those decisions, authorize a final Provider reacceptance review before any UI marker change.

Stop status:

`provider_runtime_bridge_status_schema_delta_partial_live_smoke_still_missing`
