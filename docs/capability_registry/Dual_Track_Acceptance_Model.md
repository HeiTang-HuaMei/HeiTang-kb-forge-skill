# Dual Track Acceptance Model

Status: `dual_track_acceptance_model_superseded_by_acceptance_type_needs_owner_review`

This file keeps the Core versus Blackbox distinction, but execution now follows `docs/capability_registry/Acceptance_Type_Model.md`. The acceptance-type model adds Artifact, Event, Governance, and Composite requirements so internal substrates are not mistaken for either pure UI features or pure Core-only utilities.

## Acceptance Tracks

| Track | Question It Answers | Evidence Examples | What It Does Not Prove |
| --- | --- | --- | --- |
| Core Acceptance | Does the underlying capability exist? | command can run; data can be generated; files persist; interface can be called; verifier passes | user can complete the workflow |
| Blackbox Acceptance | Can a user or real operation path complete the work? | visible entry; button/action triggers real method; state refreshes; artifact opens/exports/deletes; restart recovery works | release approval |
| Artifact Acceptance | Did the durable output enter the Artifact Lifecycle? | manifest registration; open/export/delete where applicable; restart recovery | user workflow closure unless it is linked |
| Event Acceptance | Did the required event enter the Event Ledger? | event type, payload, scope, restart persistence | artifact or UI closure by itself |
| Governance Acceptance | Are registry, queue, status, and forbidden-claim rules consistent? | legal status values; queue alignment; no duplicate ledgers; no forbidden overclaim | runtime behavior |
| Release Acceptance | Can this be shipped? | explicit Release Gate evidence and Owner approval | anything before Release Gate |

## Rules

1. `core_status=passed` means the underlying ability has evidence.
2. `blackbox_status=passed` means the user or real operation path has evidence.
3. `core_status=passed` plus `blackbox_status=blocked` means `core_passed`, `blackbox_blocked`, `ui_operation_blocked`, `release_blocked`.
4. `acceptance_type=user_blackbox` cannot close unless Core and Blackbox both pass.
5. `acceptance_type=core_only` must not receive fake standalone UI blackbox requirements.
6. `acceptance_type=composite` does not need a standalone UI page, but must carry linked blackbox cases in the user paths it supports.
7. Blackbox blocked does not erase Core implementation evidence.
8. Core passed must not be written as a release claim.

## Required Registry Fields

Every capability row must carry:

| Field | Meaning |
| --- | --- |
| `capability_id` | Stable capability key. |
| `capability_name` | Human-readable name. |
| `phase` | P0, P1, P2, or Release. |
| `acceptance_type` | `user_blackbox`, `core_only`, `artifact`, `governance`, or `composite`. |
| `core_status` | Underlying implementation status. |
| `blackbox_status` | User path or linked blackbox status. |
| `artifact_status` | Durable output lifecycle status. |
| `event_status` | Event Ledger status where required. |
| `governance_status` | Registry/queue/policy status where required. |
| `release_blocker` | Release remains blocked before explicit Release Gate. |
| `close_allowed` | Whether this row has enough evidence for its acceptance type before Owner Review. |
| `linked_blackbox_cases` | Required product-path cases for composite capabilities. |
| `next_core_gate` | Next Core implementation or review Gate. |
| `next_blackbox_gate` | Next user-path or linked-case Gate. |

## Composite Examples

| Capability | Why Composite | Linked Cases |
| --- | --- | --- |
| OKF Minimal Core | Internal format baseline used by KB and document flows. | Knowledge Base Generation; Knowledge Base Validation; Knowledge Base Export; Document Generation citation/source use. |
| Knowledge Reliability Minimal Core | Internal reliability contract used by answer and validation flows. | Bound-KB QA; no-bound-KB block; wrong-KB missing-evidence block; validation_report/reasoning_report artifact checks. |
| Agent Memory Minimal Core | Internal task memory used by long capability-chain execution. | Goal-mode resume; remaining_gates guard; task_memory_snapshot artifact; Event Ledger `memory_snapshot_created`; new-session recovery. |

## Release Boundary

`release_blocker=true` remains correct until the relevant staged Release Gate and Owner Review. `close_allowed=true` is not a release claim.

Staged Release Gates may write only:

```text
p0_release_gate_passed_needs_owner_review
p1_release_gate_passed_needs_owner_review
p2_release_gate_passed_needs_owner_review
overall_industrial_landing_candidate_needs_owner_review
```
