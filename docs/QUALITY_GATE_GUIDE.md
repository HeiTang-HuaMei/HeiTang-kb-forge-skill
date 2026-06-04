# Quality Gate Guide

v1.2.1 adds an opt-in package quality gate for release checks.

## Commands

Run the gate and keep the build successful:

```powershell
heitang-kb-forge build --input .\input --output .\output --quality-gate
```

Fail the current build when the gate status is `fail`:

```powershell
heitang-kb-forge build --input .\input --output .\output --quality-gate-strict
```

## Outputs

When enabled, the package includes:

- `quality_gate_report.json`
- `quality_gate_summary.md`
- `package_acceptance_report.md`
- `package_validation_report.json`
- `package_readiness_report.md`

## Gate Signals

The gate checks existing package assets and validation outputs:

- zero chunks
- empty chunks
- package readiness
- hallucination risk
- optional LLM quality report
- optional risk labels
- citation and source path coverage warnings

## Boundary

The quality gate does not call LLMs, embedding APIs, vector databases, or external services.
