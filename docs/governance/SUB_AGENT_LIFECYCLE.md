# Sub-Agent Lifecycle Governance

Sub-agents are planning or execution helpers. They can advise, inspect, or patch bounded file scopes, but final decisions stay with the main agent.

## Registry

Every spawned sub-agent must be registered in:

- `.codex/active_agents.json`
- `.codex/sub_agent_lifecycle_report.md`

Required fields:

- `agent_id`
- `role`
- `owner_task`
- `status`
- `created_at`
- `last_activity_at`
- `retry_count`
- `current_file_scope`
- `expected_output`
- `close_condition`
- `final_summary`
- `adopted_suggestions`
- `rejected_suggestions`
- `archive_path`

## Status Values

Allowed statuses:

- `created`
- `running`
- `blocked`
- `waiting_retry`
- `completed`
- `failed`
- `archived`
- `terminated`

## Concurrency Limit

Default maximum running sub-agents: 2.

Heavy tasks may use at most 3 running sub-agents, and the main agent must record why the extra concurrency is needed.

Do not open unlimited sub-agents. Do not open multiple identical-role sub-agents for the same unresolved question.

## Automatic Close Rules

1. A completed sub-agent must be archived.
2. An idle sub-agent older than 15 minutes must be archived or terminated.
3. A blocked sub-agent older than 20 minutes must report back to the main agent.
4. A sub-agent with more than 3 retries must be terminated.
5. When `owner_task` is complete, all related sub-agents must be closed or archived.
6. Before task resume, stale agents must be cleaned up.

## Main-Agent Consolidation

Sub-agent output cannot directly decide final state. The main agent must record:

- sub-agent suggestion
- adopted suggestions
- rejected suggestions
- rejection reason
- final main-agent judgment
- whether it affects `integration_decision`
- whether it affects UI integration
- whether it affects test scope

Example: if a sub-agent suggests `needs_strengthening` only because a dependency is missing, the main agent must apply the dependency remediation policy first.

## Acceptance

Validation must cover active agent registry, max concurrency, idle cleanup, completed archive, retry cap, stale cleanup, and main-agent decision consolidation.
