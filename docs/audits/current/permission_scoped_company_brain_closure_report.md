# P2-34 Permission-Scoped Company Brain Closure Report

## Gate

- current_phase: P2
- current_gate: P2-34 Permission-Scoped Company Brain
- current_capability_id: permission_scoped_company_brain
- acceptance_type: core_only
- next_gate: P2-35 Retrieval Regression Benchmark Industrial

## Scope

P2-34 closes the local core permission-scoped company brain evidence slice. It validates role-bound company knowledge access, allowed test knowledge retrieval, denied out-of-scope access, source_trace retention, permission matrix evidence, lifecycle evidence, Event Ledger, Artifact Catalog, restart recovery and boundary checks.

This gate does not expose a standalone UI, does not connect an external database, does not call an external model, does not load external project runtimes, does not package Redis or vector services, does not train a local model, and does not delete real user data.

## White-box Test Result

- status: passed
- runtime method: `runPermissionScopedCompanyBrainAcceptance`
- evidence package: `acceptance/permission_scoped_company_brain_summary.json`
- black_box_status: not_required

Required generated files:

- `permission_scoped_company_brain/company_brain_policy.json`
- `permission_scoped_company_brain/company_knowledge_manifest.json`
- `permission_scoped_company_brain/role_permission_matrix.json`
- `permission_scoped_company_brain/scoped_retrieval_plan.json`
- `permission_scoped_company_brain/source_trace.jsonl`
- `permission_scoped_company_brain/allowed_answer_report.json`
- `permission_scoped_company_brain/denied_access_report.json`
- `permission_scoped_company_brain/lifecycle_report.json`
- `permission_scoped_company_brain/state_snapshot.json`
- `permission_scoped_company_brain/validation_report.json`
- `permission_scoped_company_brain/boundary_report.json`

## Core Evidence

- permission policy includes allow, reference and block rules.
- company knowledge manifest contains only test-marked allowed knowledge bases plus one blocked non-test placeholder.
- role permission matrix allows test company policy and product reference knowledge while blocking the non-test finance placeholder.
- scoped retrieval plan uses `Anchor -> Entity -> Evidence -> Answer`.
- allowed answer report uses only allowed test knowledge bases.
- denied access report blocks out-of-scope and non-test knowledge access.
- source_trace rows keep citations for every allowed test evidence row.

## Evidence Completeness

- artifact_status: passed
- event_status: passed
- lifecycle_status: passed
- restart_status: passed
- Event Ledger: `permission_scoped_company_brain_validated`
- Artifact Catalog: summary, validation report, source_trace and denied-access report records.

## Lifecycle Result

- create: policy, manifest, permission matrix, scoped retrieval plan, source_trace, allowed/denied reports, lifecycle, validation and summary are written.
- view: summary, validation report, source_trace and denied-access report can be read from workspace files.
- open: registered report paths can be opened by path.
- export: registered report paths are available for Artifact Center export.
- delete: only test-marked objects are in scope; no real user data is deleted.
- restart recovery: state snapshot reloads from workspace files and keeps `global_goal_complete=false`.
- error path: out-of-scope knowledge access, missing source_trace, real-user deletion or boundary violation blocks acceptance.

## Regression Result

- P2-34 targeted test passed.
- P2-33 regression test passed.
- Full P0 + P1 + P2 regression remains deferred to P2 Release Gate.

## Boundary Compliance

- no UI modification.
- no fake UI blackbox.
- no external project runtime loaded.
- no external database connected.
- no external model call.
- no network call.
- no new dependency.
- no Provider / Adapter / Parser / Matrix / 0/x user-facing exposure.
- no Redis or Vector DB service packaged into EXE.
- no local model training.
- no GPU training or video generation.
- no real user data deletion.
- no plaintext secret written.
- stage chain is not mutated.

## Rubric Result

| Dimension | Result |
| --- | --- |
| Core Completeness | pass |
| User Operability | pass |
| Evidence Completeness | pass |
| Lifecycle Completeness | pass |
| Regression Safety | pass |
| Boundary Compliance | pass |

## Reviewer Findings

- Core-only status is correct; no standalone UI blackbox is fabricated.
- Company knowledge access is bounded to local, test-marked evidence artifacts.
- Out-of-scope non-test knowledge access is blocked and recorded.
- User-facing labels remain product-level capability/status wording.
- P2 Release Gate still owns full regression and phase exit.

## Fix / Retest Log

- fix_applied: added dedicated P2-34 core evidence package and targeted runtime test.
- retest_command: `dart analyze lib/rc6_runtime/rc6_runtime_controller_io.dart lib/rc6_runtime/rc6_runtime_controller_stub.dart test/rc6_runtime_truth_blocker_repair_test.dart`
- retest_result: passed
- retest_command: `flutter test test/rc6_runtime_truth_blocker_repair_test.dart --plain-name "p2 permission scoped company brain creates core evidence package" --concurrency=1`
- retest_result: passed
- regression_command: `flutter test test/rc6_runtime_truth_blocker_repair_test.dart --plain-name "p2 memory consolidation industrial creates core evidence package" --concurrency=1`
- regression_result: passed

## Final Close Decision

- close_allowed: true
- release_blocker: true
- evidence_commit: pending_current_gate_commit
- next_gate: P2-35 Retrieval Regression Benchmark Industrial
