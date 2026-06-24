# Blackbox Case Mapping

Status: `blackbox_case_mapping_acceptance_type_aligned_needs_owner_review`

This file maps user or real operation paths. It does not force UI blackbox tests onto internal Core-only capabilities, but composite internal substrates must be verified through the user paths they support.

## Scope

Blackbox Acceptance is mandatory when `acceptance_type=user_blackbox`. Artifact capabilities may also have operation checks when a user can create, open, export, or delete the artifact. Composite capabilities do not need standalone UI pages, but they must carry `linked_blackbox_cases`.

## P0 User Blackbox Cases

| capability_id | User Path | Required Evidence | Current Status | Gap | Next Gate |
| --- | --- | --- | --- | --- | --- |
| event_ledger | Perform tracked actions, view recent activity, restart and inspect persisted events. | Event matrix with blocked rows 0 plus Owner Review. | `passed` | Owner Review remains. | Owner Review |
| artifact_lifecycle | Create artifact, open, export, delete, restart and verify persisted state. | Artifact lifecycle matrix with blocked rows 0 plus Owner Review. | `passed` | Future artifact types need per-Gate checks. | Owner Review |
| agent_p0_single_assistant | Create/edit/save/restart/chat/delete a single assistant and verify state. | Agent P0 blackbox matrix plus Owner Review. | `passed` | Not A2A, not workgroup, not industrial Agent runtime. | Owner Review plus P0 Assistant Bound-KB rerun |
| document_library_lifecycle | Add/import document, inspect list/detail, delete, restart and recover state. | Document library matrix with blocked rows 0 plus Owner Review. | `passed` | OKF standardization tracked separately. | Owner Review |
| material_organizing_kb_generation | Organize material, generate KB package, inspect report/artifact, restart recovery. | KB build matrix with blocked rows 0 plus Owner Review. | `passed` | Reliability minimum remains separate. | Owner Review plus P0-5B |
| knowledge_base_validation | Trigger validation, inspect report, open/export artifact, restart recovery. | Knowledge validation matrix with blocked rows 0 plus Owner Review. | `passed` | Reliability minimum remains separate. | Owner Review plus P0-5B |
| document_generation | Select KB/template, generate document, register artifact, open/export/delete, restart recovery. | Document generation matrix with blocked rows 0 plus Owner Review. | `passed` | Office adapter and template registry are later Gates. | Owner Review |
| skill_generation | Generate skill, register artifact, inspect/open/export/delete, restart recovery. | Skill generation matrix with blocked rows 0 plus Owner Review. | `passed` | Native skill library remains later Gate. | Owner Review |
| assistant_bound_kb_integration | Use assistant with bound KB scope, verify answers/artifacts carry KB/source scope and unsupported answers are blocked. | Final P0 acceptance rerun after reliability minimum. | `blocked` | Must wait for P0-5B reliability minimum. | `P0 Core Lifecycle Acceptance Gate (rerun after P0 backfill)` |
| settings_path_export | Configure settings/path/export, restart and verify persistence/export output. | Settings/export matrix with blocked rows 0 plus Owner Review. | `passed` | External providers and Office adapters are later Gates. | Owner Review |

## P0 Composite Linked Cases

| capability_id | acceptance_type | Linked Blackbox Cases | Required Non-UI Evidence | Current Status | Next Gate |
| --- | --- | --- | --- | --- | --- |
| okf_minimal_core | `composite` | Knowledge Base Generation; Knowledge Base Validation; Knowledge Base Export; Document Generation citation/source use. | OKF manifests, chunks/blocks, source trace, artifact and validation linkage. | `linked_partial` | P0 acceptance rerun keeps linked cases attached. |
| knowledge_reliability_minimal_core | `composite` | Bound-KB QA; no-bound-KB block; wrong-KB missing-evidence block; validation_report/reasoning_report artifact checks. | Source-trace scope checks, citation existence/scope checks, missing-evidence block, no cross-KB mixed answer by default. | `linked_required` | `P0-5B Knowledge Reliability Minimal Core Gate` |
| agent_memory_minimal_core | `composite` | Goal-mode resume; remaining_gates guard; task_memory_snapshot artifact; Event Ledger `memory_snapshot_created`; new-session recovery. | Snapshot artifact, Event Ledger record, capability queue status, checkpoint/failure/resume placeholders. | `linked_required` | `P0-4C Agent Memory Minimal Core Gate` |

## P0 Core / Governance Cases

| capability_id | acceptance_type | Acceptance Basis | Current Status | Next Gate |
| --- | --- | --- | --- | --- |
| industrial_scope_metadata | `core_only` | Metadata reservation matrix and report; no standalone UI path. | `passed` | `P1-9 Scope Resolver Basic` |
| memory_evidence_metadata | `core_only` | Metadata reservation matrix and report; no standalone UI path. | `passed` | P1 Memory / Evidence Gates |
| external_project_classification_registry | `governance` | Five-category classification, routing into existing modules, no dependency unless `real_integration`. | `passed` | Owner Review |
| p0_core_acceptance | `governance` | Rerun P0 acceptance after Core, Blackbox, Artifact, Event, Governance and linked cases agree. | `blocked` | `P0 Core Lifecycle Acceptance Gate (rerun after P0 backfill)` |

## Reporting Rule

When answering whether a capability has landed, report the acceptance type first:

```text
Acceptance type:
Core:
Blackbox / linked cases:
Artifact:
Event:
Governance:
Release blocker:
Close allowed:
Next Gate:
```

Do not collapse these into a single pass/fail status.

## Stage Regression Mapping

| Stage Gate | Must Regress |
| --- | --- |
| P0 Release Gate | P0 user blackbox, artifact lifecycle, composite linked cases, governance queue state, Event Ledger and restart evidence. |
| P1 Release Gate | All P1 rows plus P0 regression. |
| P2 Release Gate | All P2 rows plus P0 and P1 regression. |
| Final Owner Review | P0, P1 and P2 release gate evidence package. |
