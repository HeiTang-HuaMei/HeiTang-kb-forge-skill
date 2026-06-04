# Production Hardening

v1.2.1 adds local production-readiness guardrails without changing the default offline package contract.

## Recommended Local Release Check

```powershell
python -m pytest
heitang-kb-forge build --input .\examples\input --output .\examples\output --quality-gate --run-manifest
```

## Recommended Batch Check

```powershell
heitang-kb-forge batch --input .\input --output .\output --continue-on-error --quality-gate
```

## Outputs To Review

Package-level:

- `quality_report.json`
- `package_validation_report.json`
- `quality_gate_report.json`
- `run_manifest.json`
- `stage_trace.jsonl`

Batch-level:

- `batch_manifest.json`
- `batch_run_summary.json`
- `failed_items.jsonl`
- `retry_manifest.json`

Workspace-level:

- `package_registry.json`
- `source_freshness_report.md`
- `refresh_plan.json`

## Non-Scope

This hardening layer does not add external orchestration, remote scheduling, permission systems, SaaS multi-tenancy, real business integration, or external publishing API calls.

## v1.3.0 Lifecycle Hardening

Lifecycle mode adds source registry, change detection, incremental update, missing source policy, update quality gate, and retry manifest artifacts. These reports make package updates auditable while preserving the default build and batch behavior.

Review these optional lifecycle files when enabled:

- `source_registry.json`
- `source_change_report.md`
- `incremental_update_report.md`
- `update_quality_gate_report.json`
- `retry_manifest.json`
