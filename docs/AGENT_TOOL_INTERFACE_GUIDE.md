# Agent Tool Interface Guide

HeiTang KB Forge v1.6.0 adds a local Agent-callable tool interface.

## Scope

The tool interface exports a registry and schema for Agent frameworks. It keeps KB Forge as a Skill-first, headless CLI-first package.

## Commands

```powershell
heitang-kb-forge tools export --output .\tool_exports
heitang-kb-forge tools list
heitang-kb-forge tools describe --name retrieve_knowledge
heitang-kb-forge tools invoke --name retrieve_knowledge --input .\input.json --output .\tool_run
```

## Export Files

- tool_registry.yaml
- tool_manifest.json
- agent_tool_schema.json
- tool_safety_policy.md

## Tool Invocation Files

- tool_execution_trace.json
- tool_result.json
- tool_error_report.json

## Tool Registry

The registry includes:

- build_knowledge_package
- batch_build_packages
- check_source_changes
- run_incremental_update
- validate_package_quality
- import_package_to_store
- retrieve_knowledge
- ask_package
- publish_package
- generate_planning_readiness

## Boundaries

- No remote execution.
- No external Agent platform calls.
- No Web UI dependency.
- Desktop UI remains a presentation layer.
