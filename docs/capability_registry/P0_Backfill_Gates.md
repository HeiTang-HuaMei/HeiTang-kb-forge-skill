# P0 Backfill Gates

Status: `p0_backfill_routes_acceptance_type_aligned_needs_owner_review`

This file converts capability inventory into the P0 execution queue. It uses the acceptance types defined in `docs/capability_registry/Acceptance_Type_Model.md`.

Execution source of truth: `docs/capability_registry/Capability_Implementation_Status.md` records P0/P1/P2 capability acceptance status, `docs/governance/EXTERNAL_PROJECT_REGISTRY.md` records external project classification policy, and the external runtime reference queue under `docs/governance` records classification results. External project classification can route a capability into a Gate, but it never replaces capability acceptance evidence.

## Current P0 Evidence

These gates have evidence for their acceptance type and still require Owner Review where noted.

| Gate | Acceptance Type | Status | Evidence |
|---|---|---|---|
| P0-1 Event Ledger | `user_blackbox` | `passed`, needs Owner Review | `web/workbench/flutter_app/output/event_ledger/event_ledger_blackbox_matrix.json` |
| P0-2 Artifact Lifecycle | `artifact` | `passed`, needs Owner Review | `web/workbench/flutter_app/output/artifact_lifecycle/artifact_lifecycle_blackbox_matrix.json` |
| P0-2b Industrial Scope Metadata Reservation | `core_only` | `passed`, metadata reservation only | `web/workbench/flutter_app/output/capability_blackbox/industrial_scope/industrial_scope_metadata_reservation_matrix.json` |
| P0-3 Document Library Lifecycle | `user_blackbox` | `passed`, needs Owner Review | `web/workbench/flutter_app/output/capability_blackbox/document_library_matrix.json` |
| P0-4 Material Organizing and Knowledge Base Generation | `user_blackbox` | `passed`, needs Owner Review | `web/workbench/flutter_app/output/capability_blackbox/knowledge_base_build_matrix.json` |
| P0-4B OKF Minimal Core Gate | `composite` | Core/Artifact evidence passed; linked cases remain attached | `docs/audits/current/okf_minimal_core_report.md`; `web/workbench/flutter_app/output/capability_blackbox/okf_minimal_core_matrix.json` |
| P0-5 Knowledge Base Validation | `artifact` | `passed`, needs Owner Review | `web/workbench/flutter_app/output/capability_blackbox/knowledge_validation_matrix.json` |
| P0-6 Document Generation | `artifact` | `passed`, needs Owner Review | `web/workbench/flutter_app/output/capability_blackbox/document_generation_matrix.json` |
| P0-7 Skill Generation | `artifact` | `passed`, needs Owner Review | `web/workbench/flutter_app/output/capability_blackbox/skill_generation_matrix.json` |
| P0-8 Settings / Path / Export | `user_blackbox` | `passed`, needs Owner Review | `web/workbench/flutter_app/output/capability_blackbox/settings_export_matrix.json` |
| P0-9 Memory and Evidence Metadata Reservation | `core_only` | `passed`, metadata reservation only | `web/workbench/flutter_app/output/capability_blackbox/memory_evidence/memory_evidence_metadata_reservation_matrix.json` |
| Capability Registry / External Project Classification | `governance` | `passed`, needs Owner Review | `docs/capability_registry/Capability_Implementation_Status.md`; `docs/governance/EXTERNAL_PROJECT_REGISTRY.md`; external runtime reference queue under `docs/governance` |

The current P0 core acceptance report is a pre-backfill snapshot: `docs/audits/current/p0_core_lifecycle_acceptance_report.md`. It must be rerun after the P0 backfill gates below.

## P0 Immediate Backfill Gates

| Gate | Acceptance Type | Reason | Dependency Status | Acceptance Minimum | Output Evidence |
|---|---|---|---|---|---|
| P0-4C Agent Memory Minimal Core Gate | `composite` | Long capability-chain execution needs task memory so a single Gate is not mistaken for global completion and queue state survives context/restart. | Capability Registry exists; P0-4B passed; TencentDB Agent Memory is classified as `absorb`, not `real_integration`. | Writes task_memory_snapshot, checkpoint/failure/resume placeholders, Event Ledger `memory_snapshot_created`, Artifact Lifecycle `task_memory_snapshot`, restart-readable current/completed/remaining/blocked state, and keeps `global_goal_complete=false` while remaining gates exist. Linked scenario must prove goal-mode recovery, not just file existence. | `docs/audits/current/agent_memory_minimal_core_report.md`; `web/workbench/flutter_app/output/capability_blackbox/agent_memory_minimal_core_matrix.json` |
| P0-5B Knowledge Reliability Minimal Core Gate | `composite` | Existing validation is useful but does not yet prove the minimal reliability contract requested for scoped evidence answers. | P0-4, P0-5 and P0-9 are accepted for their current types. | Bound-KB source_trace, citation existence/scope check, missing-evidence report, answer block on missing evidence, reasoning_report artifact, no cross-KB mixed answer by default. Linked cases must include bound-KB QA, no-bound-KB block, wrong-KB missing-evidence block and report artifacts. | `docs/audits/current/knowledge_reliability_minimal_core_report.md`; `web/workbench/flutter_app/output/capability_blackbox/knowledge_reliability_minimal_core_matrix.json` |

## P0 Core Acceptance Before P0 Release Gate

P0 Core Acceptance must be rerun before the staged P0 Release Gate only after:

1. `P0-4C Agent Memory Minimal Core Gate` passes its composite checks with blocked rows `0`.
2. `P0-5B Knowledge Reliability Minimal Core Gate` passes its composite checks with blocked rows `0`.
3. Required `user_blackbox` P0 capabilities still have Blackbox status `passed`.
4. Required `artifact` P0 capabilities still have Artifact status `passed`.
5. Composite linked blackbox cases for OKF, Knowledge Reliability and Agent Memory are still attached and verified or explicitly Owner Review pending.
6. Governance files and `capability_chain_status.json` remain consistent.
7. `capability_chain_status.json` still has `global_goal_complete=false`.

## P0 Release Gate

P0 Release Gate is the stage exit gate from P0 to P1. It is not a production release.

It must:

1. Confirm all required P0 rows have `close_allowed=true` or explicit Owner Review pending where the row is a pre-accepted foundation.
2. Confirm OKF, Knowledge Reliability and Agent Memory composite linked cases are present.
3. Confirm Event, Artifact, Restart and evidence report fields are complete for P0.
4. Write only `p0_release_gate_passed_needs_owner_review`.
5. Advance the queue to P1 while keeping `global_goal_complete=false`.

## Not Allowed In P0 Backfill

- Do not implement Evidence Graph Basic.
- Do not implement Memory Layer Separation runtime.
- Do not implement full L0-L3 memory, TencentDB Agent Memory integration, Mermaid Task Map runtime, Loop Runtime, Meta-Harness, A2A, Workgroup, multi-model orchestration, Night Knowledge Maintenance, Company Brain, OfficeCLI adapter, or Release.
- Do not create fake standalone UI pages for composite capabilities.
- Do not treat "no standalone UI" as "no linked blackbox scenario".
- Do not write `production_ready`, `release_ready`, `industrial_acceptance_passed`, `semantic_reasoning_passed`, `rule_engine_passed`, `evidence_graph_passed`, or `loop_runtime_passed`.

## Next Execution Queue

1. `P0-4C Agent Memory Minimal Core Gate`
2. `P0-5B Knowledge Reliability Minimal Core Gate`
3. `P0 Core Lifecycle Acceptance Gate (rerun after P0 backfill)`
4. `P0 Release Gate`
5. P1 queue
