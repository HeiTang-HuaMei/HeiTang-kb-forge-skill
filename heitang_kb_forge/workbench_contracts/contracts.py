from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json


WORKBENCH_CONTRACT_OUTPUT_FILES = [
    "workbench_contract_manifest.json",
    "workbench_navigation_contract.json",
    "workbench_action_contract.json",
    "workbench_agent_contract.json",
    "workbench_hierarchy_contract.json",
    "workbench_memory_contract.json",
    "workbench_storage_contract.json",
    "workbench_error_contract.json",
    "workbench_asset_contract.json",
    "workbench_status_contract.json",
    "workbench_contract_trace.json",
    "workbench_contract_report.md",
]


def generate_workbench_contracts(core_output: Path, output: Path | None = None, project_name: str = "HeiTang Workbench") -> dict:
    if not core_output.exists() or not core_output.is_dir():
        raise FileNotFoundError(f"Core output not found: {core_output}")
    target = output or core_output
    target.mkdir(parents=True, exist_ok=True)
    assets = _assets(core_output)
    navigation = {
        "workbench_navigation_contract_version": "3.4.0-alpha.1",
        "project_name": project_name,
        "views": [
            {"id": "packages", "label": "Knowledge Packages", "asset_types": ["knowledge_package"]},
            {"id": "skills", "label": "Skills", "asset_types": ["skill_package", "fused_skill"]},
            {"id": "agents", "label": "Agents", "asset_types": ["agent_package"]},
            {"id": "agent_builder", "label": "Agent Builder", "asset_types": ["agent_package"]},
            {"id": "standalone_agent_builder", "label": "Standalone Agent Builder", "asset_types": ["agent_package"]},
            {"id": "kb_bound_agent_generator", "label": "KB-bound Agent Generator", "asset_types": ["knowledge_package", "agent_package"]},
            {"id": "agent_package_validator", "label": "Agent Package Validator", "asset_types": ["agent_package", "report"]},
            {"id": "agent_smoke_test", "label": "Agent Smoke Test", "asset_types": ["agent_package", "report"]},
            {"id": "agent_hierarchy", "label": "Agent Hierarchy", "asset_types": ["agent_package", "report"]},
            {"id": "local_agent_runtime", "label": "Local Agent Runtime", "asset_types": ["agent_package", "report"]},
            {"id": "golden_demo_acceptance", "label": "Golden Demo Acceptance", "asset_types": ["report"]},
            {"id": "product_hardening", "label": "Product Hardening", "asset_types": ["report"]},
            {"id": "local_release_readiness", "label": "Local Release Readiness", "asset_types": ["report"]},
            {"id": "memory_policy", "label": "Memory Policy", "asset_types": ["report"]},
            {"id": "memory_writeback", "label": "Memory Writeback", "asset_types": ["report"]},
            {"id": "storage_status", "label": "Storage Status", "asset_types": ["storage", "report"]},
            {"id": "storage_lifecycle", "label": "Storage Lifecycle", "asset_types": ["storage", "report"]},
            {"id": "parser_benchmark", "label": "Parser Benchmark", "asset_types": ["report"]},
            {"id": "pdf_token_reduction", "label": "PDF Token Reduction", "asset_types": ["report"]},
            {"id": "query_rewrite", "label": "Query Rewrite", "asset_types": ["report"]},
            {"id": "retrieval_planning", "label": "Retrieval Planning", "asset_types": ["report"]},
            {"id": "retrieval_quality", "label": "Retrieval Quality", "asset_types": ["report"]},
            {"id": "claim_verification", "label": "Claim Verification", "asset_types": ["report"]},
            {"id": "knowledge_accuracy", "label": "Knowledge Accuracy", "asset_types": ["report"]},
            {"id": "reports", "label": "Reports", "asset_types": ["report"]},
        ],
    }
    actions = {
        "workbench_action_contract_version": "3.4.0-alpha.1",
        "actions": [
            {"id": "build_package", "label": "Build Package", "command": "build", "requires": ["input", "output"]},
            {"id": "book_to_skill", "label": "Book to Skill", "command": "book-to-skill", "requires": ["input_or_package", "output", "skill_name"]},
            {"id": "extract_methodology", "label": "Extract Methodology", "command": "extract-methodology", "requires": ["knowledge_package", "output"]},
            {"id": "plan_skill_suite", "label": "Plan Skill Suite", "command": "plan-skill-suite", "requires": ["methodology", "output"]},
            {"id": "generate_structured_skill", "label": "Generate Structured Skill", "command": "generate-skill --on-demand", "requires": ["package", "output"]},
            {"id": "validate_skill_package", "label": "Validate Skill Package", "command": "validate-skill-package", "requires": ["skill", "output"]},
            {"id": "diff_skill_package", "label": "Diff Skill Package", "command": "diff-skill-package", "requires": ["old_skill", "new_skill", "output"]},
            {"id": "skill_governance_report", "label": "Skill Governance Report", "command": "skill-governance-report", "requires": ["skill", "output"]},
            {"id": "generate_documents", "label": "Generate Documents", "command": "generate-documents", "requires": ["package", "output"]},
            {"id": "generate_bound_agent", "label": "Generate Bound Agent", "command": "generate-bound-agent", "requires": ["package", "output"]},
            {"id": "create_standalone_agent", "label": "Create Standalone Agent", "command": "generate-agent --mode standalone", "requires": ["output"]},
            {"id": "create_kb_bound_agent", "label": "Create KB-bound Agent", "command": "generate-agent --mode kb_bound", "requires": ["package", "skill", "output"]},
            {"id": "validate_agent_package", "label": "Validate Agent Package", "command": "local-validation", "requires": ["agent"]},
            {"id": "run_agent_smoke_test", "label": "Run Agent Smoke Test", "command": "local-smoke-test", "requires": ["agent"]},
            {"id": "configure_agent_hierarchy", "label": "Configure Agent Hierarchy", "command": "orchestrate-multi-kb --mother-agent", "requires": ["mother_agent", "child_agents"]},
            {"id": "bind_child_agent", "label": "Bind Child Agent", "command": "orchestrate-multi-kb --agents", "requires": ["child_agent"]},
            {"id": "queue_memory_writeback", "label": "Queue Memory Writeback", "command": "orchestrate-multi-kb --parent-writeback", "requires": ["child_agent", "candidate"]},
            {"id": "run_local_agent", "label": "Run Local Agent", "command": "run-local-agent", "requires": ["package", "agent", "task", "output"]},
            {"id": "run_golden_demo_acceptance", "label": "Run Golden Demo Acceptance", "command": "run-golden-demo-acceptance", "requires": ["package", "output"]},
            {"id": "run_product_hardening", "label": "Run Product Hardening", "command": "product-hardening", "requires": ["workspace", "package", "output"]},
            {"id": "review_memory_candidate", "label": "Review Memory Candidate", "command": "review-memory-candidate", "requires": ["candidate"]},
            {"id": "promote_memory_candidate", "label": "Promote Memory Candidate", "command": "promote-memory-candidate", "requires": ["candidate", "approval"]},
            {"id": "inspect_storage_status", "label": "Inspect Storage Status", "command": "workbench-contracts", "requires": ["core_output"]},
            {"id": "scan_workspace_storage", "label": "Scan Workspace Storage", "command": "scan-workspace", "requires": ["workspace"]},
            {"id": "report_storage", "label": "Report Storage", "command": "report-storage", "requires": ["workspace"]},
            {"id": "plan_cleanup", "label": "Plan Cleanup", "command": "plan-cleanup", "requires": ["workspace"]},
            {"id": "plan_memory_lifecycle", "label": "Plan Memory Lifecycle", "command": "plan-memory-lifecycle", "requires": ["output"]},
            {"id": "benchmark_parser_backends", "label": "Benchmark Parser Backends", "command": "benchmark-parser-backends", "requires": ["source", "output"]},
            {"id": "report_pdf_token_reduction", "label": "Report PDF Token Reduction", "command": "report-pdf-token-reduction", "requires": ["source", "output"]},
            {"id": "rewrite_query", "label": "Rewrite Query", "command": "rewrite-query", "requires": ["query", "output"]},
            {"id": "plan_retrieval", "label": "Plan Retrieval", "command": "plan-retrieval", "requires": ["query", "output"]},
            {"id": "eval_retrieval", "label": "Evaluate Retrieval", "command": "eval-retrieval", "requires": ["package", "output"]},
            {"id": "rerank_results", "label": "Rerank Results", "command": "rerank-results", "requires": ["package", "query", "output"]},
            {"id": "select_evidence", "label": "Select Evidence", "command": "select-evidence", "requires": ["package", "query", "output"]},
            {"id": "verify_claims", "label": "Verify Claims", "command": "verify-claims", "requires": ["package", "output"]},
            {"id": "check_knowledge_accuracy", "label": "Check Knowledge Accuracy", "command": "check-knowledge-accuracy", "requires": ["package", "output"]},
            {"id": "export_local_workspace", "label": "Export Local Workspace", "command": "workspace-export", "requires": ["workspace", "output"]},
            {"id": "orchestrate_multi_kb", "label": "Orchestrate Multi-KB", "command": "orchestrate-multi-kb", "requires": ["packages", "output"]},
            {"id": "reverse_fuse_skills", "label": "Reverse Fuse Skills", "command": "reverse-fuse-skills", "requires": ["skills", "output"]},
        ],
    }
    agent_contract = _agent_contract()
    hierarchy_contract = _hierarchy_contract()
    memory_contract = _memory_contract()
    storage_contract = _storage_contract(core_output)
    error_contract = _error_contract()
    asset_contract = {"workbench_asset_contract_version": "3.4.0-alpha.1", "assets": assets}
    status = {
        "workbench_status_contract_version": "3.4.0-alpha.1",
        "status": "ready" if assets else "empty",
        "asset_count": len(assets),
        "report_count": len([asset for asset in assets if asset["asset_type"] == "report"]),
        "hierarchy_trace_available": (core_output / "hierarchy_trace.json").exists(),
        "memory_writeback_available": (core_output / "memory_writeback_report.json").exists(),
        "memory_isolation_available": (core_output / "memory_isolation_report.json").exists(),
        "storage_backend": storage_contract["storage_backend"],
        "storage_status": storage_contract["status"],
        "memory_size_bytes": storage_contract["sizes"]["memory_size_bytes"],
        "package_size_bytes": storage_contract["sizes"]["package_size_bytes"],
        "index_size_bytes": storage_contract["sizes"]["index_size_bytes"],
        "compaction_status": storage_contract["compaction_status"],
        "backup_export_status": storage_contract["backup_export_status"],
        "query_rewrite_available": (core_output / "query_rewrite_trace.json").exists(),
        "retrieval_plan_available": (core_output / "retrieval_plan.json").exists(),
        "retrieval_purposes": ["answering", "validation"],
        "retrieval_quality_available": (core_output / "retrieval_quality_report.json").exists(),
        "rerank_available": (core_output / "rerank_report.json").exists(),
        "evidence_selection_available": (core_output / "evidence_selection_trace.json").exists(),
        "claim_verification_available": (core_output / "claim_verification_report.json").exists(),
        "knowledge_accuracy_available": (core_output / "knowledge_accuracy_report.json").exists(),
        "v38_external_absorption_map_available": (core_output / "v38_external_absorption_map.json").exists(),
        "retrieval_quality_network_required": False,
        "workspace_storage_available": (core_output / "workspace_registry.json").exists(),
        "storage_usage_report_available": (core_output / "storage_usage_report.json").exists(),
        "cleanup_plan_available": (core_output / "cleanup_plan.json").exists(),
        "token_budget_policy_available": (core_output / "token_budget_policy.json").exists(),
        "parser_backend_benchmark_available": (core_output / "parser_backend_benchmark_report.json").exists(),
        "pdf_token_reduction_available": (core_output / "pdf_token_reduction_report.json").exists(),
        "no_cloud_upload_available": (core_output / "no_cloud_upload_report.json").exists(),
        "v39_external_absorption_map_available": (core_output / "v39_external_absorption_map.json").exists(),
        "local_agent_runtime_available": (core_output / "local_agent_runtime_status.json").exists(),
        "mother_child_runtime_available": (core_output / "mother_child_runtime_trace.json").exists(),
        "child_kb_access_report_available": (core_output / "child_kb_access_report.json").exists(),
        "workflow_shared_memory_report_available": (core_output / "workflow_shared_memory_report.json").exists(),
        "parent_writeback_actions_available": (core_output / "parent_memory_writeback_actions.json").exists(),
        "golden_demo_acceptance_available": (core_output / "real_acceptance_smoke_result.json").exists(),
        "artifact_openability_available": (core_output / "artifact_openability_report.json").exists(),
        "sample_coverage_available": (core_output / "sample_coverage_report.json").exists(),
        "product_hardening_available": (core_output / "product_hardening_manifest.json").exists(),
        "local_release_readiness_available": (core_output / "local_release_readiness_result.json").exists(),
        "v4_rc_gate_available": (core_output / "v4_rc_gate_report.json").exists(),
        "structured_skill_package_available": (core_output / "structured_skill_package" / "SKILL.md").exists() or (core_output / "structured_skill_package_completion_report.json").exists(),
        "book_to_skill_absorption_available": (core_output / "book_to_skill_benchmark_absorption_report.json").exists(),
        "skill_on_demand_loading_available": (core_output / "on_demand_loading_report.json").exists() or (core_output / "structured_skill_package" / "on_demand_load_manifest.json").exists(),
        "skill_installability_available": (core_output / "skill_installability_report.json").exists() or (core_output / "structured_skill_package" / "skill_installability_report.json").exists(),
        "skill_agent_kb_compatibility_available": (core_output / "skill_agent_kb_compatibility_report.json").exists() or (core_output / "structured_skill_package" / "skill_agent_kb_compatibility_report.json").exists(),
        "skill_governance_report_available": (core_output / "skill_governance_report.json").exists() or (core_output / "structured_skill_package" / "skill_governance_report.json").exists(),
        "methodology_map_available": (core_output / "methodology_map.json").exists(),
        "evidence_windows_available": (core_output / "evidence_windows.json").exists(),
        "skill_candidates_available": (core_output / "skill_candidates.json").exists(),
    }
    manifest = {
        "workbench_contract_version": "3.4.0-alpha.1",
        "project_name": project_name,
        "core_output": str(core_output).replace("\\", "/"),
        "status": status["status"],
        "output_files": WORKBENCH_CONTRACT_OUTPUT_FILES,
    }
    trace = {
        "workbench_contract_trace_version": "3.4.0-alpha.1",
        "steps": [
            {"name": "scan_core_output", "status": "pass", "asset_count": len(assets)},
            {"name": "write_navigation_contract", "status": "pass"},
            {"name": "write_action_contract", "status": "pass"},
            {"name": "write_agent_contract", "status": "pass"},
            {"name": "write_hierarchy_contract", "status": "pass"},
            {"name": "write_memory_contract", "status": "pass"},
            {"name": "write_storage_contract", "status": "pass"},
            {"name": "write_error_contract", "status": "pass"},
            {"name": "write_status_contract", "status": status["status"]},
        ],
    }
    write_json(target / "workbench_contract_manifest.json", manifest)
    write_json(target / "workbench_navigation_contract.json", navigation)
    write_json(target / "workbench_action_contract.json", actions)
    write_json(target / "workbench_agent_contract.json", agent_contract)
    write_json(target / "workbench_hierarchy_contract.json", hierarchy_contract)
    write_json(target / "workbench_memory_contract.json", memory_contract)
    write_json(target / "workbench_storage_contract.json", storage_contract)
    write_json(target / "workbench_error_contract.json", error_contract)
    write_json(target / "workbench_asset_contract.json", asset_contract)
    write_json(target / "workbench_status_contract.json", status)
    write_json(target / "workbench_contract_trace.json", trace)
    (target / "workbench_contract_report.md").write_text(_report(manifest, status), encoding="utf-8")
    return manifest


def _assets(core_output: Path) -> list[dict]:
    candidates = [
        ("manifest.json", "knowledge_package"),
        ("evidence_windows.json", "report"),
        ("methodology_map.json", "report"),
        ("methodology_map.md", "report"),
        ("source_trace.json", "report"),
        ("skill_candidates.json", "report"),
        ("skill_plan.json", "report"),
        ("dependency_draft.json", "report"),
        ("candidate_planning_report.md", "report"),
        ("generated_file_report.json", "report"),
        ("knowledge_bound_factory_manifest.json", "report"),
        ("multi_kb_orchestration_manifest.json", "report"),
        ("hierarchy_trace.json", "report"),
        ("memory_writeback_report.json", "report"),
        ("memory_promotion_report.json", "report"),
        ("memory_isolation_report.json", "report"),
        ("memory_lifecycle_report.json", "report"),
        ("query_rewrite_report.json", "report"),
        ("query_rewrite_trace.json", "report"),
        ("retrieval_plan.json", "report"),
        ("retrieval_plan_report.md", "report"),
        ("multi_query_recall_trace.json", "report"),
        ("rerank_report.json", "report"),
        ("evidence_selection_trace.json", "report"),
        ("retrieval_failure_report.json", "report"),
        ("retrieval_quality_report.json", "report"),
        ("retrieval_quality_report.md", "report"),
        ("golden_query_eval_report.json", "report"),
        ("claim_verification_report.json", "report"),
        ("source_cross_check_report.json", "report"),
        ("contradiction_map.json", "report"),
        ("freshness_check_report.json", "report"),
        ("knowledge_accuracy_report.json", "report"),
        ("verification_retrieval_trace.json", "report"),
        ("v38_external_absorption_map.json", "report"),
        ("workspace_registry.json", "storage"),
        ("package_registry.json", "storage"),
        ("skill_registry.json", "storage"),
        ("agent_registry.json", "storage"),
        ("memory_registry.json", "storage"),
        ("document_registry.json", "storage"),
        ("index_registry.json", "storage"),
        ("storage_usage_report.json", "report"),
        ("cleanup_plan.json", "report"),
        ("dedup_report.json", "report"),
        ("retention_policy_report.json", "report"),
        ("archive_plan.json", "report"),
        ("memory_compaction_plan.json", "report"),
        ("memory_index_contract.json", "report"),
        ("token_budget_policy.json", "report"),
        ("memory_retention_policy.json", "report"),
        ("local_pdf_markdown_report.json", "report"),
        ("parser_backend_benchmark_report.json", "report"),
        ("pdf_token_reduction_report.json", "report"),
        ("parser_backend_selection_report.json", "report"),
        ("no_cloud_upload_report.json", "report"),
        ("v39_external_absorption_map.json", "report"),
        ("local_agent_runtime_session.json", "report"),
        ("local_agent_runtime_trace.json", "report"),
        ("mother_child_runtime_trace.json", "report"),
        ("child_task_route_trace.json", "report"),
        ("child_kb_access_report.json", "report"),
        ("child_memory_isolation_report.json", "report"),
        ("workflow_shared_memory_report.json", "report"),
        ("parent_memory_writeback_actions.json", "report"),
        ("local_agent_runtime_status.json", "report"),
        ("local_agent_runtime_report.md", "report"),
        ("golden_demo_manifest.json", "report"),
        ("golden_demo_report.md", "report"),
        ("real_acceptance_smoke_result.json", "report"),
        ("real_acceptance_smoke_report.md", "report"),
        ("sample_coverage_report.json", "report"),
        ("sample_coverage_report.md", "report"),
        ("artifact_openability_report.json", "report"),
        ("artifact_openability_report.md", "report"),
        ("generated_package_compatibility_report.json", "report"),
        ("smoke_realism_report.json", "report"),
        ("v311_acceptance_trace.json", "report"),
        ("product_hardening_manifest.json", "report"),
        ("product_hardening_report.md", "report"),
        ("doctor_diagnostics_report.json", "report"),
        ("command_audit_report.json", "report"),
        ("package_audit_report.json", "report"),
        ("workspace_audit_report.json", "report"),
        ("golden_demo_verification_report.json", "report"),
        ("stable_error_taxonomy.json", "report"),
        ("troubleshooting_report.json", "report"),
        ("troubleshooting_report.md", "report"),
        ("optional_dependency_diagnostics.json", "report"),
        ("no_secret_no_temp_report.json", "report"),
        ("local_privacy_boundary_report.json", "report"),
        ("contract_drift_report.json", "report"),
        ("installer_readiness_report.json", "report"),
        ("local_release_readiness_result.json", "report"),
        ("local_release_readiness_report.md", "report"),
        ("v4_rc_gate_report.json", "report"),
        ("v4_rc_gate_report.md", "report"),
        ("v312_external_absorption_map.json", "report"),
        ("release_artifact_inventory.json", "report"),
        ("v312_hardening_trace.json", "report"),
        ("skill_reverse_fusion_manifest.json", "report"),
        ("agent_manifest.json", "agent_package"),
        ("workbench_agent_contract.json", "report"),
        ("workbench_hierarchy_contract.json", "report"),
        ("workbench_memory_contract.json", "report"),
        ("workbench_storage_contract.json", "storage"),
        ("workbench_error_contract.json", "report"),
        ("skill_package/SKILL.md", "skill_package"),
        ("structured_skill_package/SKILL.md", "skill_package"),
        ("structured_skill_package/skill_manifest.json", "skill_package"),
        ("structured_skill_package/on_demand_load_manifest.json", "skill_package"),
        ("structured_skill_package_completion_report.json", "report"),
        ("book_to_skill_benchmark_absorption_report.json", "report"),
        ("skill_agent_kb_compatibility_report.json", "report"),
        ("skill_governance_report.json", "report"),
        ("skill_governance_report.md", "report"),
        ("structured_skill_package/skill_governance_report.json", "report"),
        ("structured_skill_package/skill_governance_report.md", "report"),
        ("agent_package/agent_profile.yaml", "agent_package"),
        ("fused_skill/SKILL.md", "fused_skill"),
    ]
    assets = []
    for relative, asset_type in candidates:
        path = core_output / relative
        if path.exists():
            assets.append({"asset_id": relative.replace("/", "_").replace(".", "_"), "asset_type": asset_type, "path": str(path).replace("\\", "/")})
    return assets


def _agent_contract() -> dict:
    return {
        "workbench_agent_contract_version": "3.4.0-alpha.1",
        "supported_agent_modes": ["standalone", "kb_bound"],
        "hierarchy_roles": ["mother_agent", "child_agent"],
        "standalone_agent_schema": {
            "required": [
                "agent_manifest.json",
                "agent_profile.yaml",
                "soul.md",
                "system_prompt.md",
                "capabilities.yaml",
                "tools.yaml",
                "memory_policy.yaml",
                "output_contract.yaml",
                "answer_policy.md",
                "refusal_policy.md",
                "eval_cases.jsonl",
            ],
            "knowledge_package_required": False,
            "retrieval_binding_required": False,
        },
        "kb_bound_agent_schema": {
            "required": [
                "agent_profile.yaml",
                "soul.md",
                "system_prompt.md",
                "retrieval_config.yaml",
                "skill_manifest.yaml",
                "memory_policy.md",
                "safety_boundary.md",
            ],
            "knowledge_package_required": True,
            "retrieval_binding_required": True,
        },
        "validation_states": ["pass", "warning", "fail"],
        "error_states": ["missing_required_file", "invalid_mode", "untrusted_kb", "retrieval_binding_missing"],
    }


def _hierarchy_contract() -> dict:
    return {
        "workbench_hierarchy_contract_version": "3.4.0-alpha.1",
        "entities": {
            "mother_agent": {"role": "parent_router", "kb_binding": "none_required"},
            "child_agents": {"role": "task_executor", "modes": ["standalone", "kb_bound"]},
            "parent_child_binding": {"required_fields": ["parent", "child", "child_mode", "bound_kbs"]},
            "per_child_kb_binding": {"standalone": [], "kb_bound": ["package_id"]},
        },
        "views": ["agent_hierarchy", "child_agent_bindings", "task_route_trace"],
        "trace_files": ["hierarchy_trace.json", "multi_agent_binding_graph.json"],
        "runtime_files": ["local_agent_runtime_status.json", "mother_child_runtime_trace.json", "child_task_route_trace.json", "child_kb_access_report.json"],
    }


def _memory_contract() -> dict:
    return {
        "workbench_memory_contract_version": "3.4.0-alpha.1",
        "policy": {
            "child_private_memory_default": True,
            "workflow_shared_memory": "explicit_only",
            "selective_parent_memory_writeback": "candidate_queue_only",
            "long_term_memory_database": "not_implemented_in_v3_4",
        },
        "lifecycle_fields": [
            "session_log",
            "short_term_memory",
            "summary_memory",
            "long_term_memory",
            "memory_candidates",
            "memory_index",
            "retention_policy",
            "compaction_policy",
            "token_budget_policy",
        ],
        "writeback_actions": ["queue_memory_writeback", "review_memory_candidate", "promote_memory_candidate"],
        "status_files": [
            "memory_candidate_queue.jsonl",
            "memory_writeback_report.json",
            "memory_promotion_report.json",
            "memory_isolation_report.json",
            "memory_lifecycle_report.json",
            "memory_compaction_plan.json",
            "memory_index_contract.json",
            "token_budget_policy.json",
            "memory_retention_policy.json",
        ],
        "trace_files": ["hierarchy_trace.json", "memory_writeback_report.json"],
        "runtime_memory_files": ["child_memory_isolation_report.json", "workflow_shared_memory_report.json", "parent_memory_writeback_actions.json"],
        "token_budget": {
            "prevent_all_history_injection": True,
            "preferred_classes": ["summary_memory", "long_term_memory", "memory_index_references"],
        },
    }


def _storage_contract(core_output: Path) -> dict:
    sizes = _storage_sizes(core_output)
    return {
        "workbench_storage_contract_version": "3.4.0-alpha.1",
        "storage_backend": "local_workspace",
        "supported_storage_backends": ["local_workspace", "local_db", "byo_cloud"],
        "future_backends": {
            "local_db": {"status": "reserved", "requires_cloud": False},
            "byo_cloud": {"status": "reserved", "requires_cloud": False, "platform_hosted_user_data": False},
        },
        "storage_areas": {
            "local_workspace": {"path": str(core_output).replace("\\", "/"), "status": "active"},
            "package_storage": {"patterns": ["manifest.json", "chunks.jsonl", "cards.jsonl"], "backend": "local_workspace"},
            "skill_storage": {"patterns": ["skill_package/SKILL.md", "fused_skill/SKILL.md"], "backend": "local_workspace"},
            "agent_storage": {"patterns": ["agent_manifest.json", "agent_package/agent_profile.yaml"], "backend": "local_workspace"},
            "memory_storage": {"patterns": ["memory_candidate_queue.jsonl", "memory_lifecycle_report.json"], "backend": "local_workspace"},
            "index_storage": {"patterns": ["workspace_index.json", "vector_index.json", "memory_index"], "backend": "local_workspace"},
            "generated_document_storage": {"patterns": ["generated_file_report.json", "*.md", "*.docx", "*.pdf", "*.pptx"], "backend": "local_workspace"},
        },
        "v39_reports": {
            "workspace_registry": (core_output / "workspace_registry.json").exists(),
            "storage_usage_report": (core_output / "storage_usage_report.json").exists(),
            "cleanup_plan": (core_output / "cleanup_plan.json").exists(),
            "dedup_report": (core_output / "dedup_report.json").exists(),
            "parser_backend_benchmark": (core_output / "parser_backend_benchmark_report.json").exists(),
            "pdf_token_reduction": (core_output / "pdf_token_reduction_report.json").exists(),
            "no_cloud_upload": (core_output / "no_cloud_upload_report.json").exists(),
        },
        "parser_backend_contracts": {
            "local_pdf_to_markdown_preprocessing": True,
            "parser_backend_selection": True,
            "parser_backend_benchmark": True,
            "no_cloud_upload_required": True,
            "mandatory_cloud_upload": False,
        },
        "sizes": sizes,
        "cleanup_suggestions": _cleanup_suggestions(sizes),
        "compaction_status": "not_required" if sizes["memory_size_bytes"] < 1024 * 1024 else "recommended",
        "backup_export_status": "available_local_export",
        "status": "ready",
    }


def _error_contract() -> dict:
    return {
        "workbench_error_contract_version": "3.5.0-alpha.1",
        "empty_states": [
            {"id": "no_assets", "label": "No assets registered", "recommended_action": "build_package"},
            {"id": "no_actions", "label": "No actions available", "recommended_action": "inspect_storage_status"},
            {"id": "no_memory_trace", "label": "No memory trace available", "recommended_action": "orchestrate_multi_kb"},
        ],
        "error_states": [
            {"id": "contract_file_missing", "severity": "warning"},
            {"id": "contract_parse_error", "severity": "error"},
            {"id": "unsupported_contract_version", "severity": "warning"},
            {"id": "asset_path_missing", "severity": "warning"},
        ],
        "status_badges": ["ready", "empty", "warning", "error", "reserved"],
    }


def _storage_sizes(core_output: Path) -> dict:
    package_files = ["manifest.json", "chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl"]
    index_files = ["workspace_index.json", "vector_index.json", "faiss.index"]
    memory_files = ["memory_candidate_queue.jsonl", "memory_writeback_report.json", "memory_promotion_report.json", "memory_isolation_report.json", "memory_lifecycle_report.json"]
    return {
        "package_size_bytes": _size_sum(core_output, package_files),
        "index_size_bytes": _size_sum(core_output, index_files),
        "memory_size_bytes": _size_sum(core_output, memory_files),
        "generated_document_size_bytes": _size_sum(core_output, ["generated_file_report.json", "generated_file_report.md", "document_generation_trace.json"]),
    }


def _size_sum(core_output: Path, files: list[str]) -> int:
    return sum((core_output / item).stat().st_size for item in files if (core_output / item).exists())


def _cleanup_suggestions(sizes: dict) -> list[str]:
    suggestions = []
    if sizes["memory_size_bytes"] > 1024 * 1024:
        suggestions.append("compact_summary_memory")
    if sizes["generated_document_size_bytes"] > 5 * 1024 * 1024:
        suggestions.append("archive_generated_documents")
    return suggestions


def _report(manifest: dict, status: dict) -> str:
    return "\n".join(
        [
            "# Workbench Contract Report",
            "",
            f"Project: {manifest['project_name']}",
            f"Status: {manifest['status']}",
            f"Assets: {status['asset_count']}",
            f"Reports: {status['report_count']}",
            "",
        ]
    )
