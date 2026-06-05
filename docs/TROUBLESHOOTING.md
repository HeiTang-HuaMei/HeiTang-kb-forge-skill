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

## Large PDF or OCR Run Is Slow

Use the combined progress and performance controls:

```powershell
heitang-kb-forge build --input .\input --output .\output --progress-jsonl --profile fast --ocr-mode first-pages --max-ocr-pages 10 --ocr-cache --resume
```

Inspect:

- `progress_events.jsonl`
- `pdf_preflight_report.json`
- `pdf_page_classification.jsonl`
- `ocr_failed_pages.jsonl`
- `ocr_resume_report.md`
- `large_file_performance_report.md`

If OCR still takes too long, reduce `--max-ocr-pages`, use `--ocr-mode selected-pages --ocr-pages 1,3-5`, lower `--ocr-scale`, or increase `--ocr-workers` cautiously.
# v1.7 Troubleshooting

If Evidence Gate refuses a query, inspect `context_pack.md`, `retrieval_trace.json`, and `evidence_gate_report.md`.

If mock LLM validation is enabled, inspect `llm_call_log.jsonl`. API keys are redacted from call logs.

# v1.8 Troubleshooting

If Skill validation is not release ready, inspect `skill_validation_result.json` and the rule files in the Skill Package.

If LLM-assisted generation falls back, inspect `llm_skill_generation_report.md`, `llm_agent_generation_report.md`, and `llm_call_log.jsonl`.

# v1.9 Troubleshooting

If workspace health is warning, inspect `reports/workspace_health_report.md` and missing registered paths. Provider registry issues should be checked in `registries/provider_registry.json`.

# v2.0 Stable Checks

If `stable-check` reports warnings, inspect `stable_check_report.md`. Missing future extensions such as master Skill learning or platform distribution should remain `not_enabled` in v2.0 and are not failures.

If `provider-health` warns about a non-mock provider while network access is disabled, use a mock provider for local validation.

# v2.1 Quality Troubleshooting

If quality scoring is warning, inspect `knowledge_quality_report.md`, `chunk_quality_scores.jsonl`, and `source_inventory_enhanced.json`.

LLM quality assist should remain optional and mock/fallback-safe. It should not be treated as human review.
# v2.3 Batch Governance Troubleshooting

- Missing `batch_job_manifest.json`: run `batch-run` or a batch config with v2.3 enabled outputs.
- Missing `batch_item_status.jsonl`: check whether numbered input files were found.
- Curated package includes rejected content: inspect `governance_decisions.jsonl` and decision values.
- Update impact is too broad: check workspace Skill and Agent registrations.
