# v3.10 本地 Agent Runtime 与母子 Agent 操作

v3.10 增加确定性的本地 runtime smoke 层，用于验证 mother/child Agent 操作。它基于 v3.2 hierarchy contracts 和 v3.9 memory/storage contracts，不实现完整 Agent Runtime、长期记忆数据库、SaaS、云同步或 UI。

## 能力范围

- 将本地任务从 mother agent 路由到 child agent。
- 支持 standalone child agents 和 KB-bound child agents。
- 强制执行每个 child 的 KB 访问边界。
- 默认保留 child private memory。
- 只有显式开启时才允许 workflow shared memory。
- 将 selective parent memory writeback 写成可复核 candidate actions。
- 生成本地 runtime session、route trace、KB access report、memory isolation report、workflow shared memory report、parent writeback actions 和 runtime status。

## 本地优先边界

v3.10 runtime 是确定性本地执行。它只读取本地 package chunks、本地 agent manifests 和本地 hierarchy reports。不调用真实 LLM provider、不需要网络、不写入真实长期记忆数据库，也不会自动把 child memory 提升到 parent memory。

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

## 报告

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
