# MCP Readiness Guide

HeiTang KB Forge v1.6.0 can export MCP readiness configuration for future Agent framework integration.

## Command

```powershell
heitang-kb-forge mcp export-config --output .\mcp_config
```

## Output Files

- mcp_server_config.yaml
- mcp_tools_manifest.json

## Boundaries

This release exports configuration only. It does not start an MCP server, call external Agent platforms, execute remote tools, or deploy a real Agent.
