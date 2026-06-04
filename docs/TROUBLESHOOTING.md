# Troubleshooting

## Unsupported File Extension

Check that the source extension is one of the registered parsers. Unsupported numbered batch files are recorded as failed items.

## Quality Gate Failed

Inspect:

- `quality_gate_report.json`
- `quality_gate_summary.md`
- `package_acceptance_report.md`
- `package_validation_report.json`

Common reasons include zero chunks, empty chunks, not-ready validation status, high hallucination risk, or high-risk labels.

## Batch Item Failed

Inspect:

- `batch_manifest.json`
- `failed_items.jsonl`
- `retry_manifest.json`

Use the retry manifest to identify source files or groups that should be rerun manually.

## Source Refresh Needed

Run:

```powershell
heitang-kb-forge refresh-check --workspace .\workspace --output .\refresh
```

Refresh signals include missing packages, missing sources, changed source hashes, stale packages, readiness warnings, and quality risk.

## OCR Dependency Errors

Install OCR extras only when OCR input is needed:

```powershell
pip install -e ".[ocr]"
```

Default Markdown, TXT, text-based PDF, DOCX, CSV, TSV, and XLSX behavior does not require OCR extras.
