# 外部项目总账

这是外部 GitHub 项目和内部能力方向总账。本文件记录 registry、roadmap、benchmark mapping、docs、tests，以及显式的可选本地 parser/OCR runtime adapter 边界。

本文件不把外部项目变成默认产品功能，也不打包外部 runtime。当前 provider 调用与 export adapter 必须显式记录，并继续遵守 UI、配置和 runtime 边界。

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

## Future Reference Queue / 未来参考队列

以下项目只登记为产品趋势对齐参考，不是 runtime 接入，不新增依赖，不执行 MCP/plugin，不改变当前 next safe action。

| 项目 | 作用 | 状态 | 接入模式 | 当前版本必须核查 |
| --- | --- | --- | --- | --- |
| andrej-karpathy-skills | Campaign 3 Supplement 4.0B 的 Knowledge-to-Skill 方法论参考 | reference_only | not_integrated | true |
| Presenton | Document/PPT generation 参考 | needs_verification | not_integrated | false |
| CodeGraph | Codebase knowledge graph / developer knowledge map 参考 | needs_verification | not_integrated | false |
| Understand Anything | Interactive knowledge graph / Workbench UI 参考 | needs_verification | not_integrated | false |
| NVlabs/LongLive | 未来长视频生成基础设施参考 | needs_verification | not_integrated | false |
| claude-plugins-official | 未来 plugin ecosystem / workflow integration 参考 | needs_verification | not_integrated | false |
| pi-mono | 未来 Agent runtime / minimal coding harness 参考 | needs_verification | not_integrated | false |

边界：不新增 runtime dependency，不执行 npm install，不接入 GPU/runtime，不执行 MCP/plugin，不把 Presenton 写成 PPT runtime，不把 LongLive 写成视频生成，不把 CodeGraph / Understand Anything 写成知识图谱 runtime，不接入 Claude plugin runtime，不接入 pi-mono Agent runtime。

## S 级项目

| 项目 | 当前状态 | pre-v4 范围 | post-v4 目标 |
| --- | --- | --- | --- |
| LLM Wiki v2 | real_workflow_evidence | capability_fusion | P2.4 |
| WeKnora | real_workflow_evidence | capability_fusion | P2.5 |
| n8n | real_workflow_evidence | workflow_export | P2.2 / P3 |
| andrej-karpathy-skills | benchmark_mapped | registry_only | P2.9 |
| PaddleOCR | planned_adapter + optional_runtime_adapter | registry_only | P2.1 |
| MinerU | planned_adapter | registry_only | P2.6 |
| Docling | planned_adapter + optional_runtime_adapter | registry_only | P2.1 |
| Unstructured | planned_adapter + optional_runtime_adapter | registry_only | P2.1 |

## A 级项目

| 项目 | 当前状态 | pre-v4 范围 | post-v4 目标 |
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
| Auto Wiki / Knowledge Graph | S | implemented baseline | P2.5 | WeKnora |
| Workflow Automation / Export | S | implemented export baseline | P2.2 / P3 | n8n |

## 边界

- planned_adapter 仍然不是 ready。
- provider/network/API 能力必须显式用户配置并展示真实 live 状态。
- n8n workflow export 已实现；不打包或执行 n8n runtime。
- WeKnora capability fusion 已实现；不内嵌 WeKnora runtime。
- 原始 S/A 契约阶段未调用 AnySearchSkill；Section 5 item 5.3 已新增受控 provider adapter 与匿名真实 smoke 证据，但 UI/Core Bridge 与真实代理路径验收仍为 `needs_strengthening`。
- LLM Wiki 启发的 Knowledge Lifecycle capability fusion 已实现；不打包 vendor runtime。
- 不复制任何外部项目代码。
