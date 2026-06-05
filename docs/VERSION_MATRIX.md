# Version Matrix

Current project version: 2.5.0-alpha.1

This matrix separates implemented checkpoints from planned capabilities. Tags may contain adjacent-version work because this project uses rapid implementation checkpoints.

| Version | Status | Main Capability | Checkpoint |
|---|---|---|---|
| v1.6 | Implemented | Real-world ingestion, multimodal assets, Contract v2 | historical |
| v1.7 | Implemented | Governance, retrieval, Evidence Gate | v1.7.0 |
| v1.8 | Implemented | Skill / Agent Package Generator | included in later checkpoint |
| v1.9 | Implemented | Workspace, registry, LLM audit | included in later checkpoint |
| v2.0 | Implemented | Stable foundation | included in later checkpoint |
| v2.1 | Implemented | Input hardening, quality, review, retrieval eval, evidence benchmark | included in later checkpoint |
| v2.2 | Implemented | Master Skill learning, derived Skill, Skill / Agent / Workspace hardening | v2.3.1-dev |
| v2.3 | Implemented | Batch, lineage, curation, update impact | v2.3.0-dev |
| v2.3.1-dev | Implemented | Post-v2.3 industrial hardening and implementation review | v2.3.1-dev |
| v2.4 | Implemented | Platform distribution and mock publishing | v2.4.0-dev |
| v2.4.1-dev | Implemented | Post-v2.4 platform publishing hardening | v2.4.1-dev |
| v2.5 | In progress | Release quality gate and regression certification | v2.5.0-dev / alpha metadata alignment in progress |
| v2.6 | Planned | Real LLM governance and Provider security | planned |
| v2.7 | Planned | Runtime compatibility smoke | planned |
| v2.8 | Planned | Domain Skill factory | planned |
| v2.9 | Planned | Feishu, personal KB, mobile / installer / iOS | planned |
| v3.x | Planned | SaaS, permissions, team collaboration | planned |

## Notes

- v2.4 platform export is an offline package and mock publishing layer, not a real platform runtime.
- XHS support is a mock/local Skill package workflow, not an official Xiaohongshu upload API.
- MCP support is a stub package, not a real MCP server.
- v2.5 release quality gate is local release certification, not external platform certification.
- Real LLM live smoke is planned for v2.6.
- Runtime compatibility smoke is planned for v2.7.
- Feishu, mobile, installer, and iOS work is planned for v2.9.
