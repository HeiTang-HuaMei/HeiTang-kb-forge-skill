# v3.11 Golden Demo & Real Acceptance Smoke

v3.11 adds a deterministic local acceptance layer for the Golden Demo path. It does not add UI, SaaS, cloud storage, or a real LLM/runtime dependency. The goal is to prove that a built Core package can support a realistic local demo before v3.12 product hardening.

## Scope

- Golden Demo readiness
- real input sample coverage
- generated artifact openability
- generated package compatibility
- smoke test realism across v3.7, v3.8, v3.9, and v3.10 outputs when required
- Workbench contract visibility for reports and actions

## Outputs

- `golden_demo_manifest.json`
- `golden_demo_report.md`
- `real_acceptance_smoke_result.json`
- `real_acceptance_smoke_report.md`
- `sample_coverage_report.json`
- `sample_coverage_report.md`
- `artifact_openability_report.json`
- `artifact_openability_report.md`
- `generated_package_compatibility_report.json`
- `smoke_realism_report.json`
- `v311_acceptance_trace.json`

## CLI

```bash
heitang-kb-forge run-golden-demo-acceptance --package ./package --output ./acceptance
```

The command is local-only. `--allow-llm` and `--allow-network` are reserved flags and must remain false in v3.11.

## Config

```yaml
golden_demo_acceptance:
  enabled: true
  require_v37: true
  require_v38: true
  require_v39: true
  require_v310: true
  allow_llm: false
  allow_network: false
```

Default build behavior is unchanged. Reports are written only when this block is enabled or the CLI command is called directly.

## Acceptance Rules

Artifact openability parses local JSON/JSONL/Markdown/text/YAML outputs and checks local Office/PDF container signatures when those files exist. It does not upload generated artifacts anywhere.

Smoke realism checks whether required prior-version outputs exist. v3.11 can require v3.7 query planning, v3.8 retrieval quality, v3.9 storage/memory, and v3.10 local agent runtime outputs so the Golden Demo does not pass on a toy scaffold.

LLM remains an optional assistive layer only. Tests do not require real LLM, API, or network access.
