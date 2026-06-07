# v3.10 Local Agent Runtime & Mother/Child Operations

v3.10 adds a deterministic local runtime smoke layer for mother/child Agent operations. It builds on v3.2 hierarchy contracts and v3.9 memory/storage contracts without implementing a full Agent Runtime, long-term memory database, SaaS, cloud sync, or UI.

## Capabilities

- Route a local task from a mother agent to a child agent.
- Support standalone child agents and KB-bound child agents.
- Enforce per-child KB access boundaries.
- Preserve child private memory by default.
- Allow workflow shared memory only when explicitly enabled.
- Queue selective parent memory writeback as reviewable candidate actions.
- Generate local runtime session, route trace, KB access report, memory isolation report, workflow shared memory report, parent writeback actions, and runtime status.

## Local-First Boundary

The v3.10 runtime is deterministic and local. It reads local package chunks, local agent manifests, and local hierarchy reports. It does not call real LLM providers, does not require network, does not write to a real long-term memory database, and does not auto-promote child memory to parent memory.

## CLI

```powershell
python -m heitang_kb_forge.cli run-local-agent --package .\package --agent .\agent --task "pricing policy" --output .\runtime
```

## Config

```yaml
local_agent_runtime:
  enabled: true
  packages: []
  agents: []
  task: "Summarize this knowledge package."
  workflow_shared_memory: false
  parent_writeback: false
  allow_llm: false
  allow_network: false
```

## Reports

- `local_agent_runtime_session.json`
- `local_agent_runtime_trace.json`
- `mother_child_runtime_trace.json`
- `child_task_route_trace.json`
- `child_kb_access_report.json`
- `child_memory_isolation_report.json`
- `workflow_shared_memory_report.json`
- `parent_memory_writeback_actions.json`
- `local_agent_runtime_status.json`
- `local_agent_runtime_report.md`
