# Recovery Checkpoint Policy

This policy defines the checkpoint files required before retrying transient failures or resuming interrupted long-running work.

## Required Files

Runtime recovery state is written under the project-local `.codex` directory:

- `.codex/recovery_checkpoint.json`
- `.codex/retry_log.jsonl`
- `.codex/recovery_report.md`
- `.codex/active_agents.json`

These are runtime artifacts. They may be cleaned or archived before release, but unresolved state must not be ignored.

## Checkpoint Fields

`recovery_checkpoint.json` must include:

- `current_goal`
- `current_slice_or_task`
- `completed_steps`
- `current_diff_summary`
- `changed_files`
- `test_status`
- `last_successful_command`
- `last_failed_command`
- `failure_type`
- `next_resume_step`
- `active_agents_snapshot`

## Retry Log

`retry_log.jsonl` records each retry attempt with timestamp, command or operation, failure type, retry number, backoff duration, and result.

## Recovery Report

`recovery_report.md` summarizes the failure, checkpoint, retry decisions, active agent cleanup, final status, and required manual action when retry cap is reached.

## Full Gate Precheck

Before Full Gate, verify:

- `.codex/recovery_checkpoint.json` is cleared or archived
- `.codex/active_agents.json` has no running or stale agent
- `.codex/retry_log.jsonl` has no unresolved retry
- `.codex/recovery_report.md` exists when recovery was needed

## Acceptance

Validation must cover checkpoint write, checkpoint resume, retry log append, no duplicate completed step execution, and Full Gate unresolved-state detection.
