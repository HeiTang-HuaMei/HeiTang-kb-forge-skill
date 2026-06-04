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

Run doctor for environment diagnostics:

```powershell
python -m heitang_kb_forge.cli doctor --output .\doctor_out
```

## Tesseract Not In PATH

If doctor reports `tesseract is not installed or not in PATH`, install Tesseract OCR for Windows and add its install directory to PATH.

Verify:

```powershell
tesseract --version
tesseract --list-langs
```

## chi_sim Missing

If `tesseract --list-langs` does not show `chi_sim`, Simplified Chinese OCR will be limited. Install `chi_sim.traineddata` into the Tesseract `tessdata` directory.

## PDF Table Optional Dependency

If `pdfplumber` is missing, install:

```powershell
python -m pip install -e ".[pdf-table]"
```

PDF table extraction is optional and does not affect the base Skill flow.
