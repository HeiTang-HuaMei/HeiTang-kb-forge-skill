# Multi-Format Parser Truth Matrix

- Status: needs_review
- Tests require real LLM/API/network: false

Large PDF, DOCX, Markdown/TXT, JSON/JSONL/YAML, Chinese paths, and English paths are proven in the large bilingual run.

Full scanned PDF OCR is not proven. The scanned PDF had 120 OCR candidate pages, while the build intentionally capped OCR at 8 pages. Do not claim universal full-OCR readiness.
