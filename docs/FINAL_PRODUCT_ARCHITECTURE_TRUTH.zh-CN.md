# 最终产品架构真值

本文档是当前 pre-v4.0 Core 状态的短版人工可读真值入口，用于集中说明哪些已实现、哪些部分实现、哪些是未来能力、哪些仍然阻断。机器可读证据保留在 `docs/audits/local_acceptance/large_bilingual_run/` 的历史大文件验收记录，以及 `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/` 的最新 Core P0 after-live-LLM 证明。

## 当前门禁

- 最新 Core P0 门禁：ready_for_v4_rc
- 最新 Core P0 证明：`docs/audits/local_acceptance/pre_v4_p0_after_live_llm/final_v4_rc_gate_report.json`
- 剩余 Core P0：最新 pre-v4 P0 证明中无剩余 Core P0。
- 阻断 P1：无
- CI：包含 after-live-LLM 证明的最新 Core commit 已 green。
- 本地 full pytest：最新 Core provider-profile 与 P0 gate 工作已通过。
- UI validation：Core 输出 Workbench contracts，但 v4.0 前 UI full-operation 仍然 blocked。
- 历史说明：`docs/audits/local_acceptance/large_bilingual_run/` 保留 earlier large-file run，当时 live LLM 仍被阻断。它不能作为最新 live-LLM P0 结论。

## 架构真值矩阵

| 层级 | 当前真值 | 状态 |
| --- | --- | --- |
| 输入与解析 | 大型 PDF、DOCX、Markdown/TXT、结构化文件、中英文混合路径已证明。扫描 PDF 全量 OCR 仍有限，不能过度声明。 | partial |
| 知识包 | 本地 package build、source inventory、metadata、quality gate 和 evidence files 已存在。所有文档类型的通用结构化解析未完全证明。 | partial |
| RAG 查询规划 | 确定性 query rewrite、expansion、decomposition、multi-query generation、answering/validation planning 已存在。 | implemented |
| RAG vector/hybrid/index | keyword/local index、本地 JSON vector query、hybrid keyword/vector retrieval、metadata filtering 和 stale index diagnostics 已实现并测试。Milvus、Pinecone、Qdrant、Chroma 与云端 vector DB adapter 仍是 future/disabled。 | implemented locally with external DB future boundary |
| 检索质量与知识准确性 | 本地 rerank、evidence selection、diagnostics、claim/freshness/contradiction/accuracy reports 已存在。冲突来源必须产生 warning/review，而不是 false pass。 | implemented with review boundary |
| 文档生成 | Grounded MD/DOCX/PDF/PPTX 生成与验证报告已存在。 | implemented |
| Agent 与 Skill | Legacy Skill package、standalone Agent、KB-bound Agent、本地确定性 runtime smoke、KB boundary、mother/child contracts、memory policy reports 已存在。P0-17 pass 已补入结构化 Book-to-Skill package、compact `SKILL.md`、on-demand loading、installability reports 与 KB/RAG/Agent compatibility proof。完整 autonomous tool-calling Agent Runtime 未实现。 | partial with structured Skill completion proof |
| 生命周期 | create/query 路径已证明。update/diff/rebuild/regenerate/refresh 仍是 partial。cleanup/archive 默认只给建议，不执行破坏性操作。 | partial |
| 存储 | `local_workspace` 是已实现默认。`local_db` 是 partial/store-index oriented。BYO cloud/database 是 future/disabled，不是已实现能力。 | partial |
| 安全与隐私 | local-first、默认 no hidden upload、API key redaction、no platform-hosted user data 已文档化并测试。动态 runtime network proof 和完整 UI security acceptance 仍需 review。 | partial |
| 规模 | 已有 synthetic 1500-scale checks。真实 1500 books、1500 KBs、1500 Agents 未生产级证明。 | needs_review |
| UI | Core 输出 Workbench contracts。完整用户可操作本地 Workbench 仍不声明，需要独立 UI full-operation acceptance gate。 | contracts present, full operation blocked |

## 仍不能声明

- v4.0 已发布或已打 tag
- 外部 vector database production readiness
- Milvus/Pinecone/Qdrant/Chroma 已实现
- 完整用户可操作 local Workbench
- 完整 autonomous tool-calling Agent Runtime
- 在 separate UI Full Operation Acceptance Gate 通过前声明完整 product-ready v4.0
- 没有真实结构化 Skill package、on-demand loading、installability reports、KB/RAG/Agent compatibility proof 就声明 Book-to-Skill completion
- 扫描 PDF 全量 OCR 已证明
- BYO cloud/database 已实现
- 默认启用破坏性 cleanup
- 默认 platform-hosted user data

## 证据文件

- `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/final_v4_rc_gate_report.json`
- `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/v4_rc_final_gate_report.json`
- `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/live_llm_acceptance_report.json`
- 历史 earlier run：`docs/audits/local_acceptance/large_bilingual_run/final_v4_rc_gate_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/product_architecture_completeness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/rag_vector_index_readiness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/ui_full_operation_readiness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/ui_full_operation_acceptance_after_core_p0.json`
- `docs/audits/local_acceptance/large_bilingual_run/multi_format_parser_truth_matrix.json`
- `docs/audits/local_acceptance/large_bilingual_run/agent_runtime_capability_truth_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/lifecycle_crud_update_readiness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/llm_provider_and_per_agent_api_readiness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/storage_backend_truth_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/security_threat_model_gap_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/scale_1500_readiness_report.json`
