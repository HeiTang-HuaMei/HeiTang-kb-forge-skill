# Staged Release Gates

Status: `staged_release_gate_chain_defined_needs_owner_review`

Release Gate in this registry means a stage exit gate, not a formal production release. It allows the capability chain to advance from one phase to the next without claiming production readiness.

## Stage Chain

```text
P0
-> P0 Release Gate
-> P1
-> P1 Release Gate
-> P2
-> P2 Release Gate
-> Final Owner Review
```

`global_goal_complete=false` while any gate remains.

## Gate Rules

| Gate | Required Regression | Allowed Status |
| --- | --- | --- |
| P0 Release Gate | All P0 acceptance types and linked cases. | `p0_release_gate_passed_needs_owner_review` |
| P1 Release Gate | P1 acceptance plus P0 regression. | `p1_release_gate_passed_needs_owner_review` |
| P2 Release Gate | P2 acceptance plus P0 + P1 regression. | `p2_release_gate_passed_needs_owner_review` |
| Final Owner Review | P0 + P1 + P2 release gate evidence package. | `overall_industrial_landing_candidate_needs_owner_review` |

## Required Evidence

Each staged Release Gate must verify:

1. Capability rows for the stage have valid `acceptance_type`.
2. Required Core, UI Binding, Blackbox, Artifact, Event, Governance and Restart statuses are passing for their type.
3. Composite rows keep linked blackbox cases attached and verified or explicitly pending Owner Review.
4. Evidence report paths exist where the row is marked passed.
5. Evidence commit is not `none` for implemented rows.
6. No forbidden release claims are written.
7. `remaining_gates` advances only to the next stage.

## Forbidden Claims

The staged gates must not write:

```text
Forbidden claim: production_ready
Forbidden claim: release_ready
Forbidden claim: industrial_acceptance_passed
```
