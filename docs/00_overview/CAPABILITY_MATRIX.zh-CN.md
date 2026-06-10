# 能力矩阵

当前 Core package 版本：`4.1.1`
当前 stable release：`v4.1.1`
上一个 stable release：`v4.1.0`

| 领域 | 当前 main 分支真值 | 状态 |
| --- | --- | --- |
| 本地 ingestion | Markdown、TXT、DOCX、文本 PDF、图片/OCR 路由、CSV/TSV/XLSX、HTML、EPUB、ZIP 和混合源通过本地路径支持。 | implemented with parser-specific boundaries |
| Parser/OCR backend runtime | Builtin parser 保持默认 fallback。Docling、PaddleOCR、Unstructured 是真实 opt-in 本地 runtime adapters，并已有 registry、matrix、inspect、smoke、replay、failure-mode 和 Workbench-visible evidence。Unstructured stable surface 是 `.md/.txt`；Docling live evidence 是 Markdown/TXT；PaddleOCR live evidence 是 PNG OCR。更广 adapter-declared surface 需要 future hardening 才能作为 stable claim。 | implemented；optional dependency gated |
| External parser backend candidates | OpenDataLoader for PDF -> Markdown/JSON/RAG-ready packaging、MinerU，以及 PaddleOCR + MinerU as an OCR + document understanding pipeline 仍只是 external backend candidate / planned adapter。当前默认 parser truth 仍是 verified internal parser、bounded best-effort OCR 和 PDF token reduction。 | planned adapter；not default |
| 知识包 | 标准 package 输出包括 `manifest.json`、`chunks.jsonl`、`cards.jsonl`、`qa_pairs.jsonl`、`glossary.jsonl`、`quality_report.json`、`ingest_report.md`。 | implemented |
| 查询与检索 | 确定性 rewrite、planning、本地 index、本地 JSON vector query、hybrid retrieval、rerank、evidence selection、diagnostics 和 accuracy reports 已存在。 | implemented locally |
| 文档生成 | Grounded Markdown、DOCX、PDF、PPTX 通过本地命令和报告支持。 | implemented |
| Skill 与 Agent packages | Skill-first package generation、Agent package surfaces、KB-bound Agent proof、本地 mother/child runtime smoke 已存在。完整 autonomous tool-calling Agent runtime 未实现。 | partial |
| Workspace 与 memory | Local workspace registry、lifecycle、update/rebuild reports、memory policy、retention、token budget、no-cloud reports 已存在。默认不做破坏性 cleanup。 | partial |
| Provider 与 LLM 层 | 已有 optional provider profile acceptance。Core tests 不需要真实 LLM/API/network 调用。Provider secrets 不得进入提交输出。 | optional only |
| 隐私与安全 | Local-first、no hidden upload、secret redaction、no platform-hosted user data 和 threat-model evidence 已文档化并测试。 | implemented with review boundaries |
| 规模 | 已有 synthetic scale checks。真实 1500 books/KBs/Agents 未生产级证明。 | needs review |
| Test governance | Validation gate manifest、changed-file impact selector、dry-run / executable validation runner、pytest markers 和 obsolete-test pruning register 已存在。 | v4.1.1 test governance |
| UI | Core contracts、P1-RWF-V2 evidence、UI consumption proof 与 P2.1 parser backend matrix evidence 已存在。Static Workbench 可以展示状态、证据和限制，但不能暗示本地 heavy runtime 执行。 | v4.1.0 Workbench sync |

见 [当前真值](CURRENT_TRUTH.zh-CN.md)、[Parser Backend Strategy](../03_core_capabilities/PARSER_BACKEND_STRATEGY.zh-CN.md)、[最终产品架构真值](../FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md) 和 [P1 UI Core Parity](../10_roadmap/P1_UI_CORE_PARITY.zh-CN.md)。
