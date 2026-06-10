# Parser Backend Strategy

Current Core package version: `4.1.1`
Current release line: `v4.1.1`
Latest stable release: `v4.1.0`

This document records parser backend strategy only. It does not make external runtimes default, download models, or execute external parser code unless a backend is explicitly selected and its local dependency is installed.

## Completed Core Parser Capability

HeiTang KB Forge current completed parser capability remains:

- verified internal parser coverage for local Markdown, TXT, DOCX, text PDF, tabular, HTML, EPUB, ZIP, image route, and mixed-source ingestion paths
- bounded best-effort OCR for local OCR routes
- local PDF token reduction and parser truth evidence

These are the default parser capabilities covered by the current Core tests and final proof. P2.1 additionally release-hardens optional real local adapters for Docling, PaddleOCR, and Unstructured, while keeping the default Core path unchanged unless the local dependency is installed and explicitly selected.

Optional real local runtime adapters now cover three S-grade parser/OCR projects:

- Docling for structured document conversion
- PaddleOCR for local OCR runtime
- Unstructured for Markdown/TXT document parsing through the `parser-unstructured` extra

## External Backend Candidates

| Candidate | Positioning | Current status |
| --- | --- | --- |
| OpenDataLoader | End-to-end PDF -> Markdown/JSON/RAG-ready parser candidate for future complete PDF content packaging. | external backend candidate; planned adapter |
| PaddleOCR | OCR foundational capability for text detection and recognition. | optional real local runtime adapter; broader OCR pipeline remains planned |
| MinerU | Document structure understanding and complex layout parsing candidate for reading order, sections, figures, formulas, and table-heavy pages. | external backend candidate; planned adapter |
| PaddleOCR + MinerU | OCR + document understanding pipeline candidate: PaddleOCR provides the OCR foundation, while MinerU handles structure and complex layout reasoning. | planned combined pipeline; not current stable surface |

## Governance Boundary

- Do not describe OpenDataLoader, MinerU, or the PaddleOCR + MinerU pipeline as current completed HeiTang KB Forge capability.
- Do not describe Docling, PaddleOCR, or Unstructured as default Core parsing, bundled runtimes, or UI-executable external projects; they remain opt-in local runtime adapters.
- Future adapters must pass local privacy, secret redaction, parser quality, token reduction, reliability, and acceptance gates before product truth changes.
- This strategy keeps the default Core parser implementation unchanged, but the optional adapters can invoke installed local runtimes when explicitly selected.
- Current release wording must say that HeiTang KB Forge preserves verified internal parser capability and builtin fallback, and also has P2.1 opt-in runtime integrations for Docling, PaddleOCR, and Unstructured with the documented stable surfaces.
