# Writer Reviewer Verifier Workflow Planning Report

Generated: 2026-06-22

Gate: `writer_reviewer_verifier_workflow_planning_gate`

Final status:

```text
writer_reviewer_verifier_plan_pending_owner_review
```

Not claimed:

```text
verifier_runtime_ready
feature_implemented
turbo_vec_integrated
stable
release
packaging_ready
```

## 1. Scope

This gate only adds workflow planning and acceptance-mechanism documentation.

No business code, UI code, runtime code, dependency configuration, Review Bus implementation, vector backend, EXE packaging, tag, release, or GitHub Release was changed by this gate.

## 2. Documents Added

| Document | Purpose |
| --- | --- |
| `docs/dev/WRITER_REVIEWER_VERIFIER_WORKFLOW.md` | Defines Writer / Reviewer / Product Verifier / Owner workflow and Review Bus message plan. |
| `docs/dev/PRODUCT_VERIFIER_AGENT_SPEC.md` | Defines the Product Verifier black-box acceptance role and evidence boundaries. |
| `docs/testing/PRODUCT_ACCEPTANCE_CHECKLIST.md` | Adds a reusable Product Acceptance Criteria template. |
| `docs/audits/current/writer_reviewer_verifier_workflow_planning_report.md` | Records this planning gate result. |

No same-name or near-name documents were found before adding these files.

## 3. Role Definitions

The workflow now defines four distinct roles:

| Role | Responsibility | Boundary |
| --- | --- | --- |
| Writer | Implements according to PRD and acceptance criteria. | Does not self-declare product acceptance. |
| Reviewer | Performs white-box code review. | Does not own final user-path acceptance. |
| Product Verifier | Runs the product as a black box against PRD and acceptance criteria. | Does not read code, modify code, commit, or fix directly. |
| Owner | Makes final acceptance and release decisions. | Only Owner can approve accepted, release-ready, or stable status. |

## 4. Product Verifier Boundary

Product Verifier must verify real product behavior:

- Launch product through CLI, Flutter Web, or EXE according to gate scope.
- Open pages and click visible controls.
- Use real input when required.
- Inspect real output and artifact files.
- Inspect artifact center and usage records.
- Verify unconfigured capability gates.
- Verify failure states are understandable to users.
- Verify workspace and Agent memory boundaries.

Product Verifier must not:

- Modify code.
- Add tests to hide product failures.
- Commit.
- Change requirements.
- Treat technical tests as product acceptance.

## 5. Acceptance Criteria Template

`docs/testing/PRODUCT_ACCEPTANCE_CHECKLIST.md` defines a reusable template with:

- Requirement goal.
- User path.
- Must-pass product checks.
- Verifier checks.
- Required acceptance evidence.
- Verifier conclusion: `verify_pass`, `verify_fail`, or `blocked`.

The checklist explicitly requires:

- Real button behavior.
- Correct config gates for unconfigured abilities.
- Real artifact center entries.
- Real usage records.
- Confirmation for delete / clear / rollback.
- No raw stack trace, `desktop_runtime_required`, `null`, or `undefined` in failure states.

## 6. Review Bus Planning

Recommended future message types:

```text
verify_pass
verify_fail
blocked
```

Planned schema:

```json
{
  "id": "",
  "from": "writer|reviewer|verifier|owner",
  "type": "review|risk|done|verify_pass|verify_fail|blocked",
  "reply_to": "",
  "body": "",
  "evidence": []
}
```

Compatibility plan if current `agent_chat` protocol is not changed yet:

- `type: risk`, `from: verifier` means product verification failed.
- `type: done`, `from: verifier` means product verification passed as a candidate.

Long-term recommendation: add `verify_pass`, `verify_fail`, and `blocked` to avoid mixing product verification results with code-review messages.

## 7. Gate Integration

The following gates must include Product Verifier evidence going forward:

- `full_product_regression_before_packaging_gate`
- `pre_exe_packaging_cleanup_gate`
- `windows_exe_packaging_gate`
- `windows_exe_smoke_acceptance_gate`
- `release_candidate_gate`

Because the current thread already completed `full_product_regression_before_packaging_gate` before this planning gate was inserted, this report does not retroactively modify the completed evidence. Future reruns of that gate must include the Product Verifier perspective.

If this planning gate is evaluated as a standalone insertion before regression, the current mainline remains allowed to enter:

```text
full_product_regression_before_packaging_gate
```

The next mainline gate remains:

```text
pre_exe_packaging_cleanup_gate
```

## 8. Local Vector Index Adapter Candidates

TurboVec, ZveC, FAISS, SQLite FTS, Qdrant, and Redis Vector are documented only as candidate local/vector index backends.

Planning conclusions:

1. Workbench does not bind to a single vector index backend.
2. The current version does not default-package any new vector library.
3. This gate does not replace Redis or external vector connectors.
4. Future adoption depends on size, speed, stability, Windows EXE packaging cost, and real knowledge-base pressure-test results.
5. No candidate is described as runtime-ready by this gate.

This gate did not add dependencies, modify vector implementation, replace the current retrieval chain, or integrate TurboVec / ZveC.

## 9. Repository State

Preflight:

| Item | Result |
| --- | --- |
| Branch | `feature/workbench-ui-prototype` |
| HEAD before this planning gate | `36f52db test: verify workbench industrial readiness candidate` |
| Pre-existing tracked dirty file | `docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md` |

This gate did not modify the pre-existing unrelated dirty file.

## 10. Release Boundary

This gate did not:

- Commit.
- Tag.
- Release.
- Create GitHub Release.
- Enter EXE packaging.
- Claim stable or packaging-ready state.

## 11. Decision

Planning status:

```text
writer_reviewer_verifier_plan_pending_owner_review
```

Allowed next mainline gate:

```text
pre_exe_packaging_cleanup_gate
```

This allowed next gate depends on the already completed `full_product_regression_before_packaging_gate`. Future product verification evidence must be included in cleanup, packaging, smoke, and release-candidate gates.
