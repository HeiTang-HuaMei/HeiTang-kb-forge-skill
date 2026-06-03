# Changelog

## v1.0.0

- Added text-based PDF table extraction with optional `pdfplumber`.
- Added best-effort scanned PDF and image OCR table extraction.
- Added optional `--validate-package`.
- Added `package_validation_report.json`.
- Added `package_readiness_report.md`.
- Added hallucination risk fields.
- Added optional `--downstream-export`.
- Added `langchain_documents.jsonl`.
- Added `llamaindex_documents.jsonl`.
- Added `generic_rag_package.json`.
- Added `openai_files_manifest.json`.
- Added `book_marketing_agent`, `publisher_sales_agent`, and `enterprise_kb_agent`.
- Added optional live provider validation report structure.
- Preserved default offline 7-file output.
- Preserved build / batch / run / pipeline default behavior.

## v0.9.0

- Added Runtime Connector Pack.
- Added OpenAI-compatible LLM provider readiness skeleton.
- Added fake and OpenAI-compatible embedding provider interfaces.
- Added `embeddings.jsonl`.
- Added `embedding_manifest.json`.
- Added local JSON vector export.
- Added `vector_store_records.jsonl`.
- Added `vector_store_manifest.json`.
- Enhanced Agent Template `tools.yaml` schema.
- Added config and pipeline support for embedding and vector stages.
- Preserved default offline output.

## v0.8.3

- Added `pipeline --config`.
- Added `pipeline_report.md`.
- Added `pipeline_manifest.json`.
- Added stage status reporting.
- Preserved `run --config`.
- Preserved build / batch behavior.

## v0.8.2

- Added `run --config`.
- Added YAML / YML config-driven execution.
- Added config mapping for build / batch / merge / LLM / RAG / Agent / Demo.
- Added `examples/configs`.

## v0.8.1

- Added portfolio demo packages.
- Added product manager agent demo.
- Added shopping guide agent demo.
- Added education tutor agent demo.
- Added `output_sample` demo outputs.

## v0.8.0

- Added `--demo-report`.
- Added `demo_report.md`.
- Added `demo_manifest.json`.
- Added `eval_summary.json`.
- Added pass / warning / fail demo readiness status.

## v0.7.0

- Added opt-in `--agent-template`.
- Added `--agent-type`.
- Added `--agent-name`.
- Added `--agent-language`.
- Added `agent_profile.yaml`.
- Added `system_prompt.md`.
- Added `retrieval_config.yaml`.
- Added `tools.yaml`.
- Added `eval_cases.jsonl`.
- Added minimal agent type templates.
- Preserved default offline output.
- No real Agent creation or deployment.

## v0.6.0

- Added opt-in `--rag-export`.
- Added provider-neutral RAG export files.
- Added `embedding_input.jsonl`.
- Added `retrieval_metadata.jsonl`.
- Added `citation_map.json`.
- Added `rag_manifest.json`.
- Added `--rag-profile basic`.
- Added `--rag-include-llm`.
- Preserved default offline output.
- No embedding API calls.
- No vector database writes.

## v0.5.0

- Added opt-in `--llm` structured extraction.
- Added fake LLM provider.
- Added LLM cache.
- Added LLM output files.
- Added LLM Summary in `ingest_report.md`.
- Added fallback and strict behavior.
- Preserved default offline 7-file output.
- Preserved offline cards / QA / glossary files.
- Added API key leakage tests.
- Tests passed: 65 passed.

## v0.4.3

- Added DOCX embedded table extraction.
- Preserved DOCX paragraph extraction.
- Converted DOCX table rows into readable text.
- No new dependencies.
- No PDF table extraction.
- Preserved build / batch / merge behavior.
- Tests passed: 53 passed.

## v0.4.2

- Added CSV parser.
- Added TSV parser.
- Added XLSX parser.
- Added `openpyxl` dependency.
- Added structured table row-to-text conversion.
- Added multi-sheet XLSX support.
- Added empty row filtering.
- Added empty and duplicate header handling.
- Preserved build / batch / merge CLI behavior.
- Preserved standard 7-file output.
- Tests passed: 45 passed.

## v0.4.1

- Added scanned PDF OCR fallback.
- Kept text-based PDF extraction as first priority.
- Added OCR fallback for empty or too-short PDF text.
- Added `pypdfium2` to optional `[ocr]` dependencies.
- Added page markers for OCR text.
- Preserved build / batch / merge CLI behavior.
- Preserved standard output filenames.
- Tests passed: 33 passed.

## v0.4.0

- Added optional image OCR parser.
- Added support for `.png`, `.jpg`, and `.jpeg`.
- Added optional OCR dependency group.
- Added lazy OCR dependency loading.
- Added clear error when OCR dependencies are missing.
- Preserved Markdown / TXT / text-based PDF / text-based DOCX behavior.
- Preserved build / batch / merge CLI behavior.
- Tests passed: 25 passed.

## v0.3.0

- Enhanced `cards.jsonl` quality.
- Added empty card filtering.
- Added card deduplication.
- Added `card_type`, `tags`, and `citation`.
- Enhanced `qa_pairs.jsonl` quality.
- Added empty QA filtering.
- Added QA deduplication.
- Added `qa_type` and `citation`.
- Enhanced `glossary.jsonl` extraction.
- Added English and Chinese term candidates.
- Added glossary `source_path`, `chunk_id`, and `citation`.
- Preserved output filenames.
- Preserved build / batch / merge behavior.
- Tests passed: 18 passed.

## v0.2.1

- Added `--merge-same-sequence` for batch.
- Added same-sequence multi-file merge.
- Added group-level output directories like `output/001/`.
- Added `merge_same_sequence` and `total_groups` in `batch_manifest.json`.
- Added `source_paths` and `source_count` for merge items.
- Added `Group Source Files` section in `batch_report.md`.
- Preserved default batch behavior.
- Preserved `build` behavior.
- Tests passed: 14 passed.

## v0.2.0

- Added `batch` command.
- Added numbered file batch processing.
- Added independent package output per source file.
- Added `batch_manifest.json`.
- Added `batch_report.md`.
- Added per-file failure isolation.
- Preserved existing `build` behavior.
- Tests passed: 12 passed.
