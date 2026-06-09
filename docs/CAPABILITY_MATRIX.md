# Capability Matrix

Current Core package version: `4.0.0`
Current stable release: `v4.0.0`

This short entry is for first-time GitHub readers. The detailed canonical matrix is [00_overview/CAPABILITY_MATRIX.md](00_overview/CAPABILITY_MATRIX.md).

| Area | What the Core provides now | Status |
| --- | --- | --- |
| Source import | Local ingestion for Markdown, TXT, DOCX, text PDF, image/OCR routes, CSV/TSV/XLSX, HTML, EPUB, ZIP, and mixed sources. | implemented with parser boundaries |
| Knowledge assets | Standard package outputs: `manifest.json`, `chunks.jsonl`, `cards.jsonl`, `qa_pairs.jsonl`, `glossary.jsonl`, `quality_report.json`, `ingest_report.md`. | implemented |
| RAG / verification | Query rewrite, retrieval planning, local JSON vector query, hybrid retrieval, rerank, evidence selection, claim verification, contradiction detection, freshness checks. | implemented locally |
| Document generation | Grounded Markdown, DOCX, PDF, and PPTX outputs plus evidence appendix and openability checks. | implemented |
| Skill / Agent surface | Structured Skill packages, standalone Agent packages, KB-bound Agent packages, memory policy, local runtime smoke, and orchestration contracts. | partial |
| Workspace / Workbench | Local workspace registries, storage reports, artifact registry, task schema, P1 Workbench contracts, fixtures, V2 action evidence, and UI consumption proof. | stable v4.0.0 |
| Privacy / providers | Local-first reports, no hidden upload, secret redaction, optional provider boundaries. | implemented with review boundaries |

OpenDataLoader, PaddleOCR, and MinerU are external backend candidates / planned adapters only. They are not completed Core integrations.

See [Current Truth](CURRENT_TRUTH.md), [AIGC Book Content Pipeline](AIGC_BOOK_CONTENT_PIPELINE.md), and [Parser Backend Strategy](03_core_capabilities/PARSER_BACKEND_STRATEGY.md).
