# P0 Backfill Gates

Status: `p0_backfill_routes_defined_needs_owner_review`

This file converts capability inventory into the P0 execution queue. It supersedes any loose "future" wording for the listed P0 gaps.

## Current P0 Completed Evidence

These gates have blackbox evidence with blocked rows at `0`, but still require Owner Review.

| Gate | Status | Evidence |
|---|---|---|
| P0-1 Event Ledger | `event_ledger_repair_completed_needs_owner_review` | `web/workbench/flutter_app/output/event_ledger/event_ledger_blackbox_matrix.json` |
| P0-2 Artifact Lifecycle | `artifact_lifecycle_repair_completed_needs_owner_review` | `web/workbench/flutter_app/output/artifact_lifecycle/artifact_lifecycle_blackbox_matrix.json` |
| P0-2b Industrial Scope Metadata Reservation | `industrial_scope_metadata_reserved_needs_review` | `web/workbench/flutter_app/output/capability_blackbox/industrial_scope/industrial_scope_metadata_reservation_matrix.json` |
| P0-3 Document Library Lifecycle | `document_library_lifecycle_completed_needs_owner_review` | `web/workbench/flutter_app/output/capability_blackbox/document_library_matrix.json` |
| P0-4 Material Organizing and Knowledge Base Generation | `knowledge_base_build_lifecycle_completed_needs_owner_review` | `web/workbench/flutter_app/output/capability_blackbox/knowledge_base_build_matrix.json` |
| P0-5 Knowledge Base Validation | `knowledge_validation_lifecycle_completed_needs_owner_review` | `web/workbench/flutter_app/output/capability_blackbox/knowledge_validation_matrix.json` |
| P0-6 Document Generation | `document_generation_lifecycle_completed_needs_owner_review` | `web/workbench/flutter_app/output/capability_blackbox/document_generation_matrix.json` |
| P0-7 Skill Generation | `skill_generation_lifecycle_completed_needs_owner_review` | `web/workbench/flutter_app/output/capability_blackbox/skill_generation_matrix.json` |
| P0-8 Settings / Path / Export | `settings_export_basic_completed_needs_owner_review` | `web/workbench/flutter_app/output/capability_blackbox/settings_export_matrix.json` |
| P0-9 Memory and Evidence Metadata Reservation | `memory_evidence_metadata_reserved_needs_review` | `web/workbench/flutter_app/output/capability_blackbox/memory_evidence/memory_evidence_metadata_reservation_matrix.json` |

The current P0 core acceptance report is a pre-backfill snapshot: `docs/audits/current/p0_core_lifecycle_acceptance_report.md`. It must be rerun after the P0 backfill gates below.

## P0 Immediate Backfill Gates

| Gate | Reason | Dependency Status | Acceptance Minimum | Output Evidence |
|---|---|---|---|---|
| P0-4B OKF Minimal Core Gate | KB generation, validation, document generation and skill generation need one accepted open knowledge package baseline instead of loose OKF references. | P0-3 and P0-4 are blackbox verified. | Stable minimal manifests for documents, chunks/blocks, source trace, artifacts and validation linkage; no OKF runtime/page overclaim. | `docs/audits/current/okf_minimal_core_report.md`; `web/workbench/flutter_app/output/capability_blackbox/okf_minimal_core_matrix.json` |
| P0-5B Knowledge Reliability Minimal Core Gate | Existing validation is useful but does not yet prove the minimal reliability contract requested for scoped evidence answers. | P0-4, P0-5 and P0-9 are blackbox verified. | Bound-KB source_trace, citation existence/scope check, missing-evidence report, answer block on missing evidence, reasoning_report artifact, no cross-KB mixed answer by default. | `docs/audits/current/knowledge_reliability_minimal_core_report.md`; `web/workbench/flutter_app/output/capability_blackbox/knowledge_reliability_minimal_core_matrix.json` |

## P0 Core Acceptance Before P1

P0 Core Acceptance must be rerun only after:

1. `P0-4B OKF Minimal Core Gate` passes with blocked rows `0`.
2. `P0-5B Knowledge Reliability Minimal Core Gate` passes with blocked rows `0`.
3. The P0 core acceptance verifier includes both backfill matrices.
4. `capability_chain_status.json` still has `global_goal_complete=false`.

## Not Allowed In P0 Backfill

- Do not implement Evidence Graph Basic.
- Do not implement Memory Layer Separation runtime.
- Do not implement Loop Runtime, Meta-Harness, A2A, Workgroup, multi-model orchestration, Night Knowledge Maintenance, Company Brain, OfficeCLI adapter, or Release.
- Do not write `production_ready`, `release_ready`, `industrial_acceptance_passed`, `semantic_reasoning_passed`, `rule_engine_passed`, `evidence_graph_passed`, or `loop_runtime_passed`.

## Next Execution Queue

1. `P0-4B OKF Minimal Core Gate`
2. `P0-5B Knowledge Reliability Minimal Core Gate`
3. `P0 Core Lifecycle Acceptance Gate (rerun after P0 backfill)`
4. Owner Review
5. P1 queue
