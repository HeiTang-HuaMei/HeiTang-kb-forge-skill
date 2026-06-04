# Knowledge Lifecycle Guide

HeiTang KB Forge v1.3.0 adds a lifecycle layer for source tracking, change detection, incremental update reporting, update quality gates, and retry planning.

## Scope

The lifecycle layer keeps the existing package output contract intact. It adds optional audit files when enabled and does not replace `build`, `batch`, `run --config`, or `pipeline --config`.

## CLI

```powershell
heitang-kb-forge lifecycle-check --input .\sources --package .\output --output .\lifecycle_check
```

```powershell
heitang-kb-forge build --input .\sources --output .\output --lifecycle --update-mode incremental --missing-source-policy mark_stale
```

## Config

```yaml
lifecycle:
  enabled: true
  update_mode: incremental
  previous_package: ./old_output
  missing_source_policy: mark_stale
  quality_gate: true
```

## Outputs

Lifecycle mode can generate:

- source_registry.json
- source_change_report.md
- changed_sources.jsonl
- missing_sources.jsonl
- new_sources.jsonl
- incremental_update_report.md
- reused_chunks.jsonl
- rebuilt_chunks.jsonl
- removed_chunks.jsonl
- stale_chunks.jsonl
- removed_source_impact_report.md
- update_quality_gate_report.json
- quality_regression_report.md
- failed_sources.jsonl
- retry_manifest.json
- retry_report.md

## Boundaries

- No external LLM calls are required.
- No vector database writes are performed.
- Incremental reporting does not change the standard package file names.
- Missing sources can be marked stale for audit without deleting the current package.
