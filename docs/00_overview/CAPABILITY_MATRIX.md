# Capability Matrix

Current Core package version: `4.0.0rc1`
Current release candidate: `v4.0.0-rc.1`

| Area | Current main branch truth | Status |
| --- | --- | --- |
| Local ingestion | Markdown, TXT, DOCX, text PDF, image/OCR routes, CSV/TSV/XLSX, HTML, EPUB, ZIP, and mixed sources are supported through local paths. | implemented with parser-specific boundaries |
| Parser backend strategy | Completed capability remains verified internal parser, bounded best-effort OCR, and local PDF token reduction. OpenDataLoader is an external backend candidate for end-to-end PDF -> Markdown/JSON/RAG-ready parsing; PaddleOCR is an OCR foundation candidate; MinerU is a document structure understanding and complex layout candidate; PaddleOCR + MinerU is a planned OCR + document understanding pipeline. | internal complete; external planned adapter only |
| Knowledge package | Standard package outputs include `manifest.json`, `chunks.jsonl`, `cards.jsonl`, `qa_pairs.jsonl`, `glossary.jsonl`, `quality_report.json`, and `ingest_report.md`. | implemented |
| Query and retrieval | Deterministic rewrite, planning, local index, local JSON vector query, hybrid retrieval, rerank, evidence selection, diagnostics, and accuracy reports are present. | implemented locally |
| Document generation | Grounded Markdown, DOCX, PDF, and PPTX generation are available through local commands and reports. | implemented |
| Skill and Agent packages | Skill-first package generation, Agent package surfaces, KB-bound Agent proof, and local mother/child runtime smoke are present. Full autonomous tool-calling Agent runtime is not implemented. | partial |
| Workspace and memory | Local workspace registry, lifecycle, update/rebuild reports, memory policy, retention, token budget, and no-cloud reports are present. Destructive cleanup is not default. | partial |
| Provider and LLM layer | Optional provider profile acceptance exists. Core tests do not require real LLM/API/network calls. Provider secrets must stay outside committed outputs. | optional only |
| Privacy and security | Local-first, no hidden upload, secret redaction, no platform-hosted user data, and threat-model evidence are documented and tested. | implemented with review boundaries |
| Scale | Synthetic scale checks exist. Real 1500 books/KBs/Agents are not production-proven. | needs review |
| UI | Core contracts, P1-RWF-V2 evidence, and UI consumption proof exist. The P1 final gate re-run, External Project Registry, and S/A Contract Inclusion are complete. | v4.0.0-rc.1 candidate; stable pending rc hardening |

See [Current Truth](CURRENT_TRUTH.md), [Parser Backend Strategy](../03_core_capabilities/PARSER_BACKEND_STRATEGY.md), [Final Product Architecture Truth](../FINAL_PRODUCT_ARCHITECTURE_TRUTH.md), and [P1 UI Core Parity](../10_roadmap/P1_UI_CORE_PARITY.md).
