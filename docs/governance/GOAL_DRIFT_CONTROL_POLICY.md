# Goal Drift Control Policy

This policy prevents a long-running task from downgrading the final product goal into a local slice, contract-only result, fixture-only result, UI status-only result, or Fast Gate-only result.

## Authoritative Ledger

Before starting a task, read:

- `docs/governance/GOAL_ACCEPTANCE_LEDGER.json`
- `docs/governance/GOAL_ACCEPTANCE_LEDGER.md`

The JSON file is authoritative. The Markdown file must remain a truthful human-readable mirror.

## Allowed Statuses

Capability status values are limited to:

- `not_started`
- `in_progress`
- `contract_only`
- `dependency_blocked`
- `real_smoke_passed`
- `ui_connected`
- `e2e_passed`
- `full_gate_passed`
- `done`

## Required Task Start Declaration

Before implementation or dependency mutation, declare:

1. Which ledger item this task advances.
2. Which ledger items this task does not advance.
3. Which statuses cannot be marked by this task.
4. The next remaining E2E gap.

## Required Task End Review

Before ending a task:

1. Update `GOAL_ACCEPTANCE_LEDGER.json` and its Markdown mirror.
2. Output a `Goal Drift Review`.
3. State whether goal downgrade occurred.
4. State whether the final goal remains active.
5. State what the next task must not skip.

## Evidence Rules

- `contract_only` cannot be written as `done`.
- `dependency_blocked` cannot be written as `available`.
- Structured skipped evidence cannot be written as passed.
- A UI action cannot be written as UI complete.
- Focused tests cannot be written as Full Gate.
- Fast Gate cannot be written as final acceptance.
- Local closure cannot be written as goal completion.
- When installation is allowed, remediation must be attempted before a final `dependency_blocked` decision.
- Industrial delivery cannot be announced without the required E2E chain.
- `real_smoke_passed` requires a successful post-install check, a real runtime invocation, a valid input, and non-empty or otherwise backend-valid output.
- `ui_connected` proves only the bridge action and truthful state presentation; it does not prove the full UI workflow.
- `e2e_passed` requires the ledger item's real upstream and downstream workflow to pass.
- `full_gate_passed` requires an actual Full Gate run. A Fast Gate result never promotes this status.
- `done` requires all item acceptance evidence, required E2E evidence, and required release-level validation.

## Downgrade Phrase Guard

If a task artifact or task report uses any of these terms:

- lightweight
- minimal
- minimal closure
- no direct commitment
- preview-only
- fixture-only
- sample-only
- contract-only
- skeleton
- stub
- planned adapter
- deferred for later
- 轻量
- 最小
- 最小闭环
- 不直接承诺
- 后续再补

it must also include:

- `final_target_not_downgraded`
- `remaining_gap`
- `next_required_e2e_step`
- `not_goal_complete`

Missing any of the four fields is a gate failure.

## Goal Drift Review Template

```text
Goal Drift Review
- ledger_item_advanced:
- ledger_items_not_advanced:
- final_target_not_downgraded:
- remaining_gap:
- next_required_e2e_step:
- not_goal_complete:
- goal_downgrade_detected:
- goal_active:
- next_step_must_not_skip:
```
