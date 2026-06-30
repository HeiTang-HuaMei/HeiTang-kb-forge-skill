# V1 L1 Backend Deepwater Acceptance Plan

Generated: 2026-06-30

## 1. Scope

Owner requires L1 backend deepwater acceptance before V1.0 can be finally accepted.

This plan defines the backend hardening and deepwater acceptance scope. It does not execute tests, does not modify product code, does not modify `capability_chain_status.json`, does not push, does not tag, and does not publish a release.

## 2. Gate Objective

L1 backend deepwater acceptance must prove that the current V1.0 baseline can survive realistic backend workflows, interruption cases, consistency checks, and long-running usage without P0/P1 defects.

Passing this plan is a prerequisite to re-entering the Owner final pass decision.

## 3. Test Scope

| ID | Domain | Acceptance focus | Evidence required |
| --- | --- | --- | --- |
| L1-01 | Real material import chain | Import real documents through the visible product path and verify backend records and user-visible outputs. | import logs, manifest/catalog snapshot, screenshots |
| L1-02 | Multi-file import / merge / delete / rebuild | Exercise multiple files, merge flows, deletion, and rebuild. | before/after manifests, catalog diff, UI screenshots |
| L1-03 | Interruption / force-kill / restart recovery | Interrupt active backend work, relaunch, and verify recovery or safe rollback. | process logs, recovery report, post-restart state |
| L1-04 | Manifest / catalog / source_trace / evidence_map consistency | Verify IDs, lineage, source trace, and evidence map remain consistent across operations. | consistency matrix, sampled source trace records |
| L1-05 | RAG miss refusal / citation validation | Ask out-of-scope questions and verify refusal; ask in-scope questions and verify citations. | prompt/answer log, citation/source trace checks |
| L1-06 | Document generation full chain | Generate document output from accepted inputs and verify artifact records, exports, and traceability. | generation logs, artifact files, evidence map |
| L1-07 | Skill snapshot / pointer / missing source strategy | Verify behavior when source files are removed or unavailable. | strategy classification, UI/error prompt screenshots |
| L1-08 | Agent configured with real model service | Configure a real model endpoint and verify the Agent call chain. | config snapshot, request/response log, UI screenshots |
| L1-09 | Redis / Vector DB connector smoke | Smoke-test connector availability, failure prompts, and fallback behavior. | connector logs, smoke report |
| L1-10 | Long-running memory curve | Run representative flows over time and record process memory. | memory baseline, interval samples, final summary |
| L1-11 | Repeated clicks / concurrent tasks / duplicate-submit prevention | Stress rapid clicks and concurrent task starts. | task logs, UI state screenshots, duplicate check |
| L1-12 | Error prompts and degradation paths | Verify user-facing error messages remain understandable and avoid internal traces. | error catalog, screenshots |
| L1-13 | Data residue / dirty data / orphan records | Inspect storage after create/update/delete/interruption flows. | orphan scan, residue report, cleanup expectations |

## 4. Required Per-Phase Output

Each L1 sub-phase must produce:

- phase report
- pass/fail/blocked conclusion
- logs/screenshots path
- `git status --short`
- `capability_chain_status.json` diff status
- ready-claim scan result
- affected test result
- whether the next phase is allowed

## 5. Failure Handling

If any P0, P1, or regression failure is found:

1. Generate an RCA report.
2. Decide whether the failure is within auto-repair scope.
3. Apply the smallest safe fix.
4. Run targeted validation.
5. Run the full affected gate.
6. Refresh downstream evidence if product code, artifact, UI, packaging, or backend behavior changed.
7. Continue only after the affected gate passes.
8. Stop only if the repair budget is exhausted or the fix would exceed the authorized scope.

Each failure class has a maximum of 3 auto-repair rounds.

The repair loop must not lower acceptance standards, delete tests to manufacture a pass, hide errors, or modify `capability_chain_status.json`.

## 6. Risk Classification

### P0

P0 blocks V1.0 final acceptance.

- data corruption
- source trace / citation confusion
- generated result cannot be traced
- real workflow crash
- `capability_chain_status.json` pollution
- old UI / old artifact recurrence
- backend core workflow unavailable

### P1

P1 requires Owner judgment after repair attempt and may block V1.0 final acceptance.

- main workflow runs but produces clearly wrong results
- RAG hallucination without refusal
- document generation output confusion
- Agent failure-state is not friendly
- obvious long-running memory leak
- inconsistent state after interruption recovery

### P2 / P3

P2/P3 issues are recorded for later versions and do not block by default unless Owner upgrades the severity.

Examples:

- UI/copy polish
- source granularity improvements
- performance tuning
- nicer duplicate-file handling
- additional observability

## 7. Evidence Refresh Rules

If L1 fixes affect artifact, UI, packaging, backend workflow, Agent behavior, or acceptance screenshots, the downstream evidence must be refreshed before requesting a new Owner final pass decision.

Potential refresh set:

- affected tests
- Package Gate, if artifact or packaging changed
- Computer Use Acceptance, if UI/artifact changed
- backend L1 reports and logs
- major-gate DeepSeek packet, if required at the next major boundary
- Owner Final Decision Ready Pack

## 8. Completion Criteria

L1 backend deepwater acceptance can be considered complete only when:

- all L1 domains are passed, deferred with Owner-approved rationale, or classified as P2/P3 backlog
- no open P0 remains
- no unresolved P1 remains without Owner decision
- `capability_chain_status.json` diff is empty
- ready-claim scan has no positive readiness claims
- no push/tag/release has been performed
- final V1.0 acceptance remains pending Owner decision

## 9. Final State After Plan Creation

`v1_owner_conditional_pass_pending_l1_backend_deepwater_acceptance`
