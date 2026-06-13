# Codex Resilience Rules

These rules govern long-running Codex execution. They prevent duplicate work, runaway retries, and ambiguous recovery after transient failures.

## Transient Failure Classification

Treat the following as transient only when the surrounding command or API call supports that interpretation:

- `network timeout`
- `connection reset`
- `request failed`
- `429`
- `too many requests`
- `rate limit`
- `temporary unavailable`
- `gateway timeout`
- `server overloaded`
- `Codex connection interrupted`

Do not classify real test failures, assertion failures, syntax errors, scope violations, or policy violations as transient failures.

## Checkpoint Before Retry

Before any retry, write checkpoint artifacts defined by `RECOVERY_CHECKPOINT_POLICY.md`.

## Retry Policy

Use bounded backoff:

- retry 1: wait 3 minutes
- retry 2: wait 7 minutes
- retry 3: wait 15 minutes
- retry 4: stop further requests, write recovery report, and wait for human handling

## Prohibited Behavior

- no infinite retries
- no increased concurrency after `429`
- no duplicate execution of completed steps
- no duplicate sub-agent spawn after interruption
- no retry before checkpoint
- no network interruption reported as a test failure
- no real test failure reported as a transient failure

## Resume Flow

1. Read `.codex/recovery_checkpoint.json`.
2. Read `.codex/retry_log.jsonl`.
3. Read `.codex/active_agents.json`.
4. Clean up completed, idle, and stale sub-agents.
5. Classify the failure type.
6. Resume with retry policy for transient failures.
7. Enter debug for real test failures.
8. Stop and write `scope_violation_report` for scope violations.
9. Continue from `next_resume_step` without redoing `completed_steps`.

## Acceptance

Validation must cover transient failure classification, retry policy, checkpoint write, checkpoint resume, no infinite retry, no duplicate work, and no duplicate sub-agent spawn.
