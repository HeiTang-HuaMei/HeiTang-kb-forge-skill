# Changelog

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
