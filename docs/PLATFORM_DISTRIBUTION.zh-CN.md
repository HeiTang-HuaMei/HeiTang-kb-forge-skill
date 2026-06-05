# 平台分发

v2.4 新增 opt-in 本地平台分发包，支持：

- `openclaw`
- `xhs`
- `codex`
- `claude_code`
- `mcp`
- `generic`
- `local_registry`

使用：

```powershell
python -m heitang_kb_forge.cli export-platform --skill .\skill_package --agent .\agent_package --output .\platform_export --platform generic
python -m heitang_kb_forge.cli platform-upload-check --export .\platform_export --output .\platform_check --platform generic
python -m heitang_kb_forge.cli mock-publish --export .\platform_export --platform generic --output .\mock_publish
```

标准输出：

- `platform_manifest.json`
- `platform_upload_check_result.json`
- `platform_upload_check_report.md`
- `mock_publish_result.json`
- `install_guide.md`
- `upload_guide.md`

上传检查范围：

- 平台必要文件。
- 导出文本文件中的疑似 API key。
- 导出文本文件中的危险命令片段。
- 真实上传始终禁用。

边界：

- 不使用真实平台账号。
- 不执行真实上传。
- 不真实运行 OpenClaw、Codex、Claude Code 或 MCP Runtime。
- 不启动 MCP Server。
- OpenClaw、Codex、Claude Code 和 MCP 输出只是本地导出包或 stub。
- 小红书输出不是小红书官方上传 API。
