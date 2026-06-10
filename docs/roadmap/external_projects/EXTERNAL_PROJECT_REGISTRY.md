# External Project Registry

This registry is the pre-v4 total ledger for external GitHub projects and internal capability anchors. It is registry, roadmap, benchmark mapping, docs, and tests only.

It does not implement external project functionality, does not add dependencies, does not call provider APIs, does not bundle external runtimes, and does not start v4.0.

Source of truth: [external_project_registry.json](external_project_registry.json).

## Summary

- External projects: 27
- S projects: 7
- A projects: 16
- B projects: 4
- Projects with `current_repo_status=needs_verification`: 0
- Internal Capability Anchors: 8
- External features implemented by this pass: false
- Planned adapters marked ready: false
- v4.0 started: false
- tag created: false
- release written: false

## S Projects

| Project | Status | Pre-v4 scope | Post-v4 target |
| --- | --- | --- | --- |
| LLM Wiki v2 | mentioned_only | registry_only | P2.4 |
| WeKnora | mentioned_only | registry_only | P2.5 |
| n8n | mentioned_only | registry_only | P2.2 / P3 |
| andrej-karpathy-skills | benchmark_mapped | registry_only | P2.9 |
| PaddleOCR | planned_adapter | registry_only | P2.6 |
| MinerU | planned_adapter | registry_only | P2.6 |
| Docling | planned_adapter | registry_only | P2.6 |

## A Projects

| Project | Status | Pre-v4 scope | Post-v4 target |
| --- | --- | --- | --- |
| AnySearchSkill | mentioned_only | registry_only | P2.3 |
| last30days-skill | benchmark_mapped | registry_only | P2.3 / P3 |
| skill-prompt-generator | mentioned_only | registry_only | P2.9 |
| MMSkills | mentioned_only | registry_only | P2.8 / P3 |
| Jellyfish | mentioned_only | registry_only | P2.8 / P3 |
| story-flicks | mentioned_only | registry_only | P2.8 / P3 |
| seedance2-skill | mentioned_only | registry_only | P2.8 / P3 |
| ai-marketing-skills | mentioned_only | registry_only | P2.7 |
| rtk | benchmark_mapped | registry_only | P3 |
| OpenDataLoader | planned_adapter | registry_only | P2.6 |
| Marker | planned_adapter | registry_only | P2.6 |
| Surya | planned_adapter | registry_only | P2.6 |
| Unstructured | planned_adapter | registry_only | P2.6 |
| LlamaIndex | benchmark_mapped | registry_only | P2.5 |
| RAGAS | benchmark_mapped | registry_only | P2.5 |
| DeepEval | docs_only | registry_only | P2.5 |

## B Projects

| Project | Status | Pre-v4 scope | Post-v4 target |
| --- | --- | --- | --- |
| ai-money-maker-handbook | mentioned_only | registry_only | P2.7 |
| vibe-coding-cn | benchmark_mapped | registry_only | P3 |
| Ruflo | benchmark_mapped | registry_only | P3 |
| Growth-Loop | not_found | registry_only | P3 |

## Boundary

- Planned adapters remain not ready.
- Provider/network/API abilities require explicit post-v4 user configuration.
- n8n is not bundled.
- WeKnora is not embedded.
- AnySearchSkill API is not called.
- LLM Wiki memory engine is not implemented.
- External project code is not copied.
