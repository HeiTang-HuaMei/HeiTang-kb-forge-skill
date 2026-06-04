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
