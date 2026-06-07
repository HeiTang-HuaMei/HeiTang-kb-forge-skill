# Network Dependency Audit Report

- Status: needs_review
- Tests require real LLM/API/network: False

```json
{
  "audit_version": "final-pre-v4.0",
  "status": "needs_review",
  "network_reference_count": 835,
  "network_references": [
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/CHANGELOG.md",
      "line": "* Added local PDF-to-Markdown preprocessing report, parser backend selection/benchmark, PDF token reduction, and no-cloud-upload reports."
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/CHANGELOG.md",
      "line": "* No real XHS upload"
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/CHANGELOG.md",
      "line": "* Added `platform-upload-check`"
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/CHANGELOG.md",
      "line": "* Added upload check and mock publish outputs"
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/CHANGELOG.md",
      "line": "* Added static upload checks for suspicious API keys and dangerous command snippets"
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/CHANGELOG.md",
      "line": "* Did not implement v2.4 platform distribution or upload adapters"
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/CHANGELOG.md",
      "line": "* No platform distribution or upload adapters"
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/CHANGELOG.md",
      "line": "* Reserved platform export and upload adapters for v2.4"
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/provider_config.example.yaml",
      "line": "docs_url: https://platform.openai.com/docs/api-reference"
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/pyproject.toml",
      "line": "Homepage = \"https://github.com/HeiTang-HuaMei/HeiTang-kb-forge-skill\""
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/pyproject.toml",
      "line": "Repository = \"https://github.com/HeiTang-HuaMei/HeiTang-kb-forge-skill\""
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/pyproject.toml",
      "line": "Issues = \"https://github.com/HeiTang-HuaMei/HeiTang-kb-forge-skill/issues\""
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/README.md",
      "line": "- v3.9 Local Workspace Storage & Memory Lifecycle: local registries, storage usage, dedup/cleanup/retention plans, memory lifecycle, token budget policy, local PDF token reduction, parser backend benc"
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/README.md",
      "line": "- no hidden upload"
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/README.md",
      "line": "- upload user documents or generated packages"
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/README.zh-CN.md",
      "line": "- v3.9 Local Workspace Storage & Memory Lifecycle：本地 registry、storage usage、dedup/cleanup/retention plans、memory lifecycle、token budget policy、本地 PDF token reduction、parser backend benchmark 和 no-clou"
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/v312_external_absorption_map.json",
      "line": "\"what_not_to_copy\": \"Telemetry, hidden uploads, platform-hosted diagnostics, or external prompts.\","
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/v312_external_absorption_map.json",
      "line": "\"reason\": \"The safe pattern is local-only verification with redacted output and no hidden upload behavior.\","
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/desktop/tauri/package-lock.json",
      "line": "\"resolved\": \"https://registry.npmjs.org/@babel/code-frame/-/code-frame-7.29.7.tgz\","
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/desktop/tauri/package-lock.json",
      "line": "\"resolved\": \"https://registry.npmjs.org/@babel/compat-data/-/compat-data-7.29.7.tgz\","
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/desktop/tauri/package-lock.json",
      "line": "\"resolved\": \"https://registry.npmjs.org/@babel/core/-/core-7.29.7.tgz\","
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/desktop/tauri/package-lock.json",
      "line": "\"url\": \"https://opencollective.com/babel\""
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/desktop/tauri/package-lock.json",
      "line": "\"resolved\": \"https://registry.npmjs.org/@babel/generator/-/generator-7.29.7.tgz\","
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/desktop/tauri/package-lock.json",
      "line": "\"resolved\": \"https://registry.npmjs.org/@babel/helper-compilation-targets/-/helper-compilation-targets-7.29.7.tgz\","
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/desktop/tauri/package-lock.json",
      "line": "\"resolved\": \"https://registry.npmjs.org/@babel/helper-globals/-/helper-globals-7.29.7.tgz\","
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/desktop/tauri/package-lock.json",
      "line": "\"resolved\": \"https://registry.npmjs.org/@babel/helper-module-imports/-/helper-module-imports-7.29.7.tgz\","
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/desktop/tauri/package-lock.json",
      "line": "\"resolved\": \"https://registry.npmjs.org/@babel/helper-module-transforms/-/helper-module-transforms-7.29.7.tgz\","
    },
    {
      "path": "C:/Users/Administrator/Documents/New project 2/kb-forge-skill/desktop/tauri
```
