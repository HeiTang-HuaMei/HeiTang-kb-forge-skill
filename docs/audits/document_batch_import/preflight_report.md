# Document Preflight Report

- Status: `warning`
- Input: `docs/audits/document_batch_import/sample_input`
- Total files: `4`
- Ready: `2`
- Unsupported: `1`
- Duplicates: `1`
- Failed: `0`

| File | Type | OCR | Tables | Recommendation | Status |
| --- | --- | --- | --- | --- | --- |
| 001_text.md | text_document | false | false | builtin | ready |
| 002_scan.pdf | pdf | true | false | paddleocr | ready |
| 003_copy.md | text_document | false | false | builtin | duplicate |
| 004_unsupported.bin | unsupported | false | false | None | unsupported |
