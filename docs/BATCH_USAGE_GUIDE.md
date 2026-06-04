# Batch Usage Guide

v1.2.1 keeps existing batch behavior and adds operational guardrails.

## Default Batch

```powershell
heitang-kb-forge batch --input .\input --output .\output --domain education --mode teaching
```

## Same-Sequence Merge

```powershell
heitang-kb-forge batch --input .\input --output .\output --merge-same-sequence
```

## Hardening Options

- `--continue-on-error / --no-continue-on-error`: continue after item failures or stop after the first failure.
- `--fail-fast`: stop after the first failed item or group.
- `--max-files`: process only the first N numbered files.
- `--max-chunks`: stop after processed successful items reach the chunk limit.
- `--quality-gate`: run package quality gates for successful item packages.
- `--quality-gate-strict`: fail an item or group when its quality gate fails.
- `--run-manifest`: write per-package run trace files.

## Root Batch Outputs

Every batch run writes the existing batch outputs plus hardening outputs:

- `batch_manifest.json`
- `batch_report.md`
- `batch_run_summary.json`
- `batch_run_report.md`
- `failed_items.jsonl`
- `retry_manifest.json`

## Failure Isolation

Single-item failures are recorded in the root batch outputs. In merge mode, one failed group does not block other groups unless `--fail-fast` or `--no-continue-on-error` is used.
