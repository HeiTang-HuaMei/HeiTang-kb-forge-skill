# 输出报告指南

生成报告都是本地文件。它们是证据，不应仅凭文件存在就当作产品能力已通过。

## Core Package Reports

- `manifest.json`：package metadata 和计数。
- `chunks.jsonl`：retrieval chunks。
- `quality_report.json`：本地 package quality status。
- `ingest_report.md`：build 摘要。

## Query and Retrieval Reports

- `query_rewrite_report.json`
- `query_rewrite_trace.json`
- `retrieval_plan.json`
- `retrieval_quality_report.json`
- `rerank_report.json`
- `evidence_selection_trace.json`
- `retrieval_failure_report.json`

## Knowledge Accuracy Reports

- `claim_verification_report.json`
- `source_cross_check_report.json`
- `contradiction_map.json`
- `freshness_check_report.json`
- `knowledge_accuracy_report.json`
- `verification_retrieval_trace.json`

## Storage and Memory Reports

- `workspace_registry.json`
- `storage_usage_report.json`
- `cleanup_plan.json`
- `memory_lifecycle_report.json`
- `memory_compaction_plan.json`
- `token_budget_policy.json`

## Document and Parser Reports

- `generated_file_report.json`
- `document_quality_report.json`
- `export_validation_report.json`
- `local_pdf_markdown_report.json`
- `parser_backend_benchmark_report.json`
- `pdf_token_reduction_report.json`
- `no_cloud_upload_report.json`

## Agent and Workbench Reports

- `local_agent_runtime_status.json`
- `mother_child_runtime_trace.json`
- `child_kb_access_report.json`
- `child_memory_isolation_report.json`
- `workbench_status_contract.json`
- `workbench_action_contract.json`
- `workbench_asset_contract.json`

## Final Audit Reports

- `final_v4_rc_gate_report.json`：是否可以启动 v4.0 的事实来源。
- `final_product_capability_proof_report.json`：产品证明摘要。
- `final_functionality_truth_matrix.json`：逐能力 truth matrix。
- `final_industrial_red_team_report.json`：对抗式发现。
- `version_metadata_audit_report.json`：可见版本/状态真实性。
- `repository_surface_audit_report.json`：根目录可读性和证据放置。

如果报告为空、placeholder-only，或没有真实路径支撑，最终审计必须标记 blocked 或 needs_review。
