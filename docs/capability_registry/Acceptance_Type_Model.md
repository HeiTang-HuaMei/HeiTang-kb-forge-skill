# Acceptance Type Model

Status: `acceptance_type_model_vertical_chain_defined_needs_owner_review`

Blackbox testing has first priority for user-operable capabilities. Core testing is whitebox or greybox evidence that proves the underlying ability exists. Internal substrates do not need fake standalone UI pages, but if they affect user workflows they must be verified through linked blackbox cases. The same model applies to P0, P1, P2, and staged Release Gates.

## Acceptance Types

| acceptance_type | Applies To | Required Evidence | Close Rule |
| --- | --- | --- | --- |
| `user_blackbox` | User can see, click, configure, create, delete, export, or reopen it. | Core evidence plus user or real operation path evidence. | Core and Blackbox must both pass. |
| `core_only` | Pure internal substrate with no direct user path and no cross-path product obligation. | Command/function/verifier output, schema, report, generated files, and hooks where applicable. | Core must pass; Blackbox must be `not_required`. |
| `artifact` | Durable output such as report, document, skill package, export package, validation report, reasoning report, or task memory snapshot. | Core evidence plus manifest registration, open/export/delete where applicable, Event record, and restart recovery. | Core and Artifact must pass; Blackbox is required only if a user path exists. |
| `governance` | Registry, classification, queue, status vocabulary, forbidden-claim list, or Release Gate policy. | Files exist, required fields are complete, values are legal, queues agree, and forbidden claims are not overused. | Governance must pass. |
| `composite` | Internal substrate carried by multiple user paths, such as OKF, Knowledge Reliability, and Agent Memory. | Core plus Artifact/Event/Governance evidence, with linked blackbox cases proving real product paths exercise the substrate. | Core and required Artifact/Event/Governance checks must pass, and linked blackbox cases must be attached and passing or explicitly pending. |

## Composite Rule

Composite does not mean standalone UI blackbox. It means no fake page is needed, but the capability cannot close by Core alone.

| capability | Required linked blackbox cases |
| --- | --- |
| OKF Minimal Core | Knowledge Base Generation; Knowledge Base Validation; Knowledge Base Export; Document Generation citation/source use. |
| Knowledge Reliability Minimal Core | Bound-KB QA; no-bound-KB block; wrong-KB missing-evidence block; validation_report/reasoning_report artifact checks. |
| Agent Memory Minimal Core | Goal-mode resume; remaining_gates guard; task_memory_snapshot artifact; Event Ledger `memory_snapshot_created`; new-session recovery. |

## Priority

1. If users can operate it directly, classify it as `user_blackbox`.
2. If it is a report/package/export/snapshot, classify it as `artifact`.
3. If it has no user path and does not carry user workflows, classify it as `core_only`.
4. If it manages process, routing, registry, status, or policy, classify it as `governance`.
5. If it is an internal substrate that affects multiple user workflows, classify it as `composite`.

## Interpretation Matrix

| Core | Blackbox | Meaning |
| --- | --- | --- |
| blocked/not_started | blocked/not_started | Underlying ability is not done. |
| passed | blocked | Core exists, but the user path is broken; this blocks P0 for `user_blackbox`. |
| blocked/not_started | passed | Suspect false blackbox pass; recheck the harness. |
| passed | passed | User-operable capability can move to Owner Review, not Release. |
| passed | not_required | Acceptable only for `core_only`, `artifact`, or `governance` where no user path exists. |
| passed | linked_required/linked_partial | Composite capability has Core evidence but still depends on linked blackbox cases. |

## Release Boundary

`release_blocker=true` remains correct for every row until its staged Release Gate and Owner Review. `close_allowed=true` only means the row has enough evidence for its own acceptance type and can go to Owner Review.

## Vertical Closure Chain

Every capability follows the same vertical chain:

```text
Core Gate
-> UI Binding / Linked Blackbox / Artifact / Governance Gate
-> Blackbox or Scenario Acceptance
-> Event / Artifact / Restart / Export / Delete Evidence
-> Closure Report
-> Commit
-> Advance
```

Stage movement follows:

```text
P0
-> P0 Release Gate
-> P1
-> P1 Release Gate with P0 regression
-> P2
-> P2 Release Gate with P0 + P1 + P2 regression
-> Final Owner Review
```

These Release Gates are stage exit gates, not production release claims. They may only write:

```text
p0_release_gate_passed_needs_owner_review
p1_release_gate_passed_needs_owner_review
p2_release_gate_passed_needs_owner_review
overall_industrial_landing_candidate_needs_owner_review
```
