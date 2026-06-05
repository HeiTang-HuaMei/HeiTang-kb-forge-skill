# 快速开始

从仓库根目录运行：

```powershell
python -m heitang_kb_forge.cli doctor --output .\tmp_quickstart\doctor
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_quickstart\package --domain demo --mode quickstart --rag-export --agent-template --validate-package --quality-gate --run-manifest
```

v1.6 多模态与 Contract v2 smoke：

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_v16_verify --profile fast --progress-jsonl --multimodal --contract-version v2 --check-contract
python -m heitang_kb_forge.cli check-contract --package .\tmp_v16_verify --contract-version v2
python -m heitang_kb_forge.cli run --config .\examples\configs\kb_forge.v16.yaml
```

预期关键输出：

- `progress_events.jsonl`
- `multimodal_assets.jsonl`
- `multimodal_evidence_map.json`
- `multimodal_report.md`
- `contract_check_result.json`
- `contract_check_report.md`
# v1.7 快速开始

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_v17_verify --contract-version v2 --check-contract --governance --retrieval-index
python -m heitang_kb_forge.cli evidence-gate --package .\tmp_v17_verify --query "这个知识包主要讲什么？" --output .\tmp_v17_gate
```

# v1.8 快速开始

```powershell
python -m heitang_kb_forge.cli generate-skill --package .\tmp_v18_package --output .\tmp_v18_skill --skill-name "Demo Knowledge Skill" --skill-type generic
python -m heitang_kb_forge.cli validate-skill --skill .\tmp_v18_skill --package .\tmp_v18_package --output .\tmp_v18_skill_validation
python -m heitang_kb_forge.cli generate-agent --package .\tmp_v18_package --skill .\tmp_v18_skill --output .\tmp_v18_agent --agent-name "Demo Knowledge Agent" --agent-type generic
```

# v1.9 快速开始

```powershell
python -m heitang_kb_forge.cli workspace-init --workspace .\tmp_v19_workspace
python -m heitang_kb_forge.cli workspace-register --workspace .\tmp_v19_workspace --path .\tmp_v19_package --type knowledge
python -m heitang_kb_forge.cli workspace-provider add --workspace .\tmp_v19_workspace --provider-id mock_default --provider-type mock --model mock-model
python -m heitang_kb_forge.cli workspace-health --workspace .\tmp_v19_workspace
```

# v2.0 稳定版快速开始

```powershell
python -m heitang_kb_forge.cli studio-run --input .\examples\quickstart\input --workspace .\tmp_v20_workspace --project-name demo_project --profile stable
python -m heitang_kb_forge.cli stable-check --workspace .\tmp_v20_workspace
python -m heitang_kb_forge.cli provider-health --workspace .\tmp_v20_workspace
python -m heitang_kb_forge.cli reliability-score --workspace .\tmp_v20_workspace
python -m heitang_kb_forge.cli release-package --workspace .\tmp_v20_workspace --output .\tmp_v20_release
```

# v2.1 质量工作流

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_v21_package --contract-version v2 --check-contract --quality-score --retrieval-eval --evidence-benchmark
python -m heitang_kb_forge.cli quality-score --package .\tmp_v21_package --output .\tmp_v21_quality
python -m heitang_kb_forge.cli review-workflow --package .\tmp_v21_package --output .\tmp_v21_review
```
# v2.3 批量治理快速开始

```powershell
python -m heitang_kb_forge.cli batch-run --input .\examples\quickstart\input --output .\tmp_v23_batch --profile production --worker-pool --max-workers 2
python -m heitang_kb_forge.cli batch-retry --batch-job .\tmp_v23_batch\batch_job_manifest.json --retry-only-failed
python -m heitang_kb_forge.cli package-lineage --workspace .\tmp_v23_workspace --output .\tmp_v23_lineage
```
