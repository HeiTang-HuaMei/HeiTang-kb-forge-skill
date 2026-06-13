# Capability Matrix

Current Core package version: `4.2.0`
Current stable release: `v4.2.0`
Previous stable release: `v4.1.1`

| Area | Current main branch truth | Status |
| --- | --- | --- |
| Local ingestion | Markdown, TXT, DOCX, text PDF, image/OCR routes, CSV/TSV/XLSX, HTML, EPUB, ZIP, and mixed sources are supported through local paths. | implemented with parser-specific boundaries |
| Parser/OCR backend runtime | Builtin parser remains the default fallback. Docling, PaddleOCR, and Unstructured are real opt-in local runtime adapters with registry, matrix, inspect, smoke, replay, failure-mode, and Workbench-visible evidence. Unstructured stable surface is `.md/.txt`; Docling live evidence is Markdown/TXT; PaddleOCR live evidence is PNG OCR. Broader adapter-declared surfaces require future hardening before stable claims. | implemented; optional dependency gated |
| External parser backend candidates | OpenDataLoader for PDF -> Markdown/JSON/RAG-ready packaging, MinerU, and PaddleOCR + MinerU as an OCR + document understanding pipeline remain external backend candidate / planned adapter only. The current default parser truth remains verified internal parser, bounded best-effort OCR, and PDF token reduction. | planned adapter; not default |
| Knowledge package | Standard package outputs include `manifest.json`, `chunks.jsonl`, `cards.jsonl`, `qa_pairs.jsonl`, `glossary.jsonl`, `quality_report.json`, and `ingest_report.md`. | implemented |
| Product output surfaces | `knowledge_package`, `document_outputs`, `skill_outputs`, and `agent_creation_package` are distinct product output surfaces. | registered product boundary |
| Query and retrieval | Deterministic rewrite, planning, local index, local JSON vector query, hybrid retrieval, rerank, evidence selection, diagnostics, and accuracy reports are present. | implemented locally |
| Document Outputs | Grounded Markdown, DOCX / Word, PDF, and PPTX / PowerPoint generation is available through `generate-documents`. This is a first-class product output capability, not an audit-report side effect and not covered by Skill Outputs. | existing_core_capability |
| Skill and Agent packages | Skill-first package generation, Agent package surfaces, KB-bound Agent proof, local mother/child runtime smoke, and P2.2 Skill Suite generation from methodology evidence are present. Full autonomous tool-calling Agent runtime is not implemented. | implemented with suite governance boundaries |
| P2.2 Skill Suite governance | Existing knowledge packages can produce evidence windows, methodology maps, skill candidates, Planning / Functional / Atomic Skill hierarchy, routing rules, dependency graph, validation, diff, installability, governance report, and controlled Skill Pack export. | v4.2.0 industrial baseline |
| Workspace and memory | Local workspace registry, lifecycle, update/rebuild reports, memory policy, retention, token budget, and no-cloud reports are present. Destructive cleanup is not default. | partial |
| Provider and LLM layer | Optional provider profile acceptance exists. Core tests do not require real LLM/API/network calls. Provider secrets must stay outside committed outputs. | optional only |
| Privacy and security | Local-first, no hidden upload, secret redaction, no platform-hosted user data, and threat-model evidence are documented and tested. | implemented with review boundaries |
| Scale | Synthetic scale checks exist. Real 1500 books/KBs/Agents are not production-proven. | needs review |
| Test governance | Validation gate manifest, changed-file impact selector, dry-run/executable validation runner, pytest markers, and obsolete-test pruning register are present. | v4.1.1 baseline, reused as release process |
| UI | Core contracts, P1-RWF-V2 evidence, UI consumption proof, and P2.1 parser backend matrix evidence exist. Static Workbench surfaces may show status/evidence/limitations, but must not imply local heavy runtime execution. | v4.1.0 Workbench sync |

See [Current Truth](CURRENT_TRUTH.md), [Parser Backend Strategy](../03_core_capabilities/PARSER_BACKEND_STRATEGY.md), [Final Product Architecture Truth](../FINAL_PRODUCT_ARCHITECTURE_TRUTH.md), and [P1 UI Core Parity](../10_roadmap/P1_UI_CORE_PARITY.md).
