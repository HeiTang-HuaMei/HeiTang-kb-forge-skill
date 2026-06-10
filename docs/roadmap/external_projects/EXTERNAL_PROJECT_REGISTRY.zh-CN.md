# 外部项目总账

这是外部 GitHub 项目和内部能力方向总账。本文件记录 registry、roadmap、benchmark mapping、docs、tests，以及显式的可选本地 parser/OCR runtime adapter 边界。

本文件不把外部项目变成默认产品功能，不调用 provider API，不打包外部 runtime，不修改 `v4.0.0`，也不启动 P2.2。

唯一数据源：[external_project_registry.json](external_project_registry.json)。

## 汇总

- 外部项目数：27
- S 级项目数：8
- A 级项目数：15
- B 级项目数：4
- `current_repo_status=needs_verification` 项目数：0
- Internal Capability Anchors 数：8
- 已完成 v4.1.0 release hardening 的可选本地 parser/OCR runtime adapters：Docling、PaddleOCR、Unstructured
- planned_adapter 标为 ready：false
- v4.0 started：false
- tag created：false
- release written：false

## S 级项目

| 项目 | 当前状态 | pre-v4 范围 | post-v4 目标 |
| --- | --- | --- | --- |
| LLM Wiki v2 | mentioned_only | registry_only | P2.4 |
| WeKnora | mentioned_only | registry_only | P2.5 |
| n8n | mentioned_only | registry_only | P2.2 / P3 |
| andrej-karpathy-skills | benchmark_mapped | registry_only | P2.9 |
| PaddleOCR | planned_adapter + optional_runtime_adapter | registry_only | P2.1 |
| MinerU | planned_adapter | registry_only | P2.6 |
| Docling | planned_adapter + optional_runtime_adapter | registry_only | P2.1 |
| Unstructured | planned_adapter + optional_runtime_adapter | registry_only | P2.1 |

## A 级项目

| 项目 | 当前状态 | pre-v4 范围 | post-v4 目标 |
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
| LlamaIndex | benchmark_mapped | registry_only | P2.5 |
| RAGAS | benchmark_mapped | registry_only | P2.5 |
| DeepEval | docs_only | registry_only | P2.5 |

## B 级项目

| 项目 | 当前状态 | pre-v4 范围 | post-v4 目标 |
| --- | --- | --- | --- |
| ai-money-maker-handbook | mentioned_only | registry_only | P2.7 |
| vibe-coding-cn | benchmark_mapped | registry_only | P3 |
| Ruflo | benchmark_mapped | registry_only | P3 |
| Growth-Loop | not_found | registry_only | P3 |

## Internal Capability Anchors

| 内部能力方向 | rating | 当前状态 | post-v4 目标 | 关联外部 benchmark |
| --- | --- | --- | --- | --- |
| Book-to-Skill | S | implemented | P2.6 | andrej-karpathy-skills, skill-prompt-generator |
| Package-to-Skill | S | implemented | P2.6 / P2.9 | andrej-karpathy-skills, skill-prompt-generator |
| Software-to-Manual-to-Skill | S | contract_only / planned_capability | P2.6 | andrej-karpathy-skills, skill-prompt-generator |
| AIGC Book Content Pipeline | S | docs_only | P2.7 / P2.8 | Jellyfish, story-flicks, ai-marketing-skills, ai-money-maker-handbook |
| Retrieval & Verification | S | implemented | P2.3 / P2.5 | AnySearchSkill, LlamaIndex, RAGAS, DeepEval |
| Memory Lifecycle | S | implemented baseline | P2.4 | LLM Wiki v2 |
| Auto Wiki / Knowledge Graph | S | future_capability | P2.5 | WeKnora |
| Workflow Automation / Export | S | future_adapter | P2.2 / P3 | n8n |

## 边界

- planned_adapter 仍然不是 ready。
- provider/network/API 能力必须等 post-v4 显式用户配置。
- n8n 不打包 runtime。
- WeKnora 不内嵌。
- AnySearchSkill API 不调用。
- LLM Wiki memory engine 不实现。
- 不复制任何外部项目代码。
