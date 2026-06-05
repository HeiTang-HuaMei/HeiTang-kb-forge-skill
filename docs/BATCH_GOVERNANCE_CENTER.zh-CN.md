# Batch And Governance Center

v2.3 在本地展示层中预留 Batch & Governance Center。

UI 可以读取：

- `batch_job_manifest.json`
- `batch_item_status.jsonl`
- `package_version_graph.json`
- `governance_decisions.jsonl`
- `impacted_skills.json`
- `impacted_agents.json`

桌面 / Web UI 仍然只是展示层。核心批量与治理逻辑保留在 Python package 和 CLI 中。
