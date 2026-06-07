# v3.12 Product Hardening & Local Release Readiness

v3.12 closes the local product hardening path before v4 planning. It is not a thin report wrapper: it runs deterministic local gates across diagnostics, commands, package outputs, workspace structure, Golden Demo evidence, privacy boundaries, contract drift, installer readiness, and v4 RC readiness.

## Scope

- doctor / diagnostics
- command audit
- package audit
- workspace audit
- Golden Demo verification
- stable user-facing error taxonomy
- troubleshooting report
- optional dependency diagnostics
- no-secret / no-temp check
- local privacy boundary report
- contract drift check
- installer readiness assessment
- local release readiness report
- v4 RC gate report
- `v312_external_absorption_map.json`

## CLI

```bash
heitang-kb-forge product-hardening --workspace . --package ./package --output ./hardening
```

`--allow-llm` and `--allow-network` are reserved and must remain false in v3.12. Tests do not require real LLM, API, or network access.

## Config

```yaml
product_hardening:
  enabled: true
  require_v37: true
  require_v38: true
  require_v39: true
  require_v310: true
  require_v311: true
  allow_llm: false
  allow_network: false
```

Default build behavior is unchanged. The hardening gate runs only when enabled.

## Outputs

- `product_hardening_manifest.json`
- `doctor_diagnostics_report.json`
- `command_audit_report.json`
- `package_audit_report.json`
- `workspace_audit_report.json`
- `golden_demo_verification_report.json`
- `stable_error_taxonomy.json`
- `troubleshooting_report.json`
- `optional_dependency_diagnostics.json`
- `no_secret_no_temp_report.json`
- `local_privacy_boundary_report.json`
- `contract_drift_report.json`
- `installer_readiness_report.json`
- `local_release_readiness_result.json`
- `v4_rc_gate_report.json`
- `v312_external_absorption_map.json`

## Boundaries

v3.12 does not implement new RAG features, Agent Runtime, storage backends, SaaS, multi-user behavior, cloud sync, or UI. It verifies the local Core release boundary so v4.0 planning can proceed from explicit evidence.
