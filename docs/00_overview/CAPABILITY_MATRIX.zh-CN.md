# 能力矩阵

当前 Core 版本：`3.12.0-alpha.1`

| 领域 | 当前 main 分支真值 | 状态 |
| --- | --- | --- |
| 本地 ingestion | Markdown、TXT、DOCX、文本 PDF、图片/OCR 路由、CSV/TSV/XLSX、HTML、EPUB、ZIP 和混合源通过本地路径支持。 | implemented with parser-specific boundaries |
| Parser backend strategy | 已完成能力仍然是已验证的 internal parser、bounded best-effort OCR 和本地 PDF token reduction。OpenDataLoader 是端到端 PDF -> Markdown/JSON/RAG-ready parsing 的 external backend candidate；PaddleOCR 是 OCR foundation candidate；MinerU 是 document structure understanding 与 complex layout candidate；PaddleOCR + MinerU 是 planned OCR + document understanding pipeline。 | internal complete；external planned adapter only |
| 知识包 | 标准 package 输出包括 `manifest.json`、`chunks.jsonl`、`cards.jsonl`、`qa_pairs.jsonl`、`glossary.jsonl`、`quality_report.json`、`ingest_report.md`。 | implemented |
| 查询与检索 | 确定性 rewrite、planning、本地 index、本地 JSON vector query、hybrid retrieval、rerank、evidence selection、diagnostics 和 accuracy reports 已存在。 | implemented locally |
| 文档生成 | Grounded Markdown、DOCX、PDF、PPTX 通过本地命令和报告支持。 | implemented |
| Skill 与 Agent packages | Skill-first package generation、Agent package surfaces、KB-bound Agent proof、本地 mother/child runtime smoke 已存在。完整 autonomous tool-calling Agent runtime 未实现。 | partial |
| Workspace 与 memory | Local workspace registry、lifecycle、update/rebuild reports、memory policy、retention、token budget、no-cloud reports 已存在。默认不做破坏性 cleanup。 | partial |
| Provider 与 LLM 层 | 已有 optional provider profile acceptance。Core tests 不需要真实 LLM/API/network 调用。Provider secrets 不得进入提交输出。 | optional only |
| 隐私与安全 | Local-first、no hidden upload、secret redaction、no platform-hosted user data 和 threat-model evidence 已文档化并测试。 | implemented with review boundaries |
| 规模 | 已有 synthetic scale checks。真实 1500 books/KBs/Agents 未生产级证明。 | needs review |
| UI | Core contracts、P1-RWF-V2 evidence 和 UI consumption proof 已存在。P1 final gate re-run 仅表示可进入 v4 RC preparation。 | ready for v4 RC；not released |

见 [当前真值](CURRENT_TRUTH.zh-CN.md)、[Parser Backend Strategy](../03_core_capabilities/PARSER_BACKEND_STRATEGY.zh-CN.md)、[最终产品架构真值](../FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md) 和 [P1 UI Core Parity](../10_roadmap/P1_UI_CORE_PARITY.zh-CN.md)。
