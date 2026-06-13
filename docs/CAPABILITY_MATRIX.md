# Capability Matrix

Current Core package version: `4.2.0`
Current stable release: `v4.2.0`
Previous stable release: `v4.1.1`

This short entry is for first-time GitHub readers. The detailed canonical matrix is [00_overview/CAPABILITY_MATRIX.md](00_overview/CAPABILITY_MATRIX.md).

| Area | What the Core provides now | Status |
| --- | --- | --- |
| Source import | Local ingestion for Markdown, TXT, DOCX, text PDF, image/OCR routes, CSV/TSV/XLSX, HTML, EPUB, ZIP, and mixed sources. | implemented with parser boundaries |
| Parser/OCR backend runtime | Builtin fallback plus opt-in real local runtime adapters for Docling, PaddleOCR, and Unstructured. The release evidence includes backend registry, matrix, inspect, smoke, replay, failure modes, and boundaries. | implemented; optional dependency gated |
| Knowledge assets | Standard package outputs: `manifest.json`, `chunks.jsonl`, `cards.jsonl`, `qa_pairs.jsonl`, `glossary.jsonl`, `quality_report.json`, `ingest_report.md`. | implemented |
| Product output surfaces | `knowledge_package`, `document_outputs`, `skill_outputs`, and `agent_creation_package` are distinct product output surfaces. | registered product boundary |
| RAG / verification | Query rewrite, retrieval planning, local JSON vector query, hybrid retrieval, rerank, evidence selection, claim verification, contradiction detection, freshness checks. | implemented locally |
| Document Outputs | Grounded Markdown, DOCX / Word, PDF, and PPTX / PowerPoint outputs through `generate-documents`. This is a first-class product output surface, not an audit-report side effect and not covered by Skill Outputs. | existing_core_capability |
| Skill / Agent surface | Structured Skill packages, standalone Agent packages, KB-bound Agent packages, memory policy, local runtime smoke, orchestration contracts, and P2.2 Skill Suite generation from methodology evidence. | implemented with suite governance boundaries |
| P2.2 Skill Suite governance | Existing knowledge packages can produce evidence windows, methodology maps, skill candidates, Planning / Functional / Atomic Skill hierarchy, routing rules, dependency graph, validation, diff, installability, governance report, and controlled Skill Pack export. | v4.2.0 industrial baseline |
| Test governance | Validation gate manifest, changed-file impact selector, dry-run/executable validation runner, pytest markers, and obsolete-test pruning register are present. | v4.1.1 baseline, reused as release process |
| Workspace / Workbench | Local workspace registries, storage reports, artifact registry, task schema, P1 Workbench contracts, fixtures, V2 action evidence, UI consumption proof, and P2.1 parser backend matrix evidence. | v4.1.0 Workbench sync |
| Privacy / providers | Local-first reports, no hidden upload, secret redaction, optional provider boundaries. | implemented with review boundaries |

Docling, PaddleOCR, and Unstructured are completed P2.1 optional runtime integrations, not bundled defaults and not static Workbench executable controls. P2.1 validates Docling on Markdown/TXT samples, PaddleOCR on PNG OCR, and Unstructured on `.md/.txt`; broader surfaces remain bounded in [P2.1 backend capability boundaries](audits/p2_1_parser_ocr_backends/backend_capability_boundaries.md). Anything2Skill, SkillX, and Anthropic Skills / skill-creator are absorbed in P2.2 only as L3/L4 contract and capability references; there is no runtime vendoring, provider/API integration, account binding, or P2.3 startup.

See [Current Truth](CURRENT_TRUTH.md), [AIGC Book Content Pipeline](AIGC_BOOK_CONTENT_PIPELINE.md), and [Parser Backend Strategy](03_core_capabilities/PARSER_BACKEND_STRATEGY.md).
