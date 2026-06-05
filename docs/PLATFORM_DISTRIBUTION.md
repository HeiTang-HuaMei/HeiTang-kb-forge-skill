# Platform Distribution

v2.4 adds opt-in local platform distribution packages for:

- `openclaw`
- `xhs`
- `codex`
- `claude_code`
- `mcp`
- `generic`
- `local_registry`

Use:

```powershell
python -m heitang_kb_forge.cli export-platform --skill .\skill_package --agent .\agent_package --output .\platform_export --platform generic
python -m heitang_kb_forge.cli platform-upload-check --export .\platform_export --output .\platform_check --platform generic
python -m heitang_kb_forge.cli mock-publish --export .\platform_export --platform generic --output .\mock_publish
```

Standard outputs:

- `platform_manifest.json`
- `platform_upload_check_result.json`
- `platform_upload_check_report.md`
- `mock_publish_result.json`
- `install_guide.md`
- `upload_guide.md`

Boundary:

- No real platform account is used.
- No real upload is performed.
- No real OpenClaw, Codex, Claude Code, or MCP runtime is started.
- No MCP server is started.
