# Golden Demo Guide

Golden Demo acceptance is the v3.11 local real-workflow smoke. It is not a v4.0 release claim by itself.

## Prepare a Package

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_package
```

## Run Golden Demo Acceptance

```powershell
python -m heitang_kb_forge.cli run-golden-demo-acceptance --package .\tmp_package --output .\tmp_golden --no-require-v37 --no-require-v38 --no-require-v39 --no-require-v310
```

For final release evidence, run without `--no-require-*` once v3.7-v3.10 artifacts are present.

## Expected Reports

- `golden_demo_manifest.json`
- `real_acceptance_smoke_result.json`
- `real_acceptance_smoke_report.md`
- `sample_coverage_report.json`
- `artifact_openability_report.json`
- `generated_package_compatibility_report.json`
- `smoke_realism_report.json`
- `v311_acceptance_trace.json`

## Acceptance Standard

Golden Demo cannot be considered verified if artifacts are missing, empty, placeholder-only, or not openable. The final pre-v4 audit must mark this as P0 if the promised demo path cannot be proven.
