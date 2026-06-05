# Agent 兼容性

v2.2 checkpoint 后补增加本地 Agent 兼容 stub。

使用：

```powershell
python -m heitang_kb_forge.cli generate-agent --package .\package --skill .\skill --output .\agent --agent-compat
```

`agent_package/compat/` 下生成：

- `openclaw_agent.yaml`
- `claude_code_instructions.md`
- `codex_instructions.md`
- `codex_task_plan.md`
- `mcp_resources.json`
- `mcp_tools_stub.json`
- `mcp_manifest.json`
- `generic_agent_profile.yaml`

这些只是兼容文件和 stub，不真实运行 OpenClaw、Codex、Claude Code 或 MCP Server。
