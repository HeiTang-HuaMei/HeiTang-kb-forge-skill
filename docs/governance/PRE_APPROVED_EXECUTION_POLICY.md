# Pre-Approved Execution Policy

The following actions are pre-approved when they are necessary for the active HeiTang KB Forge goal and remain inside the authorized project, workspace, and local-machine boundary.

## Pre-Approved Actions

- expand the working scope required by the final goal
- register user-provided external projects
- modify Core, UI, workspace project files, governance, tests, docs, and audits
- remove or refactor obsolete project files
- install project-local dependencies
- install system dependencies with version, source, path, checkpoint, rollback, and action report
- perform dependency remediation
- run real adapter smoke
- perform local packaging, installer, and portable builds
- run Fast Gate, Full Gate, Release Check, and Full Review when the active task permits them
- create local commits
- push, tag, and create a GitHub Release when the active task permits release actions
- synchronize workspace status, handoff, and task logs
- create, close, and archive sub-agents
- perform bounded retry, checkpoint, and recovery
- refactor the UI
- extend the Core Bridge
- change engineering required by the EXE packaging chain

These actions do not trigger routine human confirmation.

## Protection Requirements

| Action | Required protection | Routine human confirmation |
| --- | --- | --- |
| reasonable scope expansion | goal ledger update | no |
| project dependency install | install log and action report | no |
| system dependency install | pre-action checkpoint, source/version/path, rollback plan, post-action report | no |
| push, tag, GitHub Release | pre-action checkpoint, remote/commit/tag record, rollback plan, post-action report | no |
| destructive project-file cleanup | pre-action checkpoint, file inventory or backup, rollback plan, post-action report | no |
| database migration | pre-action checkpoint, backup, rollback plan, migration validation | no |
| packaging or installer change | pre-action checkpoint, rollback plan, build validation, post-action report | no |
| Core Bridge execution boundary change | pre-action checkpoint, threat/risk note, rollback plan, Core/UI validation | no |
| external provider, API, or proxy integration | checkpoint, secret-safe plan, rollback plan, connectivity validation | no |
| retry or recovery | recovery checkpoint and bounded retry log | no |
| sub-agent cleanup | lifecycle registry update and archive/termination record | no |

## Release Action Constraint

Pre-approved means no routine permission prompt is required. It does not mean a release action should run before its task-specific acceptance condition.

For the current goal, the active instruction to avoid push, tag, and release until the full target is complete remains controlling. Once that condition is satisfied, release actions may proceed under the high-risk action protocol without another routine confirmation.

## Scope Boundary

Automatic scope expansion may include the current project repositories, project workspace files, project governance, local dependency environments, local packaging tools, and local machine dependencies required by the product.

It does not authorize unrelated projects, unrelated user data, real production data, third-party accounts, or irreversible external operations outside the current goal.
