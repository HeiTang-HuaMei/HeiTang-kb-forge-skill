# Unstructured UI Impact Note

- Adapter: `unstructured`
- UI status: `dependency_missing`
- Desktop bridge actions: fallback_parser_contract, check_unstructured_backend, smoke_unstructured_backend
- Web execution enabled: `false`
- Web blocked reason: `web_local_cli_unsupported`
- Evidence path: `docs/audits/unstructured_fallback_strengthening/unstructured_integration_decision_report.json`
- Truthfulness note: Static web surfaces may show Core evidence snapshots, but only the desktop bridge can run local Unstructured checks or smokes. Unstructured remains limited to the .md/.txt stable surface.
