# v3.2 Multi-KB and Multi-Agent Orchestration

v3.2 adds an opt-in local orchestration contract for multiple knowledge packages and optional Agent packages.

## Scope

- Build deterministic package route maps.
- Build simple Agent-to-package binding graphs.
- Support registries containing both `kb_bound` and `standalone` Agents.
- Support a `mother_agent` with `child_agents` and explicit parent-child binding records.
- Detect overlapping evidence terms across packages.
- Write orchestration manifest, trace, conflict, graph, and Markdown reports.
- Write hierarchy, memory writeback, memory promotion, memory isolation, and memory lifecycle reports.
- Keep default build, run, and pipeline behavior unchanged unless enabled.

## Agent Registry Requirements

Agent registry records must include:

- `agent_id`
- `mode`: `kb_bound` or `standalone`
- `bound_kbs`
- `capabilities`
- `memory_policy`
- `provider_profile`
- `tool_policy`
- `routing_tags`

## Routing Rules

- Mother Agent routing is contract-only: tasks are routed from the mother to selected child Agent records.
- KB/domain questions should prefer `kb_bound` Agents with matching trusted KBs.
- Planning, process, formatting, and coaching tasks may route to `standalone` Agents.
- `standalone` Agents must not be routed to answer KB-grounded factual questions unless workflow policy explicitly allows non-grounded handling.
- Route reports must show whether the selected Agent was `kb_bound` or `standalone`.
- Unauthorized KB access must remain blocked.
- Memory isolation applies to both modes.
- Child private memory is the default.
- Workflow shared memory is enabled only when explicitly requested.
- Parent memory writeback is selective and produces candidate records, not direct long-term writes.
- Binding graphs must show standalone Agents as no-KB nodes.

## Memory Lifecycle

Memory reports expose structured lifecycle fields instead of raw append-only logs only:

- `session_log`
- `short_term_memory`
- `summary_memory`
- `long_term_memory`
- `memory_candidates`
- `memory_index`
- `retention_policy`
- `compaction_policy`
- `token_budget_policy`

## Commands

```powershell
python -m heitang_kb_forge.cli orchestrate-multi-kb --packages .\pkg_a,.\pkg_b --output .\tmp_orchestration --query "pricing policy"
```

Config-driven runs support:

```yaml
multi_kb_orchestration:
  enabled: true
  query: pricing policy
  workflow_shared_memory: false
  parent_writeback: false
```

## Output Files

- `multi_kb_orchestration_manifest.json`
- `multi_kb_route_map.json`
- `multi_agent_binding_graph.json`
- `multi_kb_conflict_report.json`
- `hierarchy_trace.json`
- `memory_candidate_queue.jsonl`
- `memory_writeback_report.json`
- `memory_promotion_report.json`
- `memory_isolation_report.json`
- `memory_lifecycle_report.json`
- `multi_kb_orchestration_trace.json`
- `multi_kb_orchestration_report.md`

## Boundaries

v3.2 is a local contract and planning layer. It does not execute agents, call external runtimes, call LLM APIs, call embedding APIs, or write vector databases.
