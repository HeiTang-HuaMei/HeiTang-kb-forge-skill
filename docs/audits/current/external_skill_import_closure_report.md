# P1-17 External Skill Import Basic Closure Report

Status: external_skill_import_completed_needs_owner_review

## Acceptance Scope

- Validate the user-operated external Skill import path in the Windows Workbench.
- Confirm a valid external `SKILL.md` is imported as S0, localized as S2 with the current KB, and persisted across restart.
- Confirm dangerous external Skill content is rejected and recorded as a failed operation.

## Verification Summary

- current_phase: P1
- current_gate: P1-18 Workbench Skill Action Spec
- next_gate: P1-18 Workbench Skill Action Spec
- remaining_gates: 74
- global_goal_complete: false
- blocked rows: 0 for this gate

## Evidence Matrix

- P1-17 row follows user_blackbox contract: passed; core=passed; ui_binding=passed; blackbox=passed; artifact=passed; event=passed; restart=passed; close_allowed=true
- Windows EXE valid import path: passed; Skill Generation -> Import template -> Windows file picker -> valid `SKILL.md`; UI shows imported / validated / generated.
- Valid import artifacts exist: passed; external manifest, localized manifest, localized SKILL.md and diff summary are present in the Workbench workspace.
- Operation history event exists: passed; `skill/operations/skill_operation_history.json` records `import_external_skill` with `status=completed`.
- Dangerous content path: passed; dangerous `SKILL.md` is rejected and operation history records `status=failed` with `reason=dangerous_override_rejected`.
- Restart recovery: passed; after Workbench restart, Skill Generation reloads the S0 + current KB generated S2 state.
- White-box guard coverage: passed; runtime test covers required-field validation, completed history record, dangerous override rejection and no localized manifest on rejection.
- Rerunnable verifier support: passed; external Skill import verifier now creates a minimal KB fixture before running the import matrix.
- Boundary compliance: passed; no dependency addition, no UI/runtime code change in this gate, no Redis/vector service packaging, no real user data deletion.

## White-box Test Result

- result: passed
- evidence: `web/workbench/flutter_app/test/rc6_runtime_truth_blocker_repair_test.dart` adds completed operation-history assertions and dangerous external content rejection coverage.
- verifier support: `web/workbench/flutter_app/tool/windows_native_product_verifier/run_external_skill_import_matrix.ps1` creates a test KB fixture and checks valid, invalid, missing-field, dangerous and missing-path import outcomes.

## Black-box Test Result

- result: passed
- app: HeiTang Workbench Windows EXE
- valid path: selected the test `SKILL.md` through the visible Import template flow and Windows file picker.
- UI evidence: Import Template Skill tab showed template imported, localized Skill verified and diff generated.
- error path: selected a dangerous test `SKILL.md`; the Workbench recorded a failed external Skill import with `dangerous_override_rejected`.

## Evidence Completeness Result

- result: passed
- report: `docs/audits/current/external_skill_import_closure_report.md`
- raw blackbox result: `web/workbench/flutter_app/output/p1_external_skill_import_basic/computer_use_blackbox/external_skill_import_computer_use_blackbox_result.json`
- operation history: `C:/Users/Administrator/AppData/Local/HeiTangKBForge/rc10_product_flow_workspace/skill/operations/skill_operation_history.json`
- artifact evidence: external manifest, localized manifest, localized SKILL.md and diff summary under the Workbench workspace.

## Lifecycle Result

- result: passed
- create: valid external Skill import creates S0 and S2 artifacts.
- view/open: Workbench displays imported / verified / generated state and generated S2 after restart.
- error path: dangerous external Skill is rejected and recorded.
- delete/export: not required for this Basic import gate; later Skill action/export gates remain queued.
- restart recovery: passed.

## Regression Result

- result: partial_verified_with_test_harness_infrastructure_blocked
- `flutter analyze`: passed.
- Targeted `flutter test test/rc6_runtime_truth_blocker_repair_test.dart --plain-name "prd external Skill import"`: blocked before suite load by local Flutter test WebSocket 502 on two attempts; no assertion result was produced.
- P0/P1 release-wide regression remains reserved for P1 Release Gate.
- Existing P1-16 evidence remains readable and current chain advances only to P1-18.

## Boundary Compliance Result

- result: passed
- no isolated pre-target pollution was used as evidence.
- no dependency addition.
- no UI/runtime source edit for this gate.
- no real user data deletion; only test-marked external Skill samples were used.
- no forbidden final-state claim added.

## Reviewer Findings

- P1-17 is user_blackbox and was not closed by core evidence alone.
- The valid user path used the Windows EXE and visible file picker rather than direct runtime invocation.
- The error path writes a durable failed history record instead of silently leaving the previous successful UI state.
- The remaining Skill action/export/delete expectations stay queued for P1-18 and later gates.

## Final Close Decision

- close_allowed: True
- next_gate: P1-18 Workbench Skill Action Spec

## Blockers

- none for this P1-17 gate.
- test_harness_infrastructure_blocked: targeted Flutter test could not load because the local test listener returned HTTP 502 twice; analyze and real EXE blackbox evidence passed.
- Owner review remains outside automatic closure.
