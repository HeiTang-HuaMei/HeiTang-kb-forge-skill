# Parser Backend Strategy

Current Core version: `3.12.0-alpha.1`

This document records parser backend strategy only. It does not add parser code, dependencies, model downloads, or external parser execution.

## Completed Core Parser Capability

HeiTang KB Forge current completed parser capability remains:

- verified internal parser coverage for local Markdown, TXT, DOCX, text PDF, tabular, HTML, EPUB, ZIP, image route, and mixed-source ingestion paths
- bounded best-effort OCR for local OCR routes
- local PDF token reduction and parser truth evidence

These are the completed parser capabilities covered by the current Core tests and final proof. External parser backends remain separate candidates until an adapter and acceptance proof change the product truth.

## External Backend Candidates

| Candidate | Positioning | Current status |
| --- | --- | --- |
| OpenDataLoader | End-to-end PDF -> Markdown/JSON/RAG-ready parser candidate for future complete PDF content packaging. | external backend candidate; planned adapter |
| PaddleOCR | OCR foundational capability candidate for text detection and recognition. | external backend candidate; planned adapter |
| MinerU | Document structure understanding and complex layout parsing candidate for reading order, sections, figures, formulas, and table-heavy pages. | external backend candidate; planned adapter |
| PaddleOCR + MinerU | OCR + document understanding pipeline candidate: PaddleOCR provides the OCR foundation, while MinerU handles structure and complex layout reasoning. | external backend candidate; planned adapter |

## Governance Boundary

- Do not describe OpenDataLoader, PaddleOCR, MinerU, or the PaddleOCR + MinerU pipeline as current completed HeiTang KB Forge capability.
- Future adapters must pass local privacy, secret redaction, parser quality, token reduction, reliability, and acceptance gates before product truth changes.
- This strategy adds no dependency, no model download, no runtime invocation, and no Core parser implementation change.
- Current release wording must continue to say that HeiTang KB Forge has verified internal parser capability, bounded best-effort OCR, and PDF token reduction as completed Core capability.
