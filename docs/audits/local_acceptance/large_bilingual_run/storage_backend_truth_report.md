# Storage Backend Truth Report

- Status: needs_review
- Tests require real LLM/API/network: false

`local_workspace` is the default implemented storage backend. Package, skill, agent, index, and generated document artifacts are local files. Memory storage is contract/report-based.

`local_db` is partial/store-index oriented. BYO cloud is future/disabled and must not be claimed implemented.
