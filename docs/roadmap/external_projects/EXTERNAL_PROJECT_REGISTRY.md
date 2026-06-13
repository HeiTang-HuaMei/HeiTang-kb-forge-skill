# External Project Registry

This registry is the external GitHub project and internal capability anchor ledger. It tracks registry, roadmap, benchmark mapping, docs, tests, and explicit optional local parser/OCR runtime adapter boundaries.

It does not make external projects default product functionality or bundle external runtimes. Current provider calls and export adapters are recorded explicitly and remain subject to their UI, configuration, and runtime boundaries.

Source of truth: [external_project_registry.json](external_project_registry.json).

## Summary

- External projects: 27
- S projects: 8
- A projects: 15
- B projects: 4
- Projects with `current_repo_status=needs_verification`: 0
- Internal Capability Anchors: 8
- Optional local parser/OCR runtime adapters release-hardened for v4.1.0: Docling, PaddleOCR, Unstructured
- Planned adapters marked ready: false
- v4.0 started: false
- tag created: false
- release written: false

## Future Reference Queue

These projects are registered for product trend alignment only. They are not runtime integrations, do not add dependencies, do not run MCP/plugin execution, and do not change the current next safe action.

| Project | Role | Status | Implementation mode | Current version required |
| --- | --- | --- | --- | --- |
| andrej-karpathy-skills | Knowledge-to-Skill methodology reference for Campaign 3 Supplement 4.0B | reference_only | not_integrated | true |
| Presenton | Document/PPT generation reference | needs_verification | not_integrated | false |
| CodeGraph | Codebase knowledge graph / developer knowledge map reference | needs_verification | not_integrated | false |
| Understand Anything | Interactive knowledge graph / Workbench UI reference | needs_verification | not_integrated | false |
| NVlabs/LongLive | Long video generation infrastructure reference | needs_verification | not_integrated | false |
| claude-plugins-official | Plugin ecosystem / workflow integration reference | needs_verification | not_integrated | false |
| pi-mono | Agent runtime / minimal coding harness reference | needs_verification | not_integrated | false |

Boundary: no runtime dependency added, no npm install, no GPU/runtime integration, no MCP/plugin execution, no Presenton PPT runtime, no LongLive video generation, no CodeGraph / Understand Anything knowledge graph runtime, no Claude plugin runtime, and no pi-mono Agent runtime.

## S Projects

| Project | Status | Pre-v4 scope | Post-v4 target |
| --- | --- | --- | --- |
| LLM Wiki v2 | real_workflow_evidence | capability_fusion | P2.4 |
| WeKnora | real_workflow_evidence | capability_fusion | P2.5 |
| n8n | real_workflow_evidence | workflow_export | P2.2 / P3 |
| andrej-karpathy-skills | benchmark_mapped | registry_only | P2.9 |
| PaddleOCR | planned_adapter + optional_runtime_adapter | registry_only | P2.1 |
| MinerU | planned_adapter | registry_only | P2.6 |
| Docling | planned_adapter + optional_runtime_adapter | registry_only | P2.1 |
| Unstructured | planned_adapter + optional_runtime_adapter | registry_only | P2.1 |

## A Projects

| Project | Status | Pre-v4 scope | Post-v4 target |
| --- | --- | --- | --- |
| AnySearchSkill | real_workflow_evidence | provider_adapter | P2.3 |
| last30days-skill | benchmark_mapped | registry_only | P2.3 / P3 |
| skill-prompt-generator | mentioned_only | registry_only | P2.9 |
| MMSkills | mentioned_only | registry_only | P2.8 / P3 |
| Jellyfish | mentioned_only | registry_only | P2.8 / P3 |
| story-flicks | mentioned_only | registry_only | P2.8 / P3 |
| seedance2-skill | reference_schema_evidence | verified_video_skill_template_metadata | P2.8 / P3 |
| ai-marketing-skills | mentioned_only | registry_only | P2.7 |
| rtk | benchmark_mapped | registry_only | P3 |
| OpenDataLoader | planned_adapter | registry_only | P2.6 |
| Marker | planned_adapter | registry_only | P2.6 |
| Surya | planned_adapter | registry_only | P2.6 |
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
- Provider/network/API abilities require explicit user configuration and truthful live status.
- n8n workflow export is implemented; n8n runtime is not bundled or executed.
- WeKnora capability fusion is implemented; WeKnora runtime is not embedded.
- The original S/A contract pass did not call AnySearchSkill. Section 5 item 5.3 now has a controlled provider adapter and anonymous real-smoke evidence; UI/Core Bridge and proxy-path acceptance remain `needs_strengthening`.
- LLM Wiki-inspired Knowledge Lifecycle capability fusion is implemented; no vendor runtime is bundled.
- External project code is not copied.
