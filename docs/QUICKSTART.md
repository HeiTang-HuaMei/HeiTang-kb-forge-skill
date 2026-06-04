# Quickstart

Run these commands from the repository root after installation.

```powershell
python -m heitang_kb_forge.cli doctor --output .\tmp_quickstart\doctor
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_quickstart\package --domain demo --mode quickstart --rag-export --agent-template --validate-package --quality-gate --run-manifest
python -m heitang_kb_forge.cli store init --db .\tmp_quickstart\kb_forge_workspace.db
python -m heitang_kb_forge.cli store import-package --db .\tmp_quickstart\kb_forge_workspace.db --package .\tmp_quickstart\package
python -m heitang_kb_forge.cli retrieve --package .\tmp_quickstart\package --query "这个知识包解决什么问题？" --output .\tmp_quickstart\retrieve
python -m heitang_kb_forge.cli ask --package .\tmp_quickstart\package --query "请总结这个知识包的核心能力。" --output .\tmp_quickstart\ask --citation-required
python -m heitang_kb_forge.cli tools export --output .\tmp_quickstart\tools
python -m heitang_kb_forge.cli mcp export-config --output .\tmp_quickstart\mcp
```

Expected result:

- A standard package in `.\tmp_quickstart\package`.
- A local SQLite store at `.\tmp_quickstart\kb_forge_workspace.db`.
- Retrieval and answer artifacts under `.\tmp_quickstart\retrieve` and `.\tmp_quickstart\ask`.
- Tool and MCP readiness exports under `.\tmp_quickstart\tools` and `.\tmp_quickstart\mcp`.
