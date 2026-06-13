# OpenDataLoader UI Impact Note

- Adapter: `opendataloader`
- UI status: `dependency_missing`
- Desktop bridge actions: check_opendataloader_backend, smoke_opendataloader_backend, run_opendataloader_convert
- Web execution enabled: `false`
- Web blocked reason: `web_local_cli_unsupported`
- Evidence path: `docs/audits/opendataloader_backend_strengthening/opendataloader_integration_decision_report.json`
- Truthfulness note: UI may expose desktop-local actions, but static web surfaces must show dependency_missing or structured_skipped until check/smoke evidence proves local availability.
