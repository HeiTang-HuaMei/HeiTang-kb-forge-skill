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

Optional progress and large-file performance smoke:

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_quickstart\package_progress --domain demo --mode quickstart --progress-jsonl --profile fast
```

Expected additional files:

- `progress_events.jsonl`
- `large_file_performance_report.md`
# v1.7 Quickstart

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_v17_verify --contract-version v2 --check-contract --governance --retrieval-index
python -m heitang_kb_forge.cli evidence-gate --package .\tmp_v17_verify --query "What is this package about?" --output .\tmp_v17_gate
```

# v1.8 Quickstart

```powershell
python -m heitang_kb_forge.cli generate-skill --package .\tmp_v18_package --output .\tmp_v18_skill --skill-name "Demo Knowledge Skill" --skill-type generic
python -m heitang_kb_forge.cli validate-skill --skill .\tmp_v18_skill --package .\tmp_v18_package --output .\tmp_v18_skill_validation
python -m heitang_kb_forge.cli generate-agent --package .\tmp_v18_package --skill .\tmp_v18_skill --output .\tmp_v18_agent --agent-name "Demo Knowledge Agent" --agent-type generic
```

# v1.9 Quickstart

```powershell
python -m heitang_kb_forge.cli workspace-init --workspace .\tmp_v19_workspace
python -m heitang_kb_forge.cli workspace-register --workspace .\tmp_v19_workspace --path .\tmp_v19_package --type knowledge
python -m heitang_kb_forge.cli workspace-provider add --workspace .\tmp_v19_workspace --provider-id mock_default --provider-type mock --model mock-model
python -m heitang_kb_forge.cli workspace-health --workspace .\tmp_v19_workspace
```

# v2.0 Stable Workflow

```powershell
python -m heitang_kb_forge.cli studio-run --input .\examples\quickstart\input --workspace .\tmp_v20_workspace --project-name demo_project --profile stable
python -m heitang_kb_forge.cli stable-check --workspace .\tmp_v20_workspace
python -m heitang_kb_forge.cli provider-health --workspace .\tmp_v20_workspace
python -m heitang_kb_forge.cli reliability-score --workspace .\tmp_v20_workspace
python -m heitang_kb_forge.cli release-package --workspace .\tmp_v20_workspace --output .\tmp_v20_release
```

# v2.1 Quality Workflow

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_v21_package --contract-version v2 --check-contract --quality-score --retrieval-eval --evidence-benchmark
python -m heitang_kb_forge.cli quality-score --package .\tmp_v21_package --output .\tmp_v21_quality
python -m heitang_kb_forge.cli review-workflow --package .\tmp_v21_package --output .\tmp_v21_review
```
# v2.3 Batch Governance Quickstart

```powershell
python -m heitang_kb_forge.cli batch-run --input .\examples\quickstart\input --output .\tmp_v23_batch --profile production --worker-pool --max-workers 2
python -m heitang_kb_forge.cli batch-retry --batch-job .\tmp_v23_batch\batch_job_manifest.json --retry-only-failed
python -m heitang_kb_forge.cli package-lineage --workspace .\tmp_v23_workspace --output .\tmp_v23_lineage
```
