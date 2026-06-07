# v3.4 Local Workbench Integration Contracts

v3.4 新增可选 Core-side contracts，用于后续本地 Workbench UI 集成。

## 范围

- 生成 navigation、action、asset、status、manifest、trace 和 Markdown contracts。
- 描述 Core 输出，不依赖 UI repo。
- 将 standalone 与 KB-bound 两种 Agent 创建模式作为一等能力暴露给未来 UI。
- 暴露 mother/child Agent hierarchy、child bindings、memory policy、writeback actions 和 memory trace/status contracts。
- 暴露 package、skill、agent、memory、index 和 generated documents 的本地 storage status。
- 未启用时默认 build、run 和 pipeline 行为不变。

## Agent Contract 要求

Workbench contracts 必须暴露：

- `supported_agent_modes: ["standalone", "kb_bound"]`
- `standalone_agent_schema`
- `kb_bound_agent_schema`
- 每种模式的 required fields
- 每种模式的 optional fields
- validation states
- error states
- `hierarchy_roles: ["mother_agent", "child_agent"]`

## Storage Contract 要求

默认 storage backend 是 `local_workspace`。

以下 backend identifier 仅为未来兼容预留，不实现云服务行为：

- `local_db`
- `byo_cloud`

Storage contracts 暴露：

- storage status
- memory size
- package size
- index size
- cleanup suggestions
- compaction status
- backup/export status

Action contract 必须包含：

- `create_standalone_agent`
- `create_kb_bound_agent`
- `validate_agent_package`
- `run_agent_smoke_test`
- `configure_agent_hierarchy`
- `queue_memory_writeback`
- `review_memory_candidate`
- `promote_memory_candidate`
- `inspect_storage_status`

Navigation 与 status contracts 应支持未来 UI 页面：

- Agent Builder
- KB-bound Agent Generator
- Standalone Agent Builder
- Agent Package Validator
- Agent Smoke Test
- Agent Hierarchy
- Memory Policy
- Memory Writeback
- Storage Status

## 命令

```powershell
python -m heitang_kb_forge.cli workbench-contracts --core-output .\tmp_core --output .\tmp_contracts --project-name "HeiTang Workbench"
```

配置驱动运行支持：

```yaml
workbench_contracts:
  enabled: true
  project_name: HeiTang Workbench
```

## 输出文件

- `workbench_contract_manifest.json`
- `workbench_navigation_contract.json`
- `workbench_action_contract.json`
- `workbench_agent_contract.json`
- `workbench_hierarchy_contract.json`
- `workbench_memory_contract.json`
- `workbench_storage_contract.json`
- `workbench_asset_contract.json`
- `workbench_status_contract.json`
- `workbench_contract_trace.json`
- `workbench_contract_report.md`

## 边界

v3.4 只写出 Core-side contracts。它不修改 UI repo，不启动 UI，不 merge UI work，不 tag UI work，也不做 frontend integration。
