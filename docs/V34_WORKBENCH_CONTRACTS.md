# v3.4 Local Workbench Integration Contracts

v3.4 adds opt-in Core-generated contracts for a future local Workbench UI integration.

## Scope

- Generate navigation, action, asset, status, manifest, trace, and Markdown contracts.
- Describe Core outputs without depending on a UI repository.
- Expose Agent creation as a first-class capability for both standalone and KB-bound modes.
- Expose mother/child Agent hierarchy, child bindings, memory policy, writeback actions, and memory trace/status contracts.
- Expose local storage status for packages, skills, agents, memory, indexes, and generated documents.
- Keep default build, run, and pipeline behavior unchanged unless enabled.

## Agent Contract Requirements

The Workbench contracts must expose:

- `supported_agent_modes: ["standalone", "kb_bound"]`
- `standalone_agent_schema`
- `kb_bound_agent_schema`
- required fields per mode
- optional fields per mode
- validation states
- error states
- `hierarchy_roles: ["mother_agent", "child_agent"]`

## Storage Contract Requirements

The default storage backend is `local_workspace`.

Future-compatible backend identifiers are reserved but not implemented as cloud service behavior:

- `local_db`
- `byo_cloud`

Storage contracts expose:

- storage status
- memory size
- package size
- index size
- cleanup suggestions
- compaction status
- backup/export status

The action contract must include:

- `create_standalone_agent`
- `create_kb_bound_agent`
- `validate_agent_package`
- `run_agent_smoke_test`
- `configure_agent_hierarchy`
- `queue_memory_writeback`
- `review_memory_candidate`
- `promote_memory_candidate`
- `inspect_storage_status`

Navigation and status contracts should allow UI pages for:

- Agent Builder
- KB-bound Agent Generator
- Standalone Agent Builder
- Agent Package Validator
- Agent Smoke Test
- Agent Hierarchy
- Memory Policy
- Memory Writeback
- Storage Status

## Commands

```powershell
python -m heitang_kb_forge.cli workbench-contracts --core-output .\tmp_core --output .\tmp_contracts --project-name "HeiTang Workbench"
```

Config-driven runs support:

```yaml
workbench_contracts:
  enabled: true
  project_name: HeiTang Workbench
```

## Output Files

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

## Boundaries

v3.4 only writes Core-side contracts. It does not modify the UI repository, start a UI, merge UI work, tag UI work, or perform frontend integration.
