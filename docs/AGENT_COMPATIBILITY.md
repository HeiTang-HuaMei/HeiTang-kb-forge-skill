# Agent Compatibility

v2.2 checkpoint fill adds local Agent compatibility stubs.

Use:

```powershell
python -m heitang_kb_forge.cli generate-agent --package .\package --skill .\skill --output .\agent --agent-compat
```

Generated files under `agent_package/compat/`:

- `openclaw_agent.yaml`
- `claude_code_instructions.md`
- `codex_instructions.md`
- `codex_task_plan.md`
- `mcp_resources.json`
- `mcp_tools_stub.json`
- `mcp_manifest.json`
- `generic_agent_profile.yaml`

These are compatibility files and stubs only. They do not run OpenClaw, Codex, Claude Code, or an MCP server.
