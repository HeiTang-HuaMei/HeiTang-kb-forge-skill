# v3.9 External Absorption Map

`v39_external_absorption_map.json` records how v3.9 absorbs external benchmark patterns without copying code, prompts, or mandatory heavy dependencies.

Mandatory references include LiteDoc for local PDF-to-Markdown and no-upload privacy boundaries, PaddleOCR for OCR routing, MinerU for complex layout/table/formula parsing, Marker/Docling for parser backend strategy, and `rohitg00/agentmemory` for memory lifecycle inspiration.

The map documents, for each v3.9 capability:

- benchmark references
- absorb/inspire/reject/future decision
- what to absorb
- what not to copy
- local deterministic implementation path
- optional LLM assist path
- offline fallback
- tests and reports
- contract impact and risk level

No external code or prompts are copied. No cloud upload path is required or enabled. Tests do not require real LLM/API/network.
