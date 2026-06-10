# Capability Matrix

Current Core package version: `4.1.0`
Current stable release: `v4.1.0`

This short entry is for first-time GitHub readers. The detailed canonical matrix is [00_overview/CAPABILITY_MATRIX.md](00_overview/CAPABILITY_MATRIX.md).

| Area | What the Core provides now | Status |
| --- | --- | --- |
| Source import | Local ingestion for Markdown, TXT, DOCX, text PDF, image/OCR routes, CSV/TSV/XLSX, HTML, EPUB, ZIP, and mixed sources. | implemented with parser boundaries |
| Parser/OCR backend runtime | Builtin fallback plus opt-in real local runtime adapters for Docling, PaddleOCR, and Unstructured. The release evidence includes backend registry, matrix, inspect, smoke, replay, failure modes, and boundaries. | implemented; optional dependency gated |
| Knowledge assets | Standard package outputs: `manifest.json`, `chunks.jsonl`, `cards.jsonl`, `qa_pairs.jsonl`, `glossary.jsonl`, `quality_report.json`, `ingest_report.md`. | implemented |
| RAG / verification | Query rewrite, retrieval planning, local JSON vector query, hybrid retrieval, rerank, evidence selection, claim verification, contradiction detection, freshness checks. | implemented locally |
| Document generation | Grounded Markdown, DOCX, PDF, and PPTX outputs plus evidence appendix and openability checks. | implemented |
| Skill / Agent surface | Structured Skill packages, standalone Agent packages, KB-bound Agent packages, memory policy, local runtime smoke, and orchestration contracts. | partial |
| Workspace / Workbench | Local workspace registries, storage reports, artifact registry, task schema, P1 Workbench contracts, fixtures, V2 action evidence, UI consumption proof, and P2.1 parser backend matrix evidence. | v4.1.0 Workbench sync |
| Privacy / providers | Local-first reports, no hidden upload, secret redaction, optional provider boundaries. | implemented with review boundaries |

Docling, PaddleOCR, and Unstructured are completed P2.1 optional runtime integrations, not bundled defaults and not static Workbench executable controls. P2.1 validates Docling on Markdown/TXT samples, PaddleOCR on PNG OCR, and Unstructured on `.md/.txt`; broader surfaces remain bounded in [P2.1 backend capability boundaries](audits/p2_1_parser_ocr_backends/backend_capability_boundaries.md). OpenDataLoader and MinerU remain external backend candidates / planned adapters only.

See [Current Truth](CURRENT_TRUTH.md), [AIGC Book Content Pipeline](AIGC_BOOK_CONTENT_PIPELINE.md), and [Parser Backend Strategy](03_core_capabilities/PARSER_BACKEND_STRATEGY.md).
