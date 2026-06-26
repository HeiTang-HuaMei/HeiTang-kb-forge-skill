# P2-28 Jurisdiction / Domain Scope Closure Report

## Gate

- current_phase: P2
- current_gate: P2-28 Jurisdiction / Domain Scope
- current_capability_id: jurisdiction_domain_scope
- acceptance_type: core_only
- next_gate: P2-29 Human Review Console

## Scope

P2-28 closes the core jurisdiction and domain scope slice. It validates local test-marked scope policy, domain scope matrix, source trace, allowed query routing, denied out-of-scope behavior, permission boundaries, test-only deletion and restart recovery.

## White-box Test Result

- status: passed
- runtime method: `runJurisdictionDomainScopeAcceptance`
- evidence package: `acceptance/jurisdiction_domain_scope_summary.json`
- black_box_status: not_required

Required generated files:

- `jurisdiction_domain_scope/jurisdiction_policy.json`
- `jurisdiction_domain_scope/domain_scope_matrix.json`
- `jurisdiction_domain_scope/test_knowledge_base_manifest.json`
- `jurisdiction_domain_scope/source_trace.jsonl`
- `jurisdiction_domain_scope/query_answer_route_report.json`
- `jurisdiction_domain_scope/denied_scope_report.json`
- `jurisdiction_domain_scope/permission_matrix.json`
- `jurisdiction_domain_scope/delete_report.json`
- `jurisdiction_domain_scope/test_jurisdiction_domain_scope.tombstone.json`
- `jurisdiction_domain_scope/state_snapshot.json`
- `jurisdiction_domain_scope/validation_report.json`
- `jurisdiction_domain_scope/boundary_report.json`

## Core Evidence

- jurisdiction policy contains allow, explicit-reference and block rules.
- domain scope matrix records active jurisdiction and active domain.
- blocked non-test knowledge base is recorded and excluded.
- source_trace spans only allowed test knowledge bases and keeps jurisdiction/domain metadata.
- query route uses Anchor -> Entity -> Evidence -> Answer and reads only allowed evidence.
- denied scope report blocks out-of-scope reads and real-user deletion.
- permission matrix denies real-user knowledge base read/delete.

## Evidence Completeness

- artifact_status: passed
- event_status: passed
- lifecycle_status: passed
- restart_status: passed
- Event Ledger: `jurisdiction_domain_scope_validated`
- Artifact Catalog: summary, validation report, source trace and tombstone records.

## Lifecycle Result

- create: policy, matrix, manifest, source trace, query route, denied-scope report, permission matrix, validation and summary are written.
- view: summary and validation report can be read from workspace files.
- open: registered report paths can be opened by path.
- export: registered report paths are available for Artifact Center export.
- delete: only the current test-marked active scope record is deleted and tombstoned.
- restart recovery: state snapshot reloads from workspace files and keeps `global_goal_complete=false`.
- error path: out-of-scope reads, real-user deletion and missing source trace block acceptance.

## Regression Result

- P2-28 targeted test passed.
- P2-27 regression test passed.
- Full P0 + P1 + P2 regression remains deferred to P2 Release Gate.

## Boundary Compliance

- no external database connected.
- no external project runtime loaded.
- no external project names exposed in product UI evidence.
- no Provider / Adapter / Parser / Matrix / 0/x user-facing exposure.
- no network call.
- no new dependency.
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
- Scope closure depends on fresh policy, matrix, source trace, query route, denied-scope and permission evidence.
- Delete evidence is limited to a test-marked active scope record.
- Real-user knowledge bases are represented only as blocked placeholders and are not read or deleted.
- P2 Release Gate still gates phase exit and full regression.

## Fix / Retest Log

- fix_applied: added dedicated P2-28 core evidence package and targeted runtime test.
- retest_command: `dart analyze web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_stub.dart web/workbench/flutter_app/test/rc6_runtime_truth_blocker_repair_test.dart`
- retest_result: passed
- retest_command: `flutter test test/rc6_runtime_truth_blocker_repair_test.dart --plain-name "p2 jurisdiction domain scope creates core evidence package" --concurrency=1`
- retest_result: passed
- retest_command: `flutter test test/rc6_runtime_truth_blocker_repair_test.dart --plain-name "p2 versioned knowledge governance creates core evidence package" --concurrency=1`
- retest_result: passed

## Final Close Decision

- close_allowed: true
- release_blocker: true
- evidence_commit: pending_current_gate_commit
- next_gate: P2-29 Human Review Console
