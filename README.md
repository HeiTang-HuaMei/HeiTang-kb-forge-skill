# HeiTang Knowledge Workbench

HeiTang Knowledge Workbench is an offline-first local knowledge supply chain Core. It turns local materials into traceable, searchable, verifiable, reusable knowledge assets, then supports document outputs, Skill generation, and Agent creation packages.

Current Core baseline: `v4.2.0`
Current Core package version: `4.2.0`
Current stable release: `v4.2.0`
Previous stable release: `v4.1.1`

LLM integration is optional. Parser/OCR extras are dependency-gated and not bundled by default.

## Public Docs

- Chinese overview: [docs/项目概览.md](docs/项目概览.md)
- Quick start: [docs/快速开始.md](docs/快速开始.md)
- User guide: [docs/使用指南.md](docs/使用指南.md)
- Product positioning: [docs/产品定位.md](docs/产品定位.md)
- Architecture: [docs/系统架构.md](docs/系统架构.md)
- Knowledge supply chain: [docs/知识供应链架构.md](docs/知识供应链架构.md)
- Skill and Agent generation: [docs/Skill与Agent生成说明.md](docs/Skill与Agent生成说明.md)
- Roadmap: [docs/路线图.md](docs/路线图.md)
- Testing and acceptance: [docs/测试与验收.md](docs/测试与验收.md)
- Release flow: [docs/发布流程.md](docs/发布流程.md)
- Chinese README: [README.zh-CN.md](README.zh-CN.md)

## Product Outputs

- Knowledge Package
- Document Outputs: Markdown, DOCX, PDF, PPTX
- Skill Outputs: Skill Template, Skill Suite
- Agent Creation Package

## Quick Start

```powershell
python -m pip install -e ".[dev]"
python -m heitang_kb_forge.cli doctor --output .\tmp_doctor
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_quickstart_output
python -m heitang_kb_forge.cli check-contract --package .\tmp_quickstart_output --output .\tmp_contract
python -m heitang_kb_forge.cli kb-index --package .\tmp_quickstart_output --output .\tmp_kb_index
python -m heitang_kb_forge.cli kb-query --package .\tmp_quickstart_output --query "Summarize the package" --output .\tmp_kb_query
python -m heitang_kb_forge.cli generate-documents --package .\tmp_quickstart_output --output .\tmp_documents
python -m heitang_kb_forge.cli final-pre-v4-audit --core-repo . --output .\tmp_final_audit
```

Optional local parser/OCR extras are dependency-gated and are not bundled by default:

```powershell
python -m pip install -e ".[ocr,pdf-table,parser-docling,parser-marker,parser-paddleocr,parser-unstructured,web]"
```

## Boundaries

- This repository is the Core package. Campaign 4 UI work is not active.
- Local Core Bridge / Campaign 5 is not complete.
- Agent Creation Package does not mean Agent Runtime ready.
- Redis / Vector DB-backed Memory Store Connector is a future target, not a current runtime dependency.
- Long video / GPU generation is not part of the current product route.
- External providers and network-dependent actions require explicit configuration.
- No GitHub Release or stable `campaign-1-3-baseline` tag is created by this cleanup.

## Repository Surface

The public main branch represents the current v4.2 product baseline. Pre-v4.2 audit piles, old RC reports, old campaign intermediate evidence, and temporary `current_run` / `latest` artifacts are not kept in main. Historical detail remains available through Git history and tags.

Engineering-critical paths remain in English: `heitang_kb_forge/`, `tests/`, `scripts/`, `examples/`, `assets/`, `desktop/`, `packaging/`, and `.github/`.

## License

MIT License. See [LICENSE](LICENSE).
