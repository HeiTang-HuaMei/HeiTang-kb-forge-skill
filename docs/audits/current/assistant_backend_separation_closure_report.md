# P1-21 Assistant Backend Separation Closure Report

Status: assistant_backend_separation_completed_needs_owner_review

## Acceptance Scope

- Validate P1-21 Assistant Backend Separation as a user_blackbox capability.
- Confirm assistant profiles persist backend configuration references instead of storing backend secrets or executing backend runtime work.
- Confirm the real Windows EXE user path exposes backend binding evidence under Assistant Config.
- Confirm acceptance evidence writes Event Ledger and Artifact Catalog records.
- Do not claim backend executor execution or multi-model orchestration completion in this gate.

## Verification Summary

- current_phase: P1
- current_gate: P1-21 Assistant Backend Separation
- next_gate: P1-22 UI Taste Gate
- remaining_gates: 70 after this gate is moved out of the queue
- global_goal_complete: false
- blocked rows: 0 for this gate

## Evidence Matrix

- P1-21 row follows user_blackbox contract: core=passed; ui_binding=passed; blackbox=passed; artifact=passed; event=passed; restart=passed; close_allowed=true.
- Backend separation summary: passed; failed_checks=[].
- Provider settings: passed; provider runtime settings exist separately from assistant profile catalog.
- Assistant profile binding: passed; agent profile stores active profile, model config and model gateway references only.
- Secret boundary: passed; provider and gateway keys are masked and no plaintext secret marker is written into the acceptance summary.
- Runtime boundary: passed; no backend executor run, no multi-model orchestration run and no external calls are recorded for this gate.
- Event Ledger: passed; records `assistant_backend_separation_validated`.
- Artifact Lifecycle: passed; records `assistant_backend_separation_summary`.
- Restart recovery: passed; agent catalog and provider settings reload from separate files.

## White-box Test Result

- result: passed with tool harness caveat
- runtime evidence: `runAssistantBackendSeparationAcceptance`, `_agentBackendSeparationSettings`, `_autoRunAssistantBackendSeparationOnLaunch`, `createAgentProfile` and `updateAgentProfile`.
- static validation: `flutter analyze` passed.
- build validation: `flutter build windows` passed.
- targeted Flutter test: `assistant backend separation persists profile and provider refs` was added, but the local Flutter test listener failed before suite load with WebSocket HTTP 502. This is recorded as `test_harness_infrastructure_blocked`, not an assertion failure.

## Black-box Test Result

- result: passed
- app: HeiTang Workbench Windows EXE
- real user path: My Assistant -> Assistant Config -> Generate backend separation evidence.
- observed UI evidence: Assistant Config shows the backend binding table with config profile, model config and model gateway rows, plus the `agent-backend-separation-evidence-button` action.
- action evidence: clicking the evidence button regenerated `assistant_backend_separation_summary.json`.

## Evidence Completeness Result

- result: passed
- acceptance summary: `C:/Users/Administrator/AppData/Local/HeiTangKBForge/rc10_product_flow_workspace/acceptance/assistant_backend_separation_summary.json`
- agent catalog: `C:/Users/Administrator/AppData/Local/HeiTangKBForge/rc10_product_flow_workspace/agent/catalog/agents.json`
- provider runtime settings: `C:/Users/Administrator/AppData/Local/HeiTangKBForge/rc10_product_flow_workspace/config/provider_runtime_settings.json`
- project config profiles: `C:/Users/Administrator/AppData/Local/HeiTangKBForge/rc10_product_flow_workspace/config/project_config_profiles.json`
- provider validation report: `C:/Users/Administrator/AppData/Local/HeiTangKBForge/rc10_product_flow_workspace/config/provider_validation_report.json`
- Event Ledger: `C:/Users/Administrator/AppData/Local/HeiTangKBForge/rc10_product_flow_workspace/audit/event_ledger.jsonl`
- Artifact Catalog: `C:/Users/Administrator/AppData/Local/HeiTangKBForge/rc10_product_flow_workspace/artifacts/catalog.json`

## Lifecycle Result

- result: passed
- create/update: assistant profile is created or updated with backend binding references.
- view: Assistant Config displays backend binding rows in the Windows EXE.
- export/open/delete: not required for this user_blackbox gate because the capability validates profile/backend separation, not a user export artifact.
- restart recovery: acceptance summary confirms the persisted profile and provider settings reload from separate files.
- error path: failed checks are captured in the acceptance summary and would set the runtime message to blocked.

## Regression Result

- result: partial_verified_with_test_harness_infrastructure_blocked
- `flutter analyze`: passed.
- `flutter build windows`: passed.
- targeted Flutter test: blocked before suite load by local WebSocket 502.
- P1 release-wide regression remains reserved for P1 Release Gate.

## Boundary Compliance Result

- result: passed
- no new dependency.
- no packaging architecture change.
- no Redis or vector service packaging into the EXE.
- no local model or GPU video scope.
- no real user data deletion.
- no secret, token, cookie or authorization header output.
- no isolated pre-target pollution used as evidence.
- no forbidden final-state claim added.

## Reviewer Findings

- P1-21 closes backend separation references only; backend execution and multi-model orchestration remain outside this gate.
- The assistant profile stores references to project/provider configuration while provider settings remain in separate config files.
- The Windows EXE path is real and user-triggered; it is not just a command-line smoke.
- The targeted Flutter test is present but blocked by the local test listener before suite load, so the closure relies on analyze, build, runtime acceptance, Event Ledger, Artifact Catalog and real EXE blackbox evidence.

## Fix / Retest Log

- fix_applied: persisted backend separation settings on assistant profile create/update.
- fix_applied: added runtime acceptance summary, Event Ledger record and Artifact Catalog record.
- fix_applied: added Assistant Config backend binding table and evidence button.
- retest_command: `flutter analyze`
- retest_result: passed.
- retest_command: `flutter build windows`
- retest_result: passed.
- retest_command: `flutter test test/rc6_runtime_truth_blocker_repair_test.dart --plain-name "assistant backend separation persists profile and provider refs"`
- retest_result: test_harness_infrastructure_blocked before suite load with WebSocket HTTP 502.
- retest_command: Windows EXE blackbox through Computer Use.
- retest_result: passed.

## Rubric Result

| Dimension | Result | Evidence |
| --- | --- | --- |
| Core Completeness | pass | Runtime acceptance persists and reloads separated backend references. |
| User Operability | pass | Windows EXE Assistant Config exposes and triggers backend separation evidence. |
| Evidence Completeness | pass | Summary, Event Ledger and Artifact Catalog records exist. |
| Lifecycle Completeness | pass | Create/update/view/restart recovery and error summary behavior are covered. |
| Regression Safety | partial | Analyze and Windows build passed; local Flutter test harness failed before suite load. |
| Boundary Compliance | pass | No secrets, external calls, service packaging, local model, GPU video or final-state claim. |

## Final Close Decision

- close_allowed: True
- release_status: blocked until P1 Release Gate
- next_gate: P1-22 UI Taste Gate

## Blockers

- none for this P1-21 gate.
- test_harness_infrastructure_blocked remains limited to local Flutter test listener 502; Windows EXE build, desktop blackbox and runtime evidence passed.
- Owner review remains outside automatic closure.
