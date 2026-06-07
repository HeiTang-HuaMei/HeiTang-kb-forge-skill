# v3.6 External Project Benchmark

This benchmark absorbs architecture patterns only. It does not copy external code, prompts, datasets, or skill text. Tests do not require network.

- Benchmark version: 3.6.0-alpha.1
- Project count: 20
- Source method: public_repository_metadata_and_architecture_review_no_external_code_copied

## Local PDF Parsing and Token Reduction Benchmark

- LiteDoc: local browser-side PDF to Markdown, privacy-first, token-cost reduction, no server upload.
- PaddleOCR: OCR recognition for scanned PDF / image text extraction.
- MinerU: complex document parsing to Markdown/JSON with layout/table/formula orientation.
- Marker / Docling: optional complex document parser backend strategy comparisons.

## Projects

- LiteDoc: https://litedoc.xyz -> inspire (v3.9, parser_hardening_track)
- agentmemory: https://github.com/rohitg00/agentmemory -> inspire (v3.9, v3.10)
- andrej-karpathy-skills: https://github.com/multica-ai/andrej-karpathy-skills -> needs_manual_review (v3.12)
- last30days-skill: https://github.com/mvanhorn/last30days-skill -> needs_manual_review (v3.12)
- rtk: https://github.com/rtk-ai/rtk -> inspire (v3.9, v3.10)
- LangChain: https://github.com/langchain-ai/langchain -> inspire (v3.7, v3.8)
- LlamaIndex: https://github.com/run-llama/llama_index -> inspire (v3.7, v3.8)
- Haystack: https://github.com/deepset-ai/haystack -> inspire (v3.8)
- GraphRAG: https://github.com/microsoft/graphrag -> future (v3.8, v4.0)
- PaddleOCR: https://github.com/PaddlePaddle/PaddleOCR -> future (parser_hardening_track, v3.9)
- MinerU: https://github.com/opendatalab/MinerU -> future (parser_hardening_track, v3.9)
- Marker: https://github.com/datalab-to/marker -> future (parser_hardening_track, v3.9)
- Docling: https://github.com/docling-project/docling -> inspire (parser_hardening_track, v3.9)
- TruLens: https://github.com/truera/trulens -> inspire (v3.8, v3.11)
- LangGraph: https://github.com/langchain-ai/langgraph -> future (v3.10)
- RAGAS: https://github.com/explodinggradients/ragas -> inspire (v3.8)
- FActScore: https://github.com/shmsw25/FActScore -> future (v3.8)
- FEVER: https://github.com/awslabs/fever -> future (v3.8, v4.3)
- AutoGen: https://github.com/microsoft/autogen -> future (v3.10, v4.0)
- Continue: https://github.com/continuedev/continue -> inspire (v4.0)

See `external_project_benchmark_report.json` for full fields.
