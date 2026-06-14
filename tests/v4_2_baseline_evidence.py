from __future__ import annotations

import json
from pathlib import Path


PROFILE_TYPES = {"official_openai", "official_vendor", "openai_compatible_proxy", "local_model", "custom_http"}


def load_baseline_report(name: str) -> dict:
    return BASELINE_REPORTS[name]


def write_baseline_reports(output: Path) -> Path:
    output.mkdir(parents=True, exist_ok=True)
    for name, payload in BASELINE_REPORTS.items():
        (output / name).write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return output


BASELINE_REPORTS: dict[str, dict] = {
    "agent_runtime_capability_truth_report.json": {
        "status": "needs_review",
        "tests_require_real_llm_api_network": False,
        "capabilities": {
            "kb_bound_agent": "fixed_and_tested",
            "kb_boundary": "fixed_and_tested",
            "full_tool_calling_agent_loop": "not_implemented",
        },
        "must_not_claim": ["full autonomous Agent Runtime"],
    },
    "full_ocr_acceptance_report.json": {
        "status": "pass",
        "all_ocr_candidate_pages_attempted": True,
        "total_pages": 120,
        "completed_pages": 120,
        "failed_pages": 0,
        "extracted_character_count": 1200,
        "no_hidden_upload": True,
        "llm_required": False,
        "raw_ocr_text_committed": False,
    },
    "full_ocr_page_coverage_report.json": {
        "status": "pass",
        "total_pages": 120,
        "attempted_pages": 120,
        "completed_pages": 120,
        "all_candidate_pages_attempted": True,
    },
    "real_input_failure_report.json": {
        "blockers": [
            {
                "id": "knowledge_accuracy_warning_on_conflict_sources",
                "status": "accepted_needs_review",
                "severity": "P1",
                "reason": "warning remains visible for conflicting sources",
            }
        ]
    },
    "lifecycle_crud_update_readiness_report.json": {
        "status": "needs_review",
        "tests_require_real_llm_api_network": False,
        "destructive_cleanup_default": False,
        "readiness": {
            "create_kb": "proven",
            "update_kb": "partial",
            "cleanup_retention": "implemented_recommendation_only",
        },
    },
    "llm_provider_and_per_agent_api_readiness_report.json": {
        "status": "needs_review",
        "core_usable_without_llm_provider": True,
        "tests_require_real_llm_api_network": False,
        "api_keys_committed": False,
        "api_keys_printed": False,
        "supported_provider_profile_types": sorted(PROFILE_TYPES),
        "official_openai_only": False,
        "openai_compatible_proxy_equivalent_to_official_openai": False,
        "bundled_or_recommended_unofficial_proxy": False,
        "live_gate_pass_requires_one_valid_profile": True,
        "per_agent_api_mapping": {"status": "partial"},
    },
    "live_llm_acceptance_report.json": {
        "status": "blocked_with_reason",
        "passing_provider_profile_count": 0,
        "allowed_provider_types": sorted(PROFILE_TYPES),
        "official_openai_only": False,
        "openai_compatible_proxy_equivalent_to_official_openai": False,
        "bundled_or_recommended_unofficial_proxy": False,
        "live_gate_pass_requires_one_valid_profile": True,
    },
    "final_v4_rc_gate_report.json": {
        "overall_status": "blocked",
        "ready_for_v4_rc": False,
        "p0_blockers": [],
        "p1_blockers": [],
        "llm_provider_readiness": {
            "status": "blocked_with_reason",
            "passing_provider_profile_count": 0,
            "official_openai_only": False,
            "openai_compatible_proxy_equivalent_to_official_openai": False,
            "bundled_or_recommended_unofficial_proxy": False,
            "live_gate_pass_requires_one_valid_profile": True,
        },
        "product_architecture_completeness": {"status": "needs_review"},
    },
    "multi_format_parser_truth_matrix.json": {
        "status": "needs_review",
        "tests_require_real_llm_api_network": False,
        "formats": {
            "large_pdf": {"status": "proven"},
            "docx": {"status": "proven"},
            "scanned_pdf_full_ocr": {"status": "needs_review"},
        },
        "must_not_claim": ["full scanned PDF OCR proven"],
    },
    "optional_llm_config_redaction_report.json": {
        "status": "pass",
        "env_names_recorded": ["HEITANG_LLM_API_KEY"],
        "env_values_recorded": False,
        "api_key_value_recorded": False,
        "tests_require_real_llm_api_network": False,
    },
    "optional_llm_fallback_report.json": {
        "status": "pass",
        "core_workflow_usable_without_llm": True,
        "tests_require_real_llm_api_network": False,
    },
    "optional_llm_provider_acceptance_report.json": {
        "status": "needs_review",
        "skip_reason": "process environment isolation prevents reading user shell secrets during tests",
        "required_env_visibility": ["HEITANG_LLM_API_KEY"],
        "api_key_value_written": False,
        "api_key_value_committed": False,
        "core_workflow_requires_llm": False,
        "tests_require_real_llm_api_network": False,
        "supported_provider_profile_types": sorted(PROFILE_TYPES),
        "official_openai_only": False,
        "openai_compatible_proxy_equivalent_to_official_openai": False,
        "bundled_or_recommended_unofficial_proxy": False,
        "live_gate_pass_requires_one_valid_profile": True,
    },
    "pre_v4_real_acceptance_blocker_fix_report.json": {
        "ready_for_v4_rc": False,
        "p0_remaining_count": 0,
        "raw_inputs_committed": False,
        "full_extracted_chunks_committed": False,
        "api_keys_committed": False,
        "tests_require_real_llm_api_network": False,
        "remaining_items": [
            {"id": "final_pre_v4_gate_still_blocked", "status": "fixed"},
            {"id": "rag_vector_index_industrial_readiness_unproven", "status": "fixed"},
        ],
    },
    "product_architecture_completeness_report.json": {
        "status": "needs_review",
        "tests_require_real_llm_api_network": False,
        "layers": [
            {"layer": "input", "items": {"large_pdf": "proven", "scanned_pdf_ocr": "proven_full_120_page_ocr_after_p0_completion"}},
            {"layer": "knowledge_package", "items": {}},
            {"layer": "rag_vector_index", "status": "pass", "items": {"vector_retrieval_status": "implemented_local_json_query", "hybrid_keyword_vector_retrieval_status": "implemented_local_keyword_plus_vector", "vector_db_adapter_status": "external_adapters_offline_contract_tested"}},
            {"layer": "lifecycle", "items": {}},
            {"layer": "scale", "items": {}},
            {"layer": "agent", "items": {}},
            {"layer": "ui", "classification": "partial_desktop_core_bridge_contract", "items": {"kb_build": "bridge_contract_tested_not_page_wired"}},
            {"layer": "storage_security", "items": {"byo_cloud_database": "explicit_byo_contract_needs_live_acceptance"}},
        ],
        "gate_summary": {
            "product_architecture_completeness": {"status": "needs_review"},
            "rag_vector_index_readiness": {"status": "pass", "blocks_v4": False},
            "ui_full_operation_readiness": {"classification": "partial_desktop_core_bridge_contract", "status": "blocked"},
            "lifecycle_update_readiness": {"status": "needs_review"},
            "scale_1500_kb_agent_readiness": {"status": "needs_review"},
        },
        "must_not_claim": ["full user-operable Workbench"],
    },
    "rag_vector_index_readiness_report.json": {
        "status": "pass",
        "severity": "resolved",
        "tests_require_real_llm_api_network": False,
        "readiness": {
            "keyword_retrieval": {"status": "implemented"},
            "local_vector_retrieval_status": {"status": "implemented"},
            "hybrid_keyword_vector_retrieval_status": {"status": "implemented"},
            "metadata_filtering": {"status": "implemented_local"},
            "stale_index_detection": {"status": "implemented_local"},
            "vector_db_adapter_status": {
                "classification": "offline_adapter_contracts_implemented",
                "implemented_vector_dbs": ["Milvus", "Pinecone", "Qdrant", "Chroma"],
            },
        },
        "must_not_claim": ["external vector database live service readiness"],
    },
    "real_input_acceptance_manifest.json": {
        "input_file_count": 4,
        "package_chunk_count": 8,
        "raw_inputs_committed": False,
        "full_extracted_chunks_committed": False,
        "api_keys_committed": False,
        "tests_require_real_llm_api_network": False,
    },
    "real_input_acceptance_report.json": {
        "local_core_without_llm_status": "pass",
        "ready_for_v4_rc": False,
        "overall_status": "needs_review",
        "blocker_count": 1,
        "p0_count": 0,
    },
    "real_input_bilingual_behavior_report.json": {
        "package_preserves_chinese_and_english_sources": True,
        "language_probes": {"zh": {"status": "answered", "answer_content_redacted": True}, "en": {"status": "answered"}},
        "ui_language_setting_priority": "not_exposed_in_core_cli_needs_review",
        "tests_require_real_llm_api_network": False,
    },
    "real_input_large_file_performance_report.json": {
        "input_total_size_bytes": 1024,
        "package_chunk_count": 8,
        "command_timing_summary": {"command_count": 3},
    },
    "real_input_pdf_parser_report.json": {
        "pdf_input_count": 1,
        "raw_pdf_sent_to_llm": False,
    },
    "real_input_ocr_report.json": {
        "status": "needs_review",
        "full_scanned_pdf_ocr_verified": False,
        "max_ocr_pages_used_in_build": 8,
        "tests_require_real_llm_api_network": False,
    },
    "real_input_privacy_redaction_report.json": {
        "raw_inputs_excluded_from_commit": True,
        "full_extracted_chunks_excluded_from_commit": True,
        "generated_documents_excluded_from_commit": True,
        "api_keys_written": False,
        "api_keys_committed": False,
    },
    "real_input_artifact_index.json": {
        "raw_inputs_committed": False,
        "full_chunks_committed": False,
        "raw_input_index": [{"file": "sample.pdf"}],
    },
    "scale_1500_readiness_report.json": {
        "status": "needs_review",
        "tests_require_real_llm_api_network": False,
        "readiness": {"simulate_1500_books": "synthetic_only", "simulate_1500_agents": "not_proven"},
        "must_not_claim": ["real 1500-book production workload proven"],
    },
    "scanned_pdf_text_quality_report.json": {
        "status": "pass",
        "extracted_character_count": 1200,
        "average_chars_per_completed_page": 10,
        "raw_text_committed": False,
    },
    "security_threat_model_gap_report.json": {
        "status": "needs_review",
        "tests_require_real_llm_api_network": False,
        "covered_boundaries": {"api_key_redaction": "tested", "agent_kb_boundary": "fixed_and_tested"},
        "gaps": [{"id": "runtime_network_behavior_not_dynamic_proven"}],
        "must_not_claim": ["BYO cloud security ready"],
    },
    "storage_backend_truth_report.json": {
        "status": "needs_review",
        "tests_require_real_llm_api_network": False,
        "storage_backends": {"local_workspace": "implemented_default", "byo_cloud": "implemented_needs_live_acceptance"},
        "no_platform_hosted_user_data": True,
        "destructive_cleanup_default": False,
    },
    "ui_full_operation_acceptance_after_core_p0.json": {
        "status": "blocked",
        "classification": "partial_desktop_core_bridge_contract",
        "ui_repo_modified": True,
        "ui_repo_modified_by_core_audit": False,
        "ui_worktree_status": "dirty_existing_uncommitted_changes",
        "ui_validation_scope": "current_dirty_worktree_contract_viewer_and_desktop_core_bridge_contract",
        "validation": {"flutter_analyze": "pass", "flutter_test": "pass", "flutter_build_web": "pass", "flutter_build_windows": "pass", "ui_contract_tests": "pass", "core_bridge_tests": "pass"},
        "operations": {"kb_build": "bridge_contract_tested_not_page_wired", "llm_api_provider_settings": "not_implemented"},
        "p1_blockers": [{"id": "ui_page_workflows_not_wired_to_core_bridge", "blocks_v4_if_v4_is_local_workbench_rc": True}],
        "must_not_claim": ["full user-operable local Workbench"],
        "worktree_evidence": {"core_audit_modified_ui_source": False},
    },
    "ui_full_operation_readiness_report.json": {
        "status": "blocked",
        "classification": "partial_desktop_core_bridge_contract",
        "ui_repo_modified": True,
        "ui_repo_modified_by_core_audit": False,
        "ui_worktree_status": "dirty_existing_uncommitted_changes",
        "validation": {"flutter_analyze": "pass"},
        "operations": {"file_selection": "not_implemented", "kb_build": "bridge_contract_tested_not_page_wired"},
        "gate_decision": "blocks_v4_if_v4_is_local_workbench_rc",
        "must_not_claim": ["full user-operable local Workbench"],
    },
}
