# v3.6 架构差距审计

本审计只记录能力差距、风险和未来版本映射，不实现 v3.7 功能，不修改 UI，也不复制外部项目代码或提示词。

- 审计版本: 3.6.0-alpha.1
- Core commit: cdfbb0e
- UI commit: 24dfa2b
- 风险统计: P0=16, P1=50, P2=20

## 外部检索用于知识准确性验证

External Retrieval for Knowledge Accuracy Verification 是 S-level 核心差距。它的目的不是无边界收集更多内容，而是验证现有 KB 的准确性、时效性、一致性和证据充分性。v3.7 只定义验证型检索规划，并区分 answer retrieval 与 validation retrieval；v3.8 才实现 claim_check、source_cross_check、freshness_check、contradiction_detection、knowledge_accuracy_score、verification_retrieval_trace 和 claim_verification_report；v4.3 再进入长期治理。

## 本地文档解析与 PDF Token 降耗

Raw PDF 不应该默认整包发送给 LLM。产品应优先走 local parsing -> structured Markdown/JSON -> chunking -> retrieval：这样既保护隐私边界，也减少 token 成本。LiteDoc 的价值在于 100% client-side PDF to Markdown 和 no server upload；HeiTang 当前已有本地 PDF/OCR/parser backend 基础，但缺少 LiteDoc-like PDF-to-Markdown 中间产物、parser backend benchmark report 和 token cost reduction report。

## LLM 可选辅助层

LLM 必须被视为 optional assistive layer，而不是 required dependency。每个 gap item 都记录 deterministic/local implementation path、optional LLM-assisted enhancement path、offline fallback，以及 tests_require_real_llm_api_network=false。Core 功能必须在没有配置 LLM provider 时仍可用，测试不得依赖真实 LLM/API/网络调用。

## 类别

- RAG Query Understanding: 6 items, P0=3, P1=3, P2=0
- RAG Retrieval Quality: 9 items, P0=2, P1=7, P2=0
- Agent / Skill System: 8 items, P0=0, P1=5, P2=3
- External Retrieval for Knowledge Accuracy Verification: 12 items, P0=9, P1=3, P2=0
- Local Document Parsing & PDF Token Reduction: 12 items, P0=0, P1=7, P2=5
- Agent Memory / Runtime: 12 items, P0=0, P1=7, P2=5
- Storage / Workspace: 12 items, P0=0, P1=7, P2=5
- Workbench / UI Contracts: 7 items, P0=1, P1=6, P2=0
- Product Readiness: 8 items, P0=1, P1=5, P2=2

## P0 项

- RAG Query Understanding / Query Rewrite -> v3.7
- RAG Query Understanding / Multi-query Generation -> v3.7
- RAG Query Understanding / Retrieval Planning -> v3.7
- RAG Retrieval Quality / Multi-query Recall -> v3.8
- RAG Retrieval Quality / Rerank -> v3.8
- External Retrieval for Knowledge Accuracy Verification / claim extraction from a KB package -> v3.8
- External Retrieval for Knowledge Accuracy Verification / claim-level evidence mapping -> v3.8
- External Retrieval for Knowledge Accuracy Verification / external source retrieval for verification -> v3.8
- External Retrieval for Knowledge Accuracy Verification / source cross-checking -> v3.8
- External Retrieval for Knowledge Accuracy Verification / contradiction detection -> v3.8
- External Retrieval for Knowledge Accuracy Verification / knowledge accuracy scoring -> v3.8
- External Retrieval for Knowledge Accuracy Verification / verification retrieval trace -> v3.8
- External Retrieval for Knowledge Accuracy Verification / claim verification report -> v3.8
- External Retrieval for Knowledge Accuracy Verification / user-facing explanation of claim trust status -> v3.8
- Workbench / UI Contracts / Core/UI contract drift risk -> v4.0
- Product Readiness / Golden Demo readiness -> v3.11

完整机器可读结果见 `architecture_gap_audit_report.json`。
