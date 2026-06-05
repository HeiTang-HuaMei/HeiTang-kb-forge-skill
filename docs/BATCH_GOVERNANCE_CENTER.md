# Batch And Governance Center

v2.3 exposes a Batch & Governance Center direction in the local presentation layer.

The UI can read:

- `batch_job_manifest.json`
- `batch_item_status.jsonl`
- `package_version_graph.json`
- `governance_decisions.jsonl`
- `impacted_skills.json`
- `impacted_agents.json`

The desktop/web UI remains a presentation layer. Core batch and governance logic stays in the Python package and CLI.
