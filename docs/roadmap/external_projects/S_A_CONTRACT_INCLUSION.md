# S/A Contract Inclusion

This pass moves S/A external projects from roadmap-only registry into Core contract visibility, Workbench capability mapping, blocked reasons, planned/future adapter registries, provider boundaries, and docs/tests.

It is contract inclusion, not implementation.

Source outputs: [../../audits/s_a_contract_inclusion/](../../audits/s_a_contract_inclusion/)

## Summary

- S projects: 7
- A projects: 16
- Internal capability anchors: 8
- External project functionality implemented: false
- Planned adapters marked ready: false
- Provider/network/API abilities marked ready: false
- P1 gate changed: false
- v4.0 started: false
- tag created: false
- release written: false

## Boundaries

- S/A projects are not local-ready before v4.
- External project functionality remains post-v4.
- API, network, provider, and secret-dependent abilities require explicit user configuration.
- n8n is not bundled.
- WeKnora is not embedded.
- The original S/A inclusion snapshot did not call AnySearchSkill. Current Section 5 item 5.3 evidence is indexed separately under `artifacts/audits/section_5/anysearchskill_provider_adapter/`.
- LLM Wiki memory engine is not implemented.
- planned_adapter and future_adapter entries are not ready.

## Readonly CLI

```powershell
python -m heitang_kb_forge.cli external-capability-registry --output .\tmp_s_a_contract
python -m heitang_kb_forge.cli external-capability-inspect --project-id anysearchskill
python -m heitang_kb_forge.cli external-capability-matrix --output .\tmp_s_a_matrix
python -m heitang_kb_forge.cli planned-adapter-status --output .\tmp_adapter_status
```

These commands only write or inspect registry/report files. They do not execute external projects.
