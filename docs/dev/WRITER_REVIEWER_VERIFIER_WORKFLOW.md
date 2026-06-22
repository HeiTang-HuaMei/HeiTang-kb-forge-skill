# Writer / Reviewer / Product Verifier Workflow

Status: `planning_pending_owner_review`

This document defines the product delivery workflow for HeiTang Knowledge Workbench. It is a process plan only. It does not modify runtime behavior, Review Bus implementation, UI code, or agent execution code.

## 1. Purpose

The project needs a separate black-box product verification role in addition to implementation and code review.

The target workflow is:

```text
Writer -> Reviewer -> Product Verifier -> Owner
```

This workflow prevents a change from being treated as accepted only because code compiles, tests pass, or screenshots look correct. Product acceptance must also prove that the real user path works.

## 2. Roles

### Writer

Position:

```text
Implementer
```

Responsibilities:

- Implement features according to PRD, acceptance criteria, and gate scope.
- Prefer existing components, existing runtime methods, and existing product patterns.
- Follow HeiTang Lazy Builder Gate requirements.
- Produce an implementation-complete `done` signal with evidence.
- Fix valid Reviewer risks and Product Verifier failures.

Boundaries:

- Must not expand the requirement without Owner approval.
- Must not add fake functionality or mock success to product paths.
- Must not expose provider, runtime, gateway, model route, or similar implementation details to ordinary users.
- Must not treat explanatory text as a substitute for a clear user path.
- Must not independently declare product acceptance.

### Reviewer

Position:

```text
White-box code reviewer
```

Responsibilities:

- Review code diffs.
- Check architecture boundaries.
- Check duplicate implementations.
- Check that fake or mock paths do not enter production behavior.
- Check that runtime semantics are not broken.
- Check test coverage and executable validation.
- Produce `review` or `risk` messages.

Reviewer focuses on:

- Code correctness.
- Architecture cleanliness.
- Test adequacy.
- Dependency and abstraction discipline.
- Runtime contract integrity.

Reviewer does not own final user-experience or product-path acceptance.

### Product Verifier

Position:

```text
Black-box product verifier
```

Responsibilities:

- Run the product from the user perspective.
- Verify behavior against PRD, product architecture, functional review notes, and acceptance criteria.
- Use real input where the gate requires real input.
- Inspect real UI behavior, screenshots, output files, artifact center entries, usage records, failure states, and config gates.
- Produce `verify_pass`, `verify_fail`, or `blocked`.

Boundaries:

- Must not read code as the basis for acceptance.
- Must not modify code.
- Must not add tests to hide or redefine product failures.
- Must not commit.
- Must not fix issues directly.
- Must not alter requirements.
- Must not treat technical test success as product acceptance.

### Owner

Position:

```text
Final decision maker
```

Responsibilities:

- Decide whether the requirement is correct.
- Decide whether the user experience is acceptable.
- Decide whether a UI or feature phase is closed.
- Decide whether the project may enter the next gate.
- Decide whether any tag or release is allowed.

Only Owner can finally confirm:

```text
accepted
release ready
stable
```

## 3. Standard Workflow

```text
Requirement / PRD / Acceptance Criteria
-> Writer implements
-> Reviewer performs white-box code review
-> Writer fixes Reviewer risks
-> Product Verifier performs black-box product verification
-> Writer fixes Product Verifier failures
-> Product Verifier re-verifies
-> Owner makes final acceptance decision
```

Strict ordering:

- No acceptance criteria: Writer must not start implementation except for explicit discovery or planning tasks.
- Reviewer not passed: Product Verifier must not be treated as the next acceptance stage.
- Product Verifier not passed: Owner Acceptance must not be requested as final.
- Owner not confirmed: no tag, no release, no stable claim.

## 4. Review Bus Message Plan

Recommended message types to add in a future protocol update:

```text
verify_pass
verify_fail
blocked
```

Planned message schema:

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

Compatibility plan for the current protocol:

- `type: risk`, `from: verifier` means product verification failed.
- `type: done`, `from: verifier` means product verification passed as a candidate.
- `blocked` can be represented as `type: risk`, `from: verifier`, with the body explicitly stating the blocker.

Long-term recommendation:

```text
Add verify_pass / verify_fail / blocked to avoid mixing product verification results with code review risk messages.
```

## 5. Gate Integration

The following gates must include Product Verifier evidence going forward:

- `full_product_regression_before_packaging_gate`
- `pre_exe_packaging_cleanup_gate`
- `windows_exe_packaging_gate`
- `windows_exe_smoke_acceptance_gate`
- `release_candidate_gate`

For `windows_exe_smoke_acceptance_gate`, Product Verifier must run the product as a black box and cover:

- Open EXE.
- Import real files.
- Build knowledge base.
- Generate Markdown.
- Generate Skill.
- Create Agent.
- View artifact center.
- View usage records.
- Verify unconfigured capability gates.
- Close EXE.

## 6. Non-Goals

This planning document does not:

- Add an agent runtime.
- Change Review Bus protocol implementation.
- Add dependencies.
- Add vector database integration.
- Change UI or runtime behavior.
- Create a tag or release.
