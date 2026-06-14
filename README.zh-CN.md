# HeiTang Knowledge Workbench

HeiTang Knowledge Workbench 是本地优先的知识供应链 Core。它把本地资料整理成可追溯、可检索、可验证、可复用的知识资产，并继续支持文档输出、Skill 生成和 Agent 创建包。

当前 Core 基线：`v4.2.0`
当前 Core package 版本：`4.2.0`
当前 stable release：`v4.2.0`
上一个 stable release：`v4.1.1`
历史 stable release：`v4.0.0`

LLM 集成是可选能力。Parser/OCR extras 依赖门控，不随默认安装打包。

## 公开文档

- 项目概览：[docs/项目概览.md](docs/项目概览.md)
- 快速开始：[docs/快速开始.md](docs/快速开始.md)
- 使用指南：[docs/使用指南.md](docs/使用指南.md)
- 产品定位：[docs/产品定位.md](docs/产品定位.md)
- 系统架构：[docs/系统架构.md](docs/系统架构.md)
- 知识供应链架构：[docs/知识供应链架构.md](docs/知识供应链架构.md)
- Skill 与 Agent 生成说明：[docs/Skill与Agent生成说明.md](docs/Skill与Agent生成说明.md)
- 路线图：[docs/路线图.md](docs/路线图.md)
- 测试与验收：[docs/测试与验收.md](docs/测试与验收.md)
- 发布流程：[docs/发布流程.md](docs/发布流程.md)
- English README：[README.md](README.md)

## 产品产物

- Knowledge Package
- Document Outputs：Markdown、DOCX、PDF、PPTX
- Skill Outputs：Skill Template、Skill Suite
- Agent Creation Package

## 快速开始

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

可选本地 parser/OCR extras 依赖门控，不随默认安装打包：

```powershell
python -m pip install -e ".[ocr,pdf-table,parser-docling,parser-marker,parser-paddleocr,parser-unstructured,web]"
```

## 边界

- 本仓库是 Core package，Campaign 4 UI 未启动。
- Local Core Bridge / Campaign 5 未完成。
- Agent Creation Package 不等于 Agent Runtime ready。
- Redis / Vector DB-backed Memory Store Connector 是 future target，不是当前 runtime dependency。
- 长视频 / GPU 生成不属于当前产品路线。
- 外部 provider 和网络相关动作必须由用户显式配置。
- 本次清理不创建 GitHub Release，也不创建稳定 `campaign-1-3-baseline` tag。

## 仓库公开表面

public main 分支只代表当前 v4.2 产品基线。pre-v4.2 审计堆、旧 RC 报告、旧 Campaign 中间证据、临时 `current_run` / `latest` artifacts 不保留在 main。历史细节通过 Git history 和 tag 查询。

工程关键路径保持英文：`heitang_kb_forge/`、`tests/`、`scripts/`、`examples/`、`assets/`、`desktop/`、`packaging/`、`.github/`。

## License

MIT License. See [LICENSE](LICENSE)。
