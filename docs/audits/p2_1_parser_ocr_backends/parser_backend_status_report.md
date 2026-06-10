# Parser Backend Status Report

This report is derived from `parser_backend_matrix.json` and the committed P2.1 live acceptance evidence.

## builtin

- Dependency mode: `default`
- Dependency available in live acceptance: `true`
- Runtime invoked in live acceptance: `true`
- Sample input type: Markdown/TXT local source
- Validated stable surface: .md, .txt
- Status: `builtin_passed`
- Evidence path: `tests/test_v28_parser_backends.py::test_parse_with_backend_builtin_writes_normalized_outputs`
- Fallback behavior: Preserved default parser path; used when optional backend is missing or not selected.

## docling

- Dependency mode: `optional_extra`
- Dependency available in live acceptance: `true`
- Runtime invoked in live acceptance: `true`
- Sample input type: Markdown/TXT document source in live acceptance replay
- Validated stable surface: .md, .txt
- Status: `real_runtime_integrated`
- Evidence path: `docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json`
- Fallback behavior: If parser-docling is missing or runtime fails, the report marks the backend unavailable/failed and preserves builtin fallback guidance.

## paddleocr

- Dependency mode: `optional_extra`
- Dependency available in live acceptance: `true`
- Runtime invoked in live acceptance: `true`
- Sample input type: PNG OCR image in live acceptance replay
- Validated stable surface: .png
- Status: `real_runtime_integrated`
- Evidence path: `docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json`
- Fallback behavior: If parser-paddleocr or local OCR model/runtime is missing, the report marks the backend unavailable/failed and preserves builtin fallback guidance.

## unstructured

- Dependency mode: `optional_extra`
- Dependency available in live acceptance: `true`
- Runtime invoked in live acceptance: `true`
- Sample input type: Markdown/TXT document source in live acceptance replay
- Validated stable surface: .md, .txt
- Status: `real_runtime_integrated`
- Evidence path: `docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json`
- Fallback behavior: If parser-unstructured is missing or runtime fails, the report marks the backend unavailable/failed and preserves builtin fallback guidance.
