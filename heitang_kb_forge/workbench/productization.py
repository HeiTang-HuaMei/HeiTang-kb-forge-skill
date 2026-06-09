from __future__ import annotations

from pathlib import Path

from pydantic import TypeAdapter

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.workbench_productization_schema import (
    TaskStatus,
    WorkbenchActionContract,
    WorkbenchArtifactRegistryEntry,
    WorkbenchCapabilityArea,
    WorkbenchErrorTaxonomyEntry,
    WorkbenchP1GateReport,
    WorkbenchProductizationBundle,
    WorkbenchProviderCandidate,
    WorkbenchProviderSchema,
    WorkbenchReportRegistryEntry,
    WorkbenchStorageSchema,
    WorkbenchTaskField,
    WorkbenchTaskSchema,
    WorkbenchTemplateRegistryEntry,
    WorkbenchWorkspaceSchema,
)


P1_PRODUCTIZATION_VERSION = "p1-core-productization-surface.1"

P1_WORKBENCH_OUTPUT_FILES = [
    "workbench_manifest.json",
    "workbench_action_contracts.json",
    "workbench_capability_matrix.json",
    "workbench_report_registry.json",
    "workbench_artifact_registry.json",
    "workbench_error_taxonomy.json",
    "workbench_task_schema.json",
    "workbench_provider_schema.json",
    "workbench_storage_schema.json",
    "workbench_workspace_schema.json",
    "workbench_template_registry.json",
    "workbench_p1_gate_report.json",
    "workbench_fixture_bundle.json",
    "workbench_productization_schema.json",
    "workbench_summary.md",
]

P1_PAGE_SPECS = [
    ("dashboard", "Dashboard", "workspace status, health, counts, gate, reports, recent tasks, and next actions"),
    ("workspace", "Workspace", "local workspace paths, health, storage, registry, backup, restore, and privacy boundary"),
    ("import_parsing", "Import & Parsing", "source validation, parser preflight, OCR detection, scan review, and parse repair"),
    ("knowledge_package_management", "Knowledge Package Management", "package build, batch, pipeline, validation, inventory, diff, export, and stale index checks"),
    ("retrieval_verification", "Retrieval & Verification", "query rewrite, retrieval planning, RAG, hybrid retrieval, rerank, evidence, verification, and freshness"),
    ("vector_hub_provider_storage", "Vector Hub / Provider / Storage", "provider validation, vector smoke, redaction, offline fallback, and storage profiles"),
    ("document_generation", "Document Generation", "Markdown, DOCX, PDF, PPTX, manual, evidence appendix, openability, and generated artifacts"),
    ("skill_factory", "Skill Factory", "book/package/template Skill generation, manifests, prompts, graph, token budget, installability, validation, and runtime profiles"),
    ("agent_factory_runtime", "Agent Factory & Runtime", "standalone and KB-bound agents, prompts, policy, tools, memory, provider mapping, traces, retries, and orchestration"),
    ("memory_center", "Memory Center", "short-term, summary, vector memory, lifecycle, compression, cleanup, isolation, and no all-history injection"),
    ("governance", "Governance", "document ownership, stale/conflict/do-not-ingest controls, health, badcases, permissions, and review-required flows"),
    ("template_library", "Template Library", "P1 Workbench templates for product, publishing, enterprise, education, commerce, and operating skills"),
    ("reports_audit", "Reports & Audit", "registry, hardening, final gate, OCR proof, live LLM acceptance, vector readiness, privacy, and blockers"),
    ("error_repair_center", "Error Repair Center", "stable user-visible failure taxonomy and repair actions"),
    ("task_job_center", "Task / Job Center", "stable task states, progress fields, retry, cancel, resume, reports, and artifacts"),
    ("artifact_management", "Artifact Management", "KB packages, chunks, indexes, generated docs, Skill/Agent packages, traces, memory files, configs, and proofs"),
]

TASK_STATUSES: list[TaskStatus] = [
    "queued",
    "running",
    "succeeded",
    "failed",
    "blocked",
    "cancelled",
    "timed_out",
    "review_required",
]

ERROR_CODES = [
    ("file_path_error", "File path error", "warning", True),
    ("unsupported_format", "Unsupported format", "warning", False),
    ("parse_failed", "Parse failed", "error", True),
    ("ocr_failed", "OCR failed", "error", True),
    ("llm_failed", "LLM call failed", "error", True),
    ("embedding_failed", "Embedding failed", "error", True),
    ("vector_db_failed", "Vector DB failed", "error", True),
    ("provider_auth_failed", "Provider authentication failed", "blocker", False),
    ("network_unavailable", "Network unavailable", "warning", True),
    ("agent_kb_access_denied", "Agent KB access denied", "blocker", False),
    ("tool_call_failed", "Tool call failed", "error", True),
    ("memory_conflict", "Memory conflict", "warning", False),
    ("index_stale", "Index stale", "warning", True),
    ("report_missing", "Report missing", "error", True),
    ("artifact_missing", "Artifact missing", "error", True),
    ("secret_risk", "Secret risk", "blocker", False),
    ("contract_drift", "Contract drift", "error", False),
    ("timeout", "Timeout", "warning", True),
    ("non_zero_exit", "Non-zero exit", "error", True),
    ("unknown_error", "Unknown error", "error", False),
]

_ACTION_SEED = [
    ("dashboard", "inspect_dashboard_status", "Inspect dashboard status", "dry_run", "workbench-smoke", ["report_p1_gate_summary", "report_system_health"], ["artifact_workspace_registry_snapshot"], ["report_missing", "artifact_missing"]),
    ("dashboard", "inspect_recent_tasks", "Inspect recent tasks", "dry_run", "workbench-smoke", ["report_task_status_summary"], ["artifact_task_event_log_fixture"], ["unknown_error"]),
    ("dashboard", "inspect_next_actions", "Inspect next actions", "dry_run", "workbench-action-dry-run --action-id inspect_next_actions", ["report_next_action_summary"], ["artifact_action_contract_pack"], ["contract_drift"]),
    ("workspace", "workspace_inspect", "Inspect workspace", "ready", "workspace-list --workspace <workspace>", ["report_workspace_health"], ["artifact_workspace_registry_snapshot"], ["file_path_error"]),
    ("workspace", "workspace_health", "Check workspace health", "ready", "workspace-health --workspace <workspace>", ["report_workspace_health"], ["artifact_workspace_health_fixture"], ["file_path_error", "report_missing"]),
    ("workspace", "workspace_paths_inspect", "Inspect workspace paths", "dry_run", "workbench-action-dry-run --action-id workspace_paths_inspect", ["report_workspace_paths"], ["artifact_workspace_schema"], ["file_path_error"]),
    ("workspace", "workspace_storage_usage", "Inspect storage usage", "ready", "report-storage --workspace <workspace>", ["report_storage_usage"], ["artifact_storage_usage_fixture"], ["file_path_error"]),
    ("workspace", "workspace_cleanup_plan", "Plan cleanup", "ready", "plan-cleanup --workspace <workspace>", ["report_cleanup_recommendation"], ["artifact_cleanup_plan_fixture"], ["file_path_error"]),
    ("workspace", "workspace_backup_restore_plan", "Plan backup and restore", "ui_pending", None, ["report_backup_restore_recommendation"], ["artifact_backup_restore_plan_fixture"], ["tool_call_failed"]),
    ("import_parsing", "source_validate", "Validate source", "ready", "check-contract --package <package> --output <output>", ["report_source_validation"], ["artifact_source_inventory"], ["file_path_error", "unsupported_format"]),
    ("import_parsing", "input_file_folder_glob", "Inspect file/folder/glob input", "dry_run", "workbench-action-dry-run --action-id input_file_folder_glob", ["report_input_selection"], ["artifact_input_selection_fixture"], ["file_path_error"]),
    ("import_parsing", "format_support_matrix", "Inspect format support matrix", "ready", "parser-backend-list", ["report_format_support_matrix"], ["artifact_format_support_matrix"], ["unsupported_format"]),
    ("import_parsing", "parser_preflight", "Run parser preflight", "ready", "parse-quality-gate --input <input> --output <output>", ["report_parser_preflight"], ["artifact_parser_preflight_fixture"], ["parse_failed"]),
    ("import_parsing", "ocr_required_detection", "Detect OCR requirement", "ready", "full-ocr-acceptance --source <source> --output <output>", ["report_ocr_required_detection"], ["artifact_ocr_review_queue"], ["ocr_failed"]),
    ("import_parsing", "scanned_pdf_review", "Review scanned PDF", "planned_adapter", None, ["report_scanned_pdf_review"], ["artifact_scanned_pdf_review_fixture"], ["ocr_failed"]),
    ("import_parsing", "parse_repair_suggest", "Suggest parse repair", "ready", "parse-reimport-corrected-text --corrected-text <file> --output <output>", ["report_parse_repair_suggestion"], ["artifact_parse_repair_patch_fixture"], ["parse_failed"]),
    ("import_parsing", "pdf_token_reduction", "Report PDF token reduction", "ready", "report-pdf-token-reduction --source <source> --output <output>", ["report_pdf_token_reduction"], ["artifact_pdf_token_reduction_fixture"], ["parse_failed"]),
    ("knowledge_package_management", "package_build", "Build package", "ready", "build --input <input> --output <output>", ["report_package_quality"], ["artifact_kb_package"], ["parse_failed", "file_path_error"]),
    ("knowledge_package_management", "package_batch", "Run batch build", "ready", "batch-run --input <input> --output <output>", ["report_batch_summary"], ["artifact_batch_manifest"], ["timeout", "non_zero_exit"]),
    ("knowledge_package_management", "package_pipeline", "Run pipeline", "ready", "pipeline --config <config>", ["report_pipeline_summary"], ["artifact_pipeline_manifest"], ["non_zero_exit"]),
    ("knowledge_package_management", "package_validation", "Validate package", "ready", "check-contract --package <package> --output <output>", ["report_package_validation"], ["artifact_contract_check_fixture"], ["artifact_missing"]),
    ("knowledge_package_management", "source_inventory", "Inspect source inventory", "dry_run", "workbench-action-dry-run --action-id source_inventory", ["report_source_inventory"], ["artifact_source_inventory"], ["report_missing"]),
    ("knowledge_package_management", "package_diff", "Diff package", "ready", "lifecycle-check --input <input> --package <package> --output <output>", ["report_package_diff"], ["artifact_package_diff_fixture"], ["index_stale"]),
    ("knowledge_package_management", "incremental_update", "Plan incremental update", "ready", "refresh-check --workspace <workspace> --output <output>", ["report_incremental_update"], ["artifact_incremental_plan_fixture"], ["index_stale"]),
    ("knowledge_package_management", "stale_index_detect", "Detect stale index", "ready", "kb-index --package <package> --output <output>", ["report_stale_index"], ["artifact_vector_index"], ["index_stale"]),
    ("knowledge_package_management", "package_export", "Export downstream package", "ready", "export-platform --skill <skill> --output <output>", ["report_downstream_export"], ["artifact_downstream_package"], ["artifact_missing"]),
    ("knowledge_package_management", "package_archive_delete_plan", "Plan archive/delete", "ui_pending", None, ["report_archive_delete_recommendation"], ["artifact_archive_delete_plan_fixture"], ["unknown_error"]),
    ("retrieval_verification", "query_rewrite", "Rewrite query", "ready", "rewrite-query --query <query> --output <output>", ["report_query_rewrite"], ["artifact_query_rewrite_trace"], ["unknown_error"]),
    ("retrieval_verification", "retrieval_planning", "Plan retrieval", "ready", "plan-retrieval --query <query> --output <output>", ["report_retrieval_plan"], ["artifact_retrieval_plan"], ["unknown_error"]),
    ("retrieval_verification", "rag_query", "Run RAG query", "ready", "kb-query --package <package> --query <query> --output <output>", ["report_rag_query"], ["artifact_retrieval_trace"], ["artifact_missing"]),
    ("retrieval_verification", "hybrid_retrieval", "Run hybrid retrieval", "ready", "eval-retrieval --package <package> --output <output>", ["report_hybrid_retrieval"], ["artifact_hybrid_retrieval_trace"], ["vector_db_failed"]),
    ("retrieval_verification", "rerank", "Rerank results", "ready", "rerank-results --package <package> --query <query> --output <output>", ["report_rerank"], ["artifact_rerank_trace"], ["llm_failed"]),
    ("retrieval_verification", "evidence_selection", "Select evidence", "ready", "select-evidence --package <package> --query <query> --output <output>", ["report_evidence_selection"], ["artifact_evidence_appendix"], ["artifact_missing"]),
    ("retrieval_verification", "claim_verification", "Verify claims", "ready", "verify-claims --package <package> --output <output>", ["report_claim_verification"], ["artifact_claim_verification_trace"], ["llm_failed"]),
    ("retrieval_verification", "contradiction_detection", "Detect contradictions", "ready", "check-knowledge-accuracy --package <package> --output <output>", ["report_contradiction_detection"], ["artifact_contradiction_map"], ["unknown_error"]),
    ("retrieval_verification", "freshness_check", "Check freshness", "ready", "check-knowledge-accuracy --package <package> --output <output>", ["report_freshness_check"], ["artifact_freshness_check_fixture"], ["index_stale"]),
    ("retrieval_verification", "retrieval_purpose_switch", "Switch retrieval purpose", "dry_run", "workbench-action-dry-run --action-id retrieval_purpose_switch", ["report_retrieval_purpose"], ["artifact_retrieval_purpose_fixture"], ["contract_drift"]),
    ("vector_hub_provider_storage", "llm_provider_validate", "Validate LLM provider", "ready", "provider-readiness --workspace <workspace> --output <output>", ["report_provider_readiness"], ["artifact_provider_profile_schema"], ["provider_auth_failed"]),
    ("vector_hub_provider_storage", "embedding_provider_validate", "Validate embedding provider", "planned_adapter", None, ["report_embedding_provider_readiness"], ["artifact_embedding_profile_schema"], ["embedding_failed"]),
    ("vector_hub_provider_storage", "reranker_provider_validate", "Validate reranker provider", "planned_adapter", None, ["report_reranker_provider_readiness"], ["artifact_reranker_profile_schema"], ["llm_failed"]),
    ("vector_hub_provider_storage", "vector_db_validate", "Validate vector DB", "ready", "vector-db-completion --output <output>", ["report_vector_db_readiness"], ["artifact_vector_storage_profile"], ["vector_db_failed"]),
    ("vector_hub_provider_storage", "vector_upsert_query_smoke", "Smoke vector upsert/query", "ready", "query-vector-index --package <package> --query <query> --output <output>", ["report_vector_smoke"], ["artifact_vector_smoke_trace"], ["vector_db_failed"]),
    ("vector_hub_provider_storage", "provider_redaction_check", "Check provider redaction", "ready", "audit-redaction-check --output <output>", ["report_provider_redaction"], ["artifact_redaction_proof"], ["secret_risk"]),
    ("vector_hub_provider_storage", "offline_fallback_status", "Inspect offline fallback", "ready", "provider-fallback-test --output <output>", ["report_offline_fallback"], ["artifact_offline_fallback_fixture"], ["network_unavailable"]),
    ("vector_hub_provider_storage", "byo_storage_profile_schema", "Inspect BYO storage schema", "dry_run", "workbench-action-dry-run --action-id byo_storage_profile_schema", ["report_storage_profile_schema"], ["artifact_byo_storage_profile_schema"], ["contract_drift"]),
    ("document_generation", "generate_markdown", "Generate Markdown", "ready", "generate-md --package <package> --output <output>", ["report_generated_markdown"], ["artifact_generated_markdown"], ["artifact_missing"]),
    ("document_generation", "generate_docx", "Generate DOCX", "ready", "generate-docx --package <package> --output <output>", ["report_generated_docx"], ["artifact_generated_docx"], ["artifact_missing"]),
    ("document_generation", "generate_pdf", "Generate PDF", "ready", "generate-pdf --package <package> --output <output>", ["report_generated_pdf"], ["artifact_generated_pdf"], ["artifact_missing"]),
    ("document_generation", "generate_pptx", "Generate PPTX", "ready", "generate-pptx --package <package> --output <output>", ["report_generated_pptx"], ["artifact_generated_pptx"], ["artifact_missing"]),
    ("document_generation", "generate_manual_user_guide", "Generate manual/user guide", "ready", "generate-documents --package <package> --output <output>", ["report_manual_user_guide"], ["artifact_user_guide"], ["artifact_missing"]),
    ("document_generation", "evidence_appendix", "Generate evidence appendix", "ready", "select-evidence --package <package> --query <query> --output <output>", ["report_evidence_appendix"], ["artifact_evidence_appendix"], ["artifact_missing"]),
    ("document_generation", "openability_check", "Check artifact openability", "ready", "run-golden-demo-acceptance --package <package> --output <output>", ["report_openability_check"], ["artifact_openability_proof"], ["artifact_missing"]),
    ("skill_factory", "book_to_skill", "Book to Skill", "ready", "book-to-skill --input <input> --output <output> --skill-name <name>", ["report_book_to_skill"], ["artifact_skill_package"], ["parse_failed"]),
    ("skill_factory", "package_to_skill", "Package to Skill", "ready", "generate-skill --package <package> --output <output>", ["report_package_to_skill"], ["artifact_skill_package"], ["artifact_missing"]),
    ("skill_factory", "template_skill_generation", "Generate template Skill", "dry_run", "workbench-action-dry-run --action-id template_skill_generation", ["report_template_skill_generation"], ["artifact_template_skill_package"], ["contract_drift"]),
    ("skill_factory", "skill_manifest_validate", "Validate Skill manifests", "ready", "validate-skill-package --skill <skill> --output <output>", ["report_skill_validation"], ["artifact_skill_manifest"], ["artifact_missing"]),
    ("skill_factory", "skill_diff", "Diff Skill", "ready", "diff-skill-package --old-skill <old> --new-skill <new> --output <output>", ["report_skill_diff"], ["artifact_skill_diff"], ["artifact_missing"]),
    ("skill_factory", "skill_runtime_profile", "Inspect target runtime profile", "dry_run", "workbench-action-dry-run --action-id skill_runtime_profile", ["report_skill_runtime_profile"], ["artifact_runtime_profile_matrix"], ["contract_drift"]),
    ("agent_factory_runtime", "standalone_agent_generation", "Generate standalone Agent", "ready", "generate-agent --mode standalone --output <output>", ["report_standalone_agent"], ["artifact_agent_package"], ["artifact_missing"]),
    ("agent_factory_runtime", "kb_bound_agent_generation", "Generate KB-bound Agent", "ready", "generate-agent --mode kb_bound --package <package> --skill <skill> --output <output>", ["report_kb_bound_agent"], ["artifact_kb_bound_agent_package"], ["agent_kb_access_denied"]),
    ("agent_factory_runtime", "agent_profile_inspect", "Inspect Agent profile", "dry_run", "workbench-action-dry-run --action-id agent_profile_inspect", ["report_agent_profile"], ["artifact_agent_profile"], ["artifact_missing"]),
    ("agent_factory_runtime", "run_agent", "Run Agent", "ready", "run-local-agent --package <package> --agent <agent> --task <task> --output <output>", ["report_agent_runtime"], ["artifact_runtime_trace"], ["tool_call_failed"]),
    ("agent_factory_runtime", "agent_checkpoint_retry", "Inspect checkpoint/retry", "dry_run", "workbench-action-dry-run --action-id agent_checkpoint_retry", ["report_agent_retry_timeout"], ["artifact_agent_checkpoint"], ["timeout", "non_zero_exit"]),
    ("agent_factory_runtime", "multi_agent_orchestration", "Run multi-agent orchestration", "ready", "orchestrate-multi-kb --packages <packages> --output <output>", ["report_multi_agent_orchestration"], ["artifact_multi_agent_trace"], ["agent_kb_access_denied"]),
    ("agent_factory_runtime", "child_agent_access", "Inspect child Agent access", "dry_run", "workbench-action-dry-run --action-id child_agent_access", ["report_child_agent_access"], ["artifact_child_agent_access_matrix"], ["agent_kb_access_denied"]),
    ("memory_center", "session_memory_inspect", "Inspect session memory", "dry_run", "workbench-action-dry-run --action-id session_memory_inspect", ["report_session_memory"], ["artifact_session_memory_fixture"], ["memory_conflict"]),
    ("memory_center", "summary_memory_lifecycle", "Plan summary memory lifecycle", "ready", "plan-memory-lifecycle --output <output>", ["report_summary_memory_lifecycle"], ["artifact_memory_lifecycle_plan"], ["memory_conflict"]),
    ("memory_center", "vector_memory_status", "Inspect vector memory", "planned_adapter", None, ["report_vector_memory_status"], ["artifact_vector_memory_index"], ["vector_db_failed"]),
    ("memory_center", "memory_compression", "Estimate memory compression", "ready", "estimate-token-budget --output <output>", ["report_memory_compression"], ["artifact_memory_compression_plan"], ["timeout"]),
    ("memory_center", "memory_cleanup", "Plan memory cleanup", "ready", "plan-memory-lifecycle --output <output>", ["report_memory_cleanup"], ["artifact_memory_cleanup_plan"], ["memory_conflict"]),
    ("memory_center", "memory_isolation", "Inspect memory isolation", "dry_run", "workbench-action-dry-run --action-id memory_isolation", ["report_memory_isolation"], ["artifact_memory_isolation_policy"], ["memory_conflict"]),
    ("memory_center", "no_all_history_injection", "Verify no all-history injection", "dry_run", "workbench-action-dry-run --action-id no_all_history_injection", ["report_no_all_history_injection"], ["artifact_token_budget_policy"], ["secret_risk"]),
    ("governance", "document_owner_inspect", "Inspect document owner", "ready", "govern --package <package> --output <output>", ["report_document_owner"], ["artifact_governance_registry"], ["report_missing"]),
    ("governance", "stale_document_detect", "Detect stale document", "ready", "govern --package <package> --output <output>", ["report_stale_document"], ["artifact_stale_document_list"], ["index_stale"]),
    ("governance", "conflict_document_detect", "Detect conflict document", "ready", "govern --package <package> --output <output>", ["report_conflict_document"], ["artifact_conflict_document_map"], ["contract_drift"]),
    ("governance", "do_not_ingest_policy", "Inspect do-not-ingest policy", "dry_run", "workbench-action-dry-run --action-id do_not_ingest_policy", ["report_do_not_ingest"], ["artifact_do_not_ingest_policy"], ["secret_risk"]),
    ("governance", "badcase_collection", "Collect badcases", "ui_pending", None, ["report_badcase_collection"], ["artifact_badcase_collection_fixture"], ["unknown_error"]),
    ("governance", "no_answer_sop", "Inspect no-answer SOP", "dry_run", "workbench-action-dry-run --action-id no_answer_sop", ["report_no_answer_sop"], ["artifact_no_answer_sop"], ["unknown_error"]),
    ("template_library", "template_product_manager_kb", "Open 产品经理知识库模板", "dry_run", "workbench-action-dry-run --action-id template_product_manager_kb", ["report_template_product_manager_kb"], ["artifact_template_product_manager_kb"], ["contract_drift"]),
    ("template_library", "template_book_publisher_kb", "Open 图书/出版社知识库模板", "dry_run", "workbench-action-dry-run --action-id template_book_publisher_kb", ["report_template_book_publisher_kb"], ["artifact_template_book_publisher_kb"], ["contract_drift"]),
    ("template_library", "template_enterprise_policy_kb", "Open 企业制度知识库模板", "dry_run", "workbench-action-dry-run --action-id template_enterprise_policy_kb", ["report_template_enterprise_policy_kb"], ["artifact_template_enterprise_policy_kb"], ["contract_drift"]),
    ("template_library", "template_education_companion", "Open 教育伴学模板", "dry_run", "workbench-action-dry-run --action-id template_education_companion", ["report_template_education_companion"], ["artifact_template_education_companion"], ["contract_drift"]),
    ("template_library", "template_shopping_ops_agent", "Open 导购/运营 Agent 模板", "dry_run", "workbench-action-dry-run --action-id template_shopping_ops_agent", ["report_template_shopping_ops_agent"], ["artifact_template_shopping_ops_agent"], ["contract_drift"]),
    ("template_library", "template_manual_operation_skill", "Open 软件说明书 / 操作 Skill 模板", "dry_run", "workbench-action-dry-run --action-id template_manual_operation_skill", ["report_template_manual_operation_skill"], ["artifact_template_manual_operation_skill"], ["contract_drift"]),
    ("reports_audit", "report_registry_inspect", "Inspect report registry", "dry_run", "workbench-action-dry-run --action-id report_registry_inspect", ["report_registry_integrity"], ["artifact_report_registry"], ["report_missing"]),
    ("reports_audit", "artifact_registry_inspect", "Inspect artifact registry", "dry_run", "workbench-action-dry-run --action-id artifact_registry_inspect", ["report_artifact_registry_integrity"], ["artifact_artifact_registry"], ["artifact_missing"]),
    ("reports_audit", "product_hardening", "Run product hardening", "ready", "product-hardening --workspace <workspace> --package <package> --output <output>", ["report_product_hardening"], ["artifact_product_hardening_manifest"], ["contract_drift"]),
    ("reports_audit", "final_gate", "Read final gate", "ready", "final-pre-v4-audit --core-repo <repo> --output <output>", ["report_final_gate"], ["artifact_final_gate_proof"], ["report_missing"]),
    ("reports_audit", "p1_workbench_gate", "Read P1 Workbench gate", "dry_run", "workbench-smoke --output <output>", ["report_p1_gate_summary"], ["artifact_p1_gate_proof"], ["contract_drift"]),
    ("reports_audit", "blocker_tracker", "Inspect blocker tracker", "dry_run", "workbench-action-dry-run --action-id blocker_tracker", ["report_blocker_tracker"], ["artifact_blocker_tracker"], ["unknown_error"]),
    ("error_repair_center", "repair_file_path_error", "Repair file path error", "dry_run", "workbench-action-dry-run --action-id repair_file_path_error", ["report_error_repair_file_path"], ["artifact_repair_file_path_fixture"], ["file_path_error"]),
    ("error_repair_center", "repair_parse_failed", "Repair parse failure", "dry_run", "workbench-action-dry-run --action-id repair_parse_failed", ["report_error_repair_parse"], ["artifact_repair_parse_fixture"], ["parse_failed"]),
    ("error_repair_center", "repair_provider_auth_failed", "Repair provider auth failure", "ui_pending", None, ["report_error_repair_provider_auth"], ["artifact_repair_provider_auth_fixture"], ["provider_auth_failed"]),
    ("error_repair_center", "repair_secret_risk", "Repair secret risk", "blocked", None, ["report_error_repair_secret"], ["artifact_repair_secret_fixture"], ["secret_risk"]),
    ("error_repair_center", "repair_contract_drift", "Repair contract drift", "dry_run", "workbench-smoke --output <output>", ["report_error_repair_contract_drift"], ["artifact_repair_contract_drift_fixture"], ["contract_drift"]),
    ("task_job_center", "task_queue_inspect", "Inspect queued/running tasks", "dry_run", "workbench-action-dry-run --action-id task_queue_inspect", ["report_task_queue"], ["artifact_task_queue_fixture"], ["unknown_error"]),
    ("task_job_center", "task_cancel", "Cancel task", "ui_pending", None, ["report_task_cancel"], ["artifact_task_cancel_fixture"], ["tool_call_failed"]),
    ("task_job_center", "task_retry", "Retry task", "dry_run", "workbench-action-dry-run --action-id task_retry", ["report_task_retry"], ["artifact_task_retry_fixture"], ["timeout", "non_zero_exit"]),
    ("task_job_center", "task_resume", "Resume task", "ui_pending", None, ["report_task_resume"], ["artifact_task_resume_fixture"], ["timeout"]),
    ("task_job_center", "task_output_inspect", "Inspect task outputs", "dry_run", "workbench-action-dry-run --action-id task_output_inspect", ["report_task_outputs"], ["artifact_task_output_fixture"], ["report_missing", "artifact_missing"]),
    ("artifact_management", "artifact_kb_package_inspect", "Inspect KB package", "ready", "check-contract --package <package> --output <output>", ["report_artifact_kb_package"], ["artifact_kb_package"], ["artifact_missing"]),
    ("artifact_management", "artifact_chunks_inspect", "Inspect chunks", "dry_run", "workbench-action-dry-run --action-id artifact_chunks_inspect", ["report_artifact_chunks"], ["artifact_chunks"], ["artifact_missing"]),
    ("artifact_management", "artifact_vector_index_inspect", "Inspect vector index", "ready", "kb-index --package <package> --output <output>", ["report_artifact_vector_index"], ["artifact_vector_index"], ["index_stale"]),
    ("artifact_management", "artifact_generated_docs_inspect", "Inspect generated docs", "ready", "generate-documents --package <package> --output <output>", ["report_artifact_generated_docs"], ["artifact_generated_docs"], ["artifact_missing"]),
    ("artifact_management", "artifact_skill_package_inspect", "Inspect Skill package", "ready", "validate-skill-package --skill <skill> --output <output>", ["report_artifact_skill_package"], ["artifact_skill_package"], ["artifact_missing"]),
    ("artifact_management", "artifact_agent_package_inspect", "Inspect Agent package", "ready", "generate-agent --mode standalone --output <output>", ["report_artifact_agent_package"], ["artifact_agent_package"], ["artifact_missing"]),
    ("artifact_management", "artifact_runtime_trace_inspect", "Inspect runtime trace", "ready", "run-local-agent --package <package> --agent <agent> --task <task> --output <output>", ["report_artifact_runtime_trace"], ["artifact_runtime_trace"], ["tool_call_failed"]),
    ("artifact_management", "artifact_memory_files_inspect", "Inspect memory files", "dry_run", "workbench-action-dry-run --action-id artifact_memory_files_inspect", ["report_artifact_memory_files"], ["artifact_memory_files"], ["memory_conflict"]),
    ("artifact_management", "artifact_config_profiles_inspect", "Inspect config profiles", "dry_run", "workbench-action-dry-run --action-id artifact_config_profiles_inspect", ["report_artifact_config_profiles"], ["artifact_config_profiles"], ["secret_risk"]),
    ("artifact_management", "artifact_acceptance_proof_inspect", "Inspect acceptance proof", "ready", "run-golden-demo-acceptance --package <package> --output <output>", ["report_artifact_acceptance_proof"], ["artifact_acceptance_proof"], ["report_missing"]),
]

_BLOCKED_REASONS = {
    "planned_adapter": "Core only exposes this as a planned adapter candidate for P1; no runnable local closed loop is claimed.",
    "ui_pending": "Core contract is present, but the Windows desktop Workbench operation still needs UI wiring and user confirmation.",
    "blocked": "P1 blocks this action until explicit repair policy, review flow, or safe user input handling exists.",
}


def make_p1_workbench_bundle() -> WorkbenchProductizationBundle:
    actions = _make_actions()
    report_registry = _make_reports(actions)
    artifact_registry = _make_artifacts(actions)
    capability_areas = _make_capabilities(actions, report_registry, artifact_registry)
    bundle = WorkbenchProductizationBundle(
        profile="p1",
        productization_version=P1_PRODUCTIZATION_VERSION,
        manifest=_make_manifest(actions, capability_areas, report_registry, artifact_registry),
        capability_areas=capability_areas,
        action_contracts=actions,
        report_registry=report_registry,
        artifact_registry=artifact_registry,
        error_taxonomy=_make_errors(actions),
        task_schema=_make_task_schema(),
        provider_schema=_make_provider_schema(),
        storage_schema=_make_storage_schema(),
        workspace_schema=_make_workspace_schema(),
        template_registry=_make_templates(),
        p1_gate_report=_make_gate_report(),
        deterministic_fixtures=_make_fixtures(),
    )
    _validate_bundle(bundle)
    return bundle


def write_p1_workbench_bundle(output: Path, project_name: str = "HeiTang P1 Workbench") -> dict:
    bundle = make_p1_workbench_bundle()
    manifest = dict(bundle.manifest)
    manifest["project_name"] = project_name
    output.mkdir(parents=True, exist_ok=True)
    write_json(output / "workbench_manifest.json", manifest)
    write_json(output / "workbench_action_contracts.json", {"actions": _dump_list(bundle.action_contracts)})
    write_json(output / "workbench_capability_matrix.json", {"capability_areas": _dump_list(bundle.capability_areas)})
    write_json(output / "workbench_report_registry.json", {"reports": _dump_list(bundle.report_registry)})
    write_json(output / "workbench_artifact_registry.json", {"artifacts": _dump_list(bundle.artifact_registry)})
    write_json(output / "workbench_error_taxonomy.json", {"errors": _dump_list(bundle.error_taxonomy)})
    write_json(output / "workbench_task_schema.json", bundle.task_schema)
    write_json(output / "workbench_provider_schema.json", bundle.provider_schema)
    write_json(output / "workbench_storage_schema.json", bundle.storage_schema)
    write_json(output / "workbench_workspace_schema.json", bundle.workspace_schema)
    write_json(output / "workbench_template_registry.json", {"templates": _dump_list(bundle.template_registry)})
    write_json(output / "workbench_p1_gate_report.json", bundle.p1_gate_report)
    write_json(output / "workbench_fixture_bundle.json", bundle.deterministic_fixtures)
    write_json(output / "workbench_productization_schema.json", _schema_json())
    (output / "workbench_summary.md").write_text(_render_summary(manifest, bundle), encoding="utf-8")
    return manifest


def get_p1_workbench_action(action_id: str) -> dict:
    for action in make_p1_workbench_bundle().action_contracts:
        if action.action_id == action_id:
            return action.model_dump(mode="json")
    raise KeyError(f"Unknown P1 Workbench action_id: {action_id}")


def make_p1_workbench_dry_run(action_id: str) -> dict:
    action = get_p1_workbench_action(action_id)
    return {
        "profile": "p1",
        "action_id": action_id,
        "status": "blocked" if action["status"] == "blocked" else "dry_run_ready",
        "executes_real_operation": False,
        "would_run_command": action["command"],
        "command_kind": action["command_kind"],
        "blocked_reason": action["blocked_reason"],
        "output_reports": action["report_ids"],
        "output_artifacts": action["artifact_ids"],
        "task_statuses": action["task_statuses"],
    }


def make_p1_workbench_smoke() -> dict:
    bundle = make_p1_workbench_bundle()
    return {
        "profile": "p1",
        "status": "pass",
        "executes_real_operation": False,
        "page_count": len(bundle.capability_areas),
        "action_count": len(bundle.action_contracts),
        "report_count": len(bundle.report_registry),
        "artifact_count": len(bundle.artifact_registry),
        "error_count": len(bundle.error_taxonomy),
        "template_count": len(bundle.template_registry),
        "core_contract_ready": bundle.p1_gate_report.core_contract_ready,
        "ui_full_operation_pending": bundle.p1_gate_report.ui_full_operation_pending,
        "p1_full_operation_gate_status": bundle.p1_gate_report.p1_full_operation_gate_status,
        "not_v4_0_workbench_rc": bundle.p1_gate_report.not_v4_0_workbench_rc,
    }


def _make_actions() -> list[WorkbenchActionContract]:
    actions: list[WorkbenchActionContract] = []
    for page_id, action_id, label, status, command, report_ids, artifact_ids, error_codes in _ACTION_SEED:
        blocked_reason = _BLOCKED_REASONS.get(status)
        command_kind = "core_cli" if status == "ready" else "ui_safe_wrapper" if status == "dry_run" else "planned_adapter" if status == "planned_adapter" else "not_runnable"
        actions.append(
            WorkbenchActionContract(
                action_id=action_id,
                page_id=page_id,
                capability_id=f"cap_{page_id}",
                label=label,
                button_id=f"btn_{action_id}",
                status=status,
                command_kind=command_kind,
                command=command,
                blocked_reason=blocked_reason,
                dry_run_supported=True,
                smoke_supported=status != "blocked",
                requires_explicit_user_config=page_id == "vector_hub_provider_storage" or "provider" in action_id,
                report_ids=report_ids,
                artifact_ids=artifact_ids,
                error_codes=error_codes,
                task_statuses=TASK_STATUSES,
            )
        )
    return actions


def _make_reports(actions: list[WorkbenchActionContract]) -> list[WorkbenchReportRegistryEntry]:
    reports: dict[str, WorkbenchReportRegistryEntry] = {}
    for action in actions:
        for report_id in action.report_ids:
            reports[report_id] = WorkbenchReportRegistryEntry(
                report_id=report_id,
                page_id=action.page_id,
                title=_title(report_id, "report"),
                format="json",
                deterministic_fixture_path=f"fixtures/p1/{report_id}.json",
                owner_capability=action.capability_id,
            )
    return [reports[key] for key in sorted(reports)]


def _make_artifacts(actions: list[WorkbenchActionContract]) -> list[WorkbenchArtifactRegistryEntry]:
    artifacts: dict[str, WorkbenchArtifactRegistryEntry] = {}
    for action in actions:
        for artifact_id in action.artifact_ids:
            managed_by = ["artifact_management"] if action.page_id == "artifact_management" else ["artifact_management", action.page_id]
            if action.page_id not in managed_by:
                managed_by.append(action.page_id)
            artifacts[artifact_id] = WorkbenchArtifactRegistryEntry(
                artifact_id=artifact_id,
                page_id=action.page_id,
                title=_title(artifact_id, "artifact"),
                artifact_type=_artifact_type(artifact_id),
                deterministic_fixture_path=f"fixtures/p1/{artifact_id}.json",
                managed_by_page_ids=managed_by,
            )
    return [artifacts[key] for key in sorted(artifacts)]


def _make_capabilities(
    actions: list[WorkbenchActionContract],
    reports: list[WorkbenchReportRegistryEntry],
    artifacts: list[WorkbenchArtifactRegistryEntry],
) -> list[WorkbenchCapabilityArea]:
    by_page_actions = _group_by_page(actions, "action_id")
    by_page_reports = _group_by_page(reports, "report_id")
    by_page_artifacts = _group_by_page(artifacts, "artifact_id")
    capability_areas = []
    for page_id, title, summary in P1_PAGE_SPECS:
        capability_areas.append(
            WorkbenchCapabilityArea(
                page_id=page_id,
                title=title,
                capability_area_id=f"cap_{page_id}",
                capability_summary=summary,
                capabilities=[item.strip() for item in summary.split(",")],
                action_ids=by_page_actions.get(page_id, []),
                report_ids=by_page_reports.get(page_id, []),
                artifact_ids=by_page_artifacts.get(page_id, []),
                desktop_web_boundary="Core exposes desktop/web-safe contracts only; UI remains a separate Windows desktop Workbench.",
                privacy_boundary="Local-first deterministic fixtures only; no raw input, local profile, or secret is embedded.",
            )
        )
    return capability_areas


def _make_errors(actions: list[WorkbenchActionContract]) -> list[WorkbenchErrorTaxonomyEntry]:
    repair_map = {code: None for code, _, _, _ in ERROR_CODES}
    for action in actions:
        if action.page_id == "error_repair_center":
            for code in action.error_codes:
                repair_map[code] = action.action_id
    return [
        WorkbenchErrorTaxonomyEntry(
            error_code=code,
            title=title,
            severity=severity,
            repair_action_id=repair_map.get(code),
            retryable=retryable,
            blocked_reason=None if repair_map.get(code) else "No dedicated repair action is claimed for P1; route to Error Repair Center triage.",
        )
        for code, title, severity, retryable in ERROR_CODES
    ]


def _make_task_schema() -> WorkbenchTaskSchema:
    return WorkbenchTaskSchema(
        task_schema_version=P1_PRODUCTIZATION_VERSION,
        statuses=TASK_STATUSES,
        fields=[
            WorkbenchTaskField(field_id="task_id", type="stable_string", required=True, description="Stable task identifier."),
            WorkbenchTaskField(field_id="action_id", type="stable_string", required=True, description="References workbench_action_contracts.action_id."),
            WorkbenchTaskField(field_id="progress", type="integer_0_100", required=True, description="Deterministic UI-safe progress value."),
            WorkbenchTaskField(field_id="current_step", type="string", required=True, description="Current step label safe for UI display."),
            WorkbenchTaskField(field_id="output_reports", type="list_report_id", required=True, description="References report_registry IDs."),
            WorkbenchTaskField(field_id="output_artifacts", type="list_artifact_id", required=True, description="References artifact_registry IDs."),
            WorkbenchTaskField(field_id="can_cancel", type="boolean", required=True, description="Whether a UI cancel affordance is allowed."),
            WorkbenchTaskField(field_id="can_retry", type="boolean", required=True, description="Whether a UI retry affordance is allowed."),
            WorkbenchTaskField(field_id="can_resume", type="boolean", required=True, description="Whether a UI resume affordance is allowed."),
        ],
        transitions={
            "queued": ["running", "cancelled", "blocked"],
            "running": ["succeeded", "failed", "timed_out", "cancelled", "review_required"],
            "review_required": ["running", "blocked", "cancelled"],
            "failed": ["queued", "blocked"],
            "timed_out": ["queued", "blocked"],
            "blocked": ["queued"],
            "succeeded": [],
            "cancelled": [],
        },
        deterministic_fixture_path="fixtures/p1/task_schema_fixture.json",
    )


def _make_provider_schema() -> WorkbenchProviderSchema:
    return WorkbenchProviderSchema(
        provider_schema_version=P1_PRODUCTIZATION_VERSION,
        candidates=[
            WorkbenchProviderCandidate(provider_id="local_mock_llm", provider_type="llm", status="ready", ready=True, requires_explicit_user_config=False, local_first_default=True),
            WorkbenchProviderCandidate(provider_id="local_json_embedding", provider_type="embedding", status="ready", ready=True, requires_explicit_user_config=False, local_first_default=True),
            WorkbenchProviderCandidate(provider_id="local_json_vector_db", provider_type="vector_db", status="ready", ready=True, requires_explicit_user_config=False, local_first_default=True),
            WorkbenchProviderCandidate(provider_id="opendataloader", provider_type="parser_backend", status="planned_adapter", ready=False, requires_explicit_user_config=True, local_first_default=False, blocked_reason="External backend candidate only; not marked ready in P1 Core."),
            WorkbenchProviderCandidate(provider_id="paddleocr", provider_type="ocr_backend", status="planned_adapter", ready=False, requires_explicit_user_config=True, local_first_default=False, blocked_reason="External backend candidate only; not marked ready in P1 Core."),
            WorkbenchProviderCandidate(provider_id="mineru", provider_type="parser_backend", status="planned_adapter", ready=False, requires_explicit_user_config=True, local_first_default=False, blocked_reason="External backend candidate only; not marked ready in P1 Core."),
            WorkbenchProviderCandidate(provider_id="external_llm", provider_type="llm", status="blocked", ready=False, requires_explicit_user_config=True, local_first_default=False, blocked_reason="Workbench must require explicit user config; no local profile or secret fixture is shipped."),
        ],
        redaction_required=True,
        network_required_by_default=False,
        deterministic_fixture_path="fixtures/p1/provider_schema_fixture.json",
    )


def _make_storage_schema() -> WorkbenchStorageSchema:
    return WorkbenchStorageSchema(
        storage_schema_version=P1_PRODUCTIZATION_VERSION,
        local_workspace_storage=True,
        byo_storage_profile_schema={
            "profile_id": "stable_string",
            "storage_type": "local_workspace|external_user_configured",
            "root_alias": "non_secret_display_alias",
            "requires_explicit_user_config": "boolean",
            "secret_material": "forbidden",
        },
        external_provider_requires_explicit_config=True,
        deterministic_fixture_path="fixtures/p1/storage_schema_fixture.json",
    )


def _make_workspace_schema() -> WorkbenchWorkspaceSchema:
    return WorkbenchWorkspaceSchema(
        workspace_schema_version=P1_PRODUCTIZATION_VERSION,
        required_paths=["<workspace>/data", "<workspace>/reports", "<workspace>/artifacts", "<workspace>/index", "<workspace>/cache"],
        registry_files=["workspace_registry.json", "package_registry.json", "skill_registry.json", "agent_registry.json", "memory_registry.json", "document_registry.json", "index_registry.json"],
        local_first_privacy_boundary="Workbench may display aliases and relative workspace areas only; fixtures never include real user paths.",
        deterministic_fixture_path="fixtures/p1/workspace_schema_fixture.json",
    )


def _make_templates() -> list[WorkbenchTemplateRegistryEntry]:
    rows = [
        ("product_manager_kb", "产品经理知识库模板", "Product requirements, roadmap, decisions, and release evidence"),
        ("book_publisher_kb", "图书/出版社知识库模板", "Books, editorial metadata, chapters, permissions, and publisher operations"),
        ("enterprise_policy_kb", "企业制度知识库模板", "Enterprise policy, SOP, compliance, and employee guidance"),
        ("education_companion", "教育伴学模板", "Course material, practice questions, feedback, and learning companion flows"),
        ("shopping_ops_agent", "导购/运营 Agent 模板", "Product operations, shopping guidance, promotion, and service Agent use cases"),
        ("manual_operation_skill", "软件说明书 / 操作 Skill 模板", "Software manuals, operation steps, troubleshooting, and reusable Skill outputs"),
    ]
    return [
        WorkbenchTemplateRegistryEntry(
            template_id=f"template_{template_id}",
            title=title,
            use_case=use_case,
            recommended_inputs=["markdown", "docx", "pdf_text", "csv_metadata"],
            chunk_strategy="semantic_sections_with_source_inventory",
            metadata_rules=["document_owner", "update_time", "permission_label", "review_required"],
            retrieval_strategy="hybrid_retrieval_with_evidence_selection_and_freshness_check",
            skill_output_structure=["SKILL.md", "manifest", "prompts", "test-prompts", "runtime_profile"],
            agent_config={"mode": "kb_bound", "memory_isolation": True, "provider_mapping": "explicit_user_config_only"},
            evaluation_questions=["Can the package answer with cited evidence?", "Does no-answer SOP trigger when evidence is missing?", "Are stale or conflicting documents flagged?"],
            example_reports=["report_package_quality", "report_retrieval_plan", "report_p1_gate_summary"],
            p1_ready=True,
            blocked_reason=None,
        )
        for template_id, title, use_case in rows
    ]


def _make_gate_report() -> WorkbenchP1GateReport:
    return WorkbenchP1GateReport(
        gate_id="p1_workbench_gate",
        core_contract_ready=True,
        ui_full_operation_pending=True,
        p1_full_operation_gate_status="blocked",
        not_v4_0_workbench_rc=True,
        dashboard_readable=True,
        reports_readable=True,
        gate_page_readable=True,
        blocker_ids=["ui_full_operation_pending", "external_provider_user_config_required", "planned_adapter_backends_not_ready"],
        evidence_files=[
            "workbench_manifest.json",
            "workbench_action_contracts.json",
            "workbench_capability_matrix.json",
            "workbench_report_registry.json",
            "workbench_artifact_registry.json",
            "workbench_error_taxonomy.json",
            "workbench_task_schema.json",
            "workbench_p1_gate_report.json",
        ],
    )


def _make_manifest(
    actions: list[WorkbenchActionContract],
    capability_areas: list[WorkbenchCapabilityArea],
    reports: list[WorkbenchReportRegistryEntry],
    artifacts: list[WorkbenchArtifactRegistryEntry],
) -> dict[str, object]:
    return {
        "profile": "p1",
        "productization_version": P1_PRODUCTIZATION_VERSION,
        "project_name": "HeiTang P1 Workbench",
        "page_count": len(capability_areas),
        "action_count": len(actions),
        "report_count": len(reports),
        "artifact_count": len(artifacts),
        "error_count": len(ERROR_CODES),
        "template_count": 6,
        "output_files": P1_WORKBENCH_OUTPUT_FILES,
        "core_contract_ready": True,
        "ui_full_operation_pending": True,
        "p1_full_operation_gate_status": "blocked",
        "not_v4_0_workbench_rc": True,
        "desktop_web_capability_boundary": "Core provides contracts, registries, schemas, fixtures, dry-run, smoke, and inspect commands only.",
    }


def _make_fixtures() -> dict[str, object]:
    return {
        "fixture_policy": "deterministic_redacted_public_fixture_only",
        "workspace_alias": "<workspace>",
        "task_fixture": {
            "task_id": "task_p1_fixture_001",
            "action_id": "inspect_dashboard_status",
            "status": "queued",
            "progress": 0,
            "current_step": "contract_ready",
            "output_reports": ["report_p1_gate_summary"],
            "output_artifacts": ["artifact_workspace_registry_snapshot"],
            "can_cancel": True,
            "can_retry": False,
            "can_resume": False,
        },
        "provider_fixture": {"provider_id": "local_mock_llm", "secret_material": "redacted"},
        "path_fixture": {"root": "<workspace>", "reports": "<workspace>/reports", "artifacts": "<workspace>/artifacts"},
    }


def _validate_bundle(bundle: WorkbenchProductizationBundle) -> None:
    page_ids = {page_id for page_id, _, _ in P1_PAGE_SPECS}
    action_ids = {action.action_id for action in bundle.action_contracts}
    report_ids = {report.report_id for report in bundle.report_registry}
    artifact_ids = {artifact.artifact_id for artifact in bundle.artifact_registry}
    error_codes = {error.error_code for error in bundle.error_taxonomy}
    if len(action_ids) != len(bundle.action_contracts):
        raise ValueError("Duplicate Workbench action_id")
    if len(report_ids) != len(bundle.report_registry):
        raise ValueError("Duplicate Workbench report_id")
    if len(artifact_ids) != len(bundle.artifact_registry):
        raise ValueError("Duplicate Workbench artifact_id")
    if len(error_codes) != len(bundle.error_taxonomy):
        raise ValueError("Duplicate Workbench error_code")
    for capability in bundle.capability_areas:
        if capability.page_id not in page_ids:
            raise ValueError(f"Unknown page_id in capability matrix: {capability.page_id}")
        if not capability.action_ids:
            raise ValueError(f"Missing actions for page: {capability.page_id}")
        if not set(capability.action_ids) <= action_ids:
            raise ValueError(f"Unknown action_id in capability matrix: {capability.page_id}")
    for action in bundle.action_contracts:
        if action.page_id not in page_ids:
            raise ValueError(f"Unknown action page_id: {action.action_id}")
        if not action.report_ids or not set(action.report_ids) <= report_ids:
            raise ValueError(f"Unknown report_id in action: {action.action_id}")
        if not action.artifact_ids or not set(action.artifact_ids) <= artifact_ids:
            raise ValueError(f"Unknown artifact_id in action: {action.action_id}")
        if not set(action.error_codes) <= error_codes:
            raise ValueError(f"Unknown error_code in action: {action.action_id}")
        if action.status in {"planned_adapter", "ui_pending", "blocked"} and not action.blocked_reason:
            raise ValueError(f"Missing blocked_reason for action: {action.action_id}")
        if action.status == "ready" and not action.command:
            raise ValueError(f"Missing command for ready action: {action.action_id}")
    for candidate in bundle.provider_schema.candidates:
        if candidate.provider_id in {"opendataloader", "paddleocr", "mineru"} and candidate.ready:
            raise ValueError(f"External backend candidate must not be ready: {candidate.provider_id}")


def _render_summary(manifest: dict[str, object], bundle: WorkbenchProductizationBundle) -> str:
    return "\n".join(
        [
            "# P1 Workbench Contract Pack",
            "",
            f"Project: {manifest['project_name']}",
            f"Profile: {manifest['profile']}",
            f"Pages: {manifest['page_count']}",
            f"Actions: {manifest['action_count']}",
            f"Reports: {manifest['report_count']}",
            f"Artifacts: {manifest['artifact_count']}",
            f"Errors: {manifest['error_count']}",
            "",
            "## Gate",
            "",
            f"core_contract_ready: {str(bundle.p1_gate_report.core_contract_ready).lower()}",
            f"ui_full_operation_pending: {str(bundle.p1_gate_report.ui_full_operation_pending).lower()}",
            f"p1_full_operation_gate_status: {bundle.p1_gate_report.p1_full_operation_gate_status}",
            f"not_v4_0_workbench_rc: {str(bundle.p1_gate_report.not_v4_0_workbench_rc).lower()}",
            "",
            "Core exposes contracts, registries, schemas, deterministic fixtures, inspect, dry-run, and smoke commands only. Full UI operation remains blocked.",
            "",
        ]
    )


def _schema_json() -> dict[str, object]:
    return TypeAdapter(WorkbenchProductizationBundle).json_schema()


def _dump_list(rows: list[object]) -> list[dict[str, object]]:
    return [row.model_dump(mode="json") for row in rows]


def _group_by_page(rows: list[object], id_field: str) -> dict[str, list[str]]:
    grouped: dict[str, list[str]] = {}
    for row in rows:
        page_id = getattr(row, "page_id")
        grouped.setdefault(page_id, []).append(getattr(row, id_field))
    return {key: sorted(value) for key, value in grouped.items()}


def _title(identifier: str, suffix: str) -> str:
    value = identifier
    prefix = f"{suffix}_"
    if value.startswith(prefix):
        value = value[len(prefix) :]
    return value.replace("_", " ").title()


def _artifact_type(artifact_id: str) -> str:
    if "skill" in artifact_id:
        return "skill_package"
    if "agent" in artifact_id:
        return "agent_package"
    if "vector" in artifact_id or "index" in artifact_id:
        return "index"
    if "report" in artifact_id or "proof" in artifact_id:
        return "acceptance_proof"
    if "profile" in artifact_id or "schema" in artifact_id or "config" in artifact_id:
        return "config_profile"
    if "trace" in artifact_id:
        return "runtime_trace"
    if "memory" in artifact_id:
        return "memory_file"
    return "core_artifact"
