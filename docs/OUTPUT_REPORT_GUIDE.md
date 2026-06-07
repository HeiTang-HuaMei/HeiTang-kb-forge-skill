# Output Report Guide

Generated reports are local files. They should be read as evidence, not as product claims by themselves.

## Core Package Reports

- `manifest.json`: package metadata and counts.
- `chunks.jsonl`: retrieval chunks.
- `quality_report.json`: local package quality status.
- `ingest_report.md`: human-readable build summary.

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

- `final_v4_rc_gate_report.json`: source of truth for whether v4.0 may start.
- `final_product_capability_proof_report.json`: product proof summary.
- `final_functionality_truth_matrix.json`: capability-by-capability truth matrix.
- `final_industrial_red_team_report.json`: adversarial findings.
- `version_metadata_audit_report.json`: visible version/status truth.
- `repository_surface_audit_report.json`: root readability and evidence placement.

If any report is empty, placeholder-only, or unsupported by a real path, the final audit must mark it blocked or needs_review.
