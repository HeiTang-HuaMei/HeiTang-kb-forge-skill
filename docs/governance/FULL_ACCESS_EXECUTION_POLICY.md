# Full Access Execution Policy

The user has pre-authorized autonomous execution for the active HeiTang KB Forge goal within the current project, workspace, and local machine boundary.

## Default Execution Rule

Within the authorized goal scope:

1. Continue execution by default.
2. Do not wait for routine human confirmation.
3. Create a checkpoint before a high-risk action or retry.
4. Create a backup or rollback plan before a high-risk action.
5. Write an action report after execution.
6. Recover automatically or enter bounded retry after failure.
7. Pause only under `HUMAN_INTERRUPT_ONLY_POLICY.md`.

Routine scope expansion that is reasonably required by the final goal does not trigger human confirmation.

## High-Risk Action Protocol

High-risk actions include:

- deleting many project files
- large refactors
- release or tag configuration changes
- remote push, tag, or release
- system dependency installation
- database migration
- packaging or installer configuration changes
- Core Bridge execution boundary changes
- external provider, API, or proxy integration

Before a high-risk action:

1. Write `pre_action_checkpoint`.
2. Record the goal, reason, and affected scope.
3. Record a rollback plan or backup location.
4. Execute without routine human confirmation.
5. Run the relevant validation.
6. Write `post_action_report`.
7. On failure, roll back when safe or enter bounded recovery.

The checkpoint must contain:

- `action_id`
- `goal`
- `reason`
- `affected_scope`
- `risk_class`
- `pre_action_state`
- `rollback_plan`
- `validation_plan`
- `next_resume_step`

The action report must contain:

- `action_id`
- `command_or_operation`
- `result`
- `exit_code`
- `artifacts`
- `validation_result`
- `rollback_used`
- `recovery_status`
- `next_step`

## Precedence and Safety Boundary

This project policy removes routine confirmation points; it does not override:

- platform-enforced approval or sandbox requirements
- applicable law, security, privacy, and license restrictions
- the current project and local-machine authorization boundary
- missing credentials, payment authorization, or external service consent
- a more specific active task instruction, such as a temporary hold on push, tag, or release until acceptance is complete

When a platform requires an approval interaction, treat it as a platform control rather than a project-level pause condition.

## Prohibited Behavior

- Do not block a long task on a routine permission question.
- Do not stop an unattended run at an ordinary confirmation point.
- Do not repackage a pre-approved action as a new permission request.
- Do not pause merely because the required scope grew while still serving the final goal.
- Do not use unbounded retry.
- Do not execute a high-risk action without a checkpoint and rollback plan.
- Do not report a protected action as complete without a post-action report.

## Required Execution Wording

When an old pause condition is encountered, record:

```text
This action is covered by the Full Access Execution Policy.
A checkpoint has been created.
A rollback plan has been recorded.
Execution will continue automatically.
An action report will be written after execution.
```
