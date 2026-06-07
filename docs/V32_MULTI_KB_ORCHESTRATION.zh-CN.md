# v3.2 Multi-KB and Multi-Agent Orchestration

v3.2 新增可选本地 orchestration contract，用于多个知识包和可选 Agent package。

## 范围

- 构建确定性的 package route map。
- 构建简单的 Agent 到 package 绑定图。
- 支持同时包含 `kb_bound` 与 `standalone` Agent 的 registry。
- 支持 `mother_agent`、`child_agents` 和显式 parent-child binding records。
- 检测多个 package 之间的 evidence term 重叠。
- 写出 orchestration manifest、trace、conflict、graph 和 Markdown report。
- 写出 hierarchy、memory writeback、memory promotion、memory isolation 和 memory lifecycle reports。
- 未启用时默认 build、run 和 pipeline 行为不变。

## Agent Registry 要求

Agent registry record 必须包含：

- `agent_id`
- `mode`: `kb_bound` 或 `standalone`
- `bound_kbs`
- `capabilities`
- `memory_policy`
- `provider_profile`
- `tool_policy`
- `routing_tags`

## 路由规则

- Mother Agent 路由仅是 contract：任务从 mother 路由到被选中的 child Agent record。
- KB/domain 问题应优先路由到绑定 trusted KB 的 `kb_bound` Agent。
- planning、process、formatting、coach 类任务可以路由到 `standalone` Agent。
- 除非 workflow policy 显式允许非 grounded handling，否则 `standalone` Agent 不得回答 KB-grounded factual questions。
- route report 必须显示被选 Agent 是 `kb_bound` 还是 `standalone`。
- 未授权 KB 访问必须继续阻断。
- 两种模式都必须应用 memory isolation。
- child private memory 是默认策略。
- workflow shared memory 只有显式开启时才启用。
- parent memory writeback 是 selective candidate queue，不直接写 long-term memory。
- binding graph 必须把 standalone Agent 表示为 no-KB node。

## Memory Lifecycle

Memory reports 暴露结构化 lifecycle 字段，而不是只有 raw append-only log：

- `session_log`
- `short_term_memory`
- `summary_memory`
- `long_term_memory`
- `memory_candidates`
- `memory_index`
- `retention_policy`
- `compaction_policy`
- `token_budget_policy`

## 命令

```powershell
python -m heitang_kb_forge.cli orchestrate-multi-kb --packages .\pkg_a,.\pkg_b --output .\tmp_orchestration --query "pricing policy"
```

配置驱动运行支持：

```yaml
multi_kb_orchestration:
  enabled: true
  query: pricing policy
  workflow_shared_memory: false
  parent_writeback: false
```

## 输出文件

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

## 边界

v3.2 是本地 contract 与 planning layer。它不执行 Agent，不调用外部 runtime，不调用 LLM API，不调用 embedding API，也不写入向量库。
