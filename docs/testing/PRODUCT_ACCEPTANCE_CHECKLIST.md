# Product Acceptance Criteria

Status: `template`

Use this checklist before implementation and during Product Verifier black-box acceptance.

## Requirement Goal

What real task does the user need to complete?

```text
TODO: Describe the user outcome in product language.
```

## User Path

1. Where does the user start?
2. What does the user input?
3. What does the system process?
4. What result does the user see?
5. Where does the artifact land?
6. How does the user continue to the next step?

## Must Pass

- [ ] The user does not need to understand Provider / Runtime / Gateway / ModelRoute.
- [ ] Button clicks have real behavior.
- [ ] Unconfigured capabilities show "需要设置", "暂不可用", or "本地模式".
- [ ] Recent tasks come from real task records.
- [ ] Report summaries use Chinese when the product path requires Chinese output.
- [ ] Fake or unavailable functionality is visibly gated and cannot appear available.
- [ ] The page does not use extra explanatory text to hide a confusing user path.
- [ ] Artifact center entries come from real artifacts.
- [ ] Usage records come from real operations.
- [ ] Delete / clear / rollback actions require confirmation.
- [ ] Failure states do not show raw stack trace, `desktop_runtime_required`, `null`, or `undefined`.
- [ ] Acceptance is based on running UI screenshots, operation results, and artifact files.

## Verifier Checks

- [ ] User path matches PRD and feature acceptance criteria.
- [ ] Primary action is clear and executable or correctly gated.
- [ ] Empty state is understandable.
- [ ] Loading state is understandable.
- [ ] Success state is understandable.
- [ ] Failure state is understandable.
- [ ] Config gate state is understandable.
- [ ] Real input is used when required.
- [ ] Real output is written when claimed.
- [ ] Artifact trace is inspectable.
- [ ] Usage record is generated from the operation.
- [ ] Workspace boundary is preserved.
- [ ] Agent memory boundary is preserved.
- [ ] Multi-Agent collaboration is real or correctly gated.

## Acceptance Evidence

UI screenshots:

```text
TODO
```

Operation recording or logs:

```text
TODO
```

Input files:

```text
TODO
```

Output files:

```text
TODO
```

Usage records:

```text
TODO
```

Failure records:

```text
TODO
```

Verifier conclusion:

```text
verify_pass | verify_fail | blocked
```
