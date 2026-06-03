# Changelog

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
