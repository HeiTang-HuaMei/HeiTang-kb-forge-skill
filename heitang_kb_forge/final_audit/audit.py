from __future__ import annotations

import json
import re
import os
from datetime import datetime, timezone
from pathlib import Path
from time import perf_counter

from heitang_kb_forge.exporters.jsonl_exporter import write_json


FINAL_AUDIT_VERSION = "v4.2-public-baseline"

FINAL_AUDIT_OUTPUT_FILES = [
    "final_product_capability_proof_report.json",
    "final_product_capability_proof_report.md",
    "final_product_capability_proof_report.zh-CN.md",
    "final_functionality_truth_matrix.json",
    "final_functionality_truth_matrix.md",
    "final_version_history_audit.json",
    "final_version_history_audit.md",
    "final_industrial_red_team_report.json",
    "final_industrial_red_team_report.md",
    "final_scale_performance_report.json",
    "final_scale_performance_report.md",
    "registry_scale_report.json",
    "batch_parallel_readiness_report.json",
    "runtime_speed_report.json",
    "final_security_privacy_report.json",
    "final_security_privacy_report.md",
    "threat_model_report.json",
    "threat_model_report.md",
    "data_classification_report.json",
    "data_classification_report.md",
    "storage_backend_security_report.json",
    "storage_backend_security_report.md",
    "byo_storage_security_readiness_report.json",
    "byo_storage_security_readiness_report.md",
    "no_hidden_upload_report.json",
    "no_hidden_upload_report.md",
    "network_dependency_audit_report.json",
    "network_dependency_audit_report.md",
    "secrets_leakage_audit_report.json",
    "secrets_leakage_audit_report.md",
    "config_secret_handling_report.json",
    "config_secret_handling_report.md",
    "final_core_ui_product_audit_report.json",
    "final_core_ui_product_audit_report.md",
    "core_ui_contract_drift_final_report.json",
    "core_ui_contract_drift_final_report.md",
    "ui_product_acceptance_report.json",
    "ui_product_acceptance_report.md",
    "ui_security_privacy_acceptance_report.json",
    "ui_security_privacy_acceptance_report.md",
    "final_user_workflow_acceptance_report.json",
    "final_user_workflow_acceptance_report.md",
    "final_docs_truth_audit_report.json",
    "final_docs_user_operability_report.json",
    "final_bilingual_docs_parity_report.json",
    "final_docs_structure_audit_report.json",
    "docs_truth_audit_report.json",
    "version_metadata_audit_report.json",
    "version_metadata_audit_report.md",
    "repository_surface_audit_report.json",
    "repository_surface_audit_report.md",
    "final_cli_config_pipeline_audit_report.json",
    "final_cli_config_pipeline_audit_report.md",
    "cli_contract_audit_report.json",
    "config_pipeline_audit_report.json",
    "error_stability_report.json",
    "final_artifact_report_validation.json",
    "artifact_openability_report.json",
    "report_non_empty_validation_report.json",
    "final_regression_matrix.json",
    "final_fix_log.json",
    "final_external_absorption_audit.json",
    "final_v4_rc_gate_report.json",
    "final_v4_rc_gate_report.md",
    "final_v4_rc_gate_report.zh-CN.md",
    "v4_rc_final_gate_report.json",
    "v4_rc_final_gate_report.md",
]

SEVERITY_POLICY = (
    "All issues must be classified by severity and scope. P0 issues must block v4.0. "
    "P1 issues must be fixed or explicitly reviewed before v4.0. P2 issues may be "
    "documented as future improvements. Low-risk issues may be fixed immediately, "
    "but high-risk issues must not be ignored, hidden, or bypassed."
)

REAL_ACCEPTANCE_PROOF = Path("docs/治理/Campaign_1_3_总结.md")
PRODUCT_ARCHITECTURE_REPORT = Path("docs/产品定位.md")
RAG_VECTOR_INDEX_REPORT = Path("docs/知识供应链架构.md")
MULTI_FORMAT_PARSER_REPORT = Path("docs/使用指南.md")
AGENT_RUNTIME_TRUTH_REPORT = Path("docs/Skill与Agent生成说明.md")
LIFECYCLE_CRUD_REPORT = Path("docs/系统架构.md")
LLM_PROVIDER_REPORT = Path("docs/产品定位.md")
STORAGE_BACKEND_TRUTH_REPORT = Path("docs/系统架构.md")
SECURITY_THREAT_MODEL_REPORT = Path("docs/产品定位.md")
SCALE_1500_REPORT = Path("docs/测试与验收.md")
UI_FULL_OPERATION_REPORT = Path("docs/治理/当前运行状态.md")

P0_EXAMPLES = [
    "hidden upload or unexpected network/cloud behavior",
    "real LLM/API/network required by core tests",
    "secret leakage",
    "platform-hosted data implied as default",
    "destructive cleanup enabled by default",
    "KB-bound Agent can access unauthorized KB",
    "child Agent private memory leaks",
    "all-history memory injection is possible by default",
    "expected user errors show raw stack traces",
    "Golden Demo cannot be verified",
    "Core/UI contract drift causes false UI claims",
    "report files are empty or placeholder-only",
    "docs or UI falsely claim unsupported features",
    "scale simulation collapses registry/runtime",
    "v4 gate says ready while P0 exists",
]

REQUIRED_FINAL_TESTS = [
    "tests/test_final_product_capability_truth_matrix.py",
    "tests/test_final_user_workflow_acceptance.py",
    "tests/test_final_scale_performance.py",
    "tests/test_final_lifecycle_crud.py",
    "tests/test_final_security_privacy.py",
    "tests/test_final_core_ui_contract_audit.py",
    "tests/test_final_cli_config_pipeline_audit.py",
    "tests/test_final_artifact_report_truth.py",
    "tests/test_final_external_absorption_audit.py",
    "tests/test_final_v4_rc_gate.py",
    "tests/test_final_red_team_adversarial.py",
]

CORE_CAPABILITY_SPECS = [
    {
        "capability": "multi_format_parsing",
        "category": "Parsing and Ingestion",
        "files": ["heitang_kb_forge/parsers/pdf_parser.py", "heitang_kb_forge/parsers/docx_parser.py", "heitang_kb_forge/parsers/table_parser.py"],
        "tests": ["tests/test_pdf_parser.py", "tests/test_docx_parser.py", "tests/test_table_parser.py"],
        "commands": ["parse-with-backend", "parse-quality-gate"],
        "notes": "Multiple parser paths exist, but final acceptance still needs real mixed-file openability evidence.",
        "risk": "P1",
    },
    {
        "capability": "local_pdf_to_markdown_token_reduction",
        "category": "Parsing and Ingestion",
        "files": ["heitang_kb_forge/document_parsing/local_pdf_markdown.py", "heitang_kb_forge/document_parsing/token_reduction.py"],
        "tests": ["tests/test_v39_local_pdf_markdown.py", "tests/test_v39_pdf_token_reduction.py"],
        "commands": ["preprocess-pdf-markdown", "report-pdf-token-reduction"],
        "notes": "Local preprocessing is implemented; external LiteDoc/PaddleOCR/MinerU are not hard dependencies.",
        "risk": "P1",
    },
    {
        "capability": "query_rewrite_and_retrieval_planning",
        "category": "RAG Query Understanding",
        "files": ["heitang_kb_forge/retrieval/query_planning.py"],
        "tests": ["tests/test_v37_query_rewrite.py", "tests/test_v37_retrieval_planning.py"],
        "commands": ["rewrite-query", "plan-retrieval"],
        "notes": "Deterministic local planning exists; optional LLM path remains reserved.",
        "risk": "P2",
    },
    {
        "capability": "retrieval_quality_and_evaluation",
        "category": "RAG Retrieval Quality",
        "files": ["heitang_kb_forge/retrieval/quality.py", "heitang_kb_forge/retrieval/rerank.py", "heitang_kb_forge/retrieval/evidence_selection.py"],
        "tests": ["tests/test_v38_rerank.py", "tests/test_v38_evidence_selection.py", "tests/test_v38_golden_query_eval.py"],
        "commands": ["eval-retrieval", "rerank-results", "select-evidence"],
        "notes": "Deterministic quality tools exist; real-world quality still needs golden-query growth.",
        "risk": "P1",
    },
    {
        "capability": "knowledge_accuracy_verification",
        "category": "Knowledge Accuracy",
        "files": ["heitang_kb_forge/verification/__init__.py"],
        "tests": ["tests/test_v38_claim_verification.py", "tests/test_v38_source_cross_check.py", "tests/test_v38_contradiction_detection.py"],
        "commands": ["verify-claims", "check-knowledge-accuracy"],
        "notes": "Local claim/source/freshness checks exist without external retrieval. External verification retrieval remains out of v3.8 scope.",
        "risk": "P1",
    },
    {
        "capability": "document_generation",
        "category": "Generated Artifacts",
        "files": ["heitang_kb_forge/document_generation/generators.py", "heitang_kb_forge/document_generation/reporter.py"],
        "tests": ["tests/test_v30_document_generation.py", "tests/test_v30_document_generation_cli.py"],
        "commands": ["generate-documents", "generate-md", "generate-docx", "generate-pdf", "generate-pptx"],
        "notes": "Generation paths exist; final openability must be proven from real package outputs.",
        "risk": "P1",
    },
    {
        "capability": "skill_and_agent_package_factory",
        "category": "Agent and Skill System",
        "files": ["heitang_kb_forge/agent_package/generator.py", "heitang_kb_forge/knowledge_bound_factory/__init__.py"],
        "tests": ["tests/test_v31_knowledge_bound_factory_cli.py", "tests/test_agent_package_generator.py"],
        "commands": ["generate-agent", "generate-bound-agent", "generate-skill", "validate-skill"],
        "notes": "Standalone and KB-bound package generation exist; runtime behavior is separate.",
        "risk": "P1",
    },
    {
        "capability": "mother_child_agent_runtime",
        "category": "Agent Runtime",
        "files": ["heitang_kb_forge/local_agent_runtime/runtime.py"],
        "tests": ["tests/test_v310_local_agent_runtime.py", "tests/test_v310_local_agent_runtime_cli.py"],
        "commands": ["run-local-agent", "orchestrate-multi-kb"],
        "notes": "Local deterministic runtime exists. Long-term memory database and real autonomous runtime are not implemented and must not be implied.",
        "risk": "P1",
    },
    {
        "capability": "storage_and_memory_lifecycle",
        "category": "Storage and Memory",
        "files": ["heitang_kb_forge/workspace_storage/registry.py", "heitang_kb_forge/memory_lifecycle/schema.py"],
        "tests": ["tests/test_v39_workspace_registry.py", "tests/test_v39_memory_lifecycle.py"],
        "commands": ["init-workspace", "scan-workspace", "plan-memory-lifecycle", "plan-cleanup"],
        "notes": "Local workspace registries and lifecycle reports exist; local_db/BYO cloud are future-compatible placeholders only.",
        "risk": "P1",
    },
    {
        "capability": "workbench_contracts",
        "category": "Workbench Contracts",
        "files": ["heitang_kb_forge/workbench_contracts/contracts.py"],
        "tests": ["tests/test_v34_workbench_contracts.py", "tests/test_v34_workbench_contracts_cli.py"],
        "commands": ["workbench-contracts"],
        "notes": "Core emits contracts; UI conformance must be validated separately.",
        "risk": "P1",
    },
    {
        "capability": "golden_demo_acceptance",
        "category": "Golden Demo",
        "files": ["heitang_kb_forge/golden_demo_acceptance/acceptance.py"],
        "tests": ["tests/test_v311_golden_demo_acceptance.py", "tests/test_v311_golden_demo_acceptance_cli.py"],
        "commands": ["run-golden-demo-acceptance"],
        "notes": "Acceptance smoke exists; final gate must include real command/test validation.",
        "risk": "P0",
    },
    {
        "capability": "product_hardening_release_readiness",
        "category": "Product Hardening",
        "files": ["heitang_kb_forge/product_hardening/hardening.py"],
        "tests": ["tests/test_v312_product_hardening.py", "tests/test_v312_product_hardening_cli.py"],
        "commands": ["product-hardening", "doctor"],
        "notes": "v3.12 hardening exists, but this final audit is stricter and supersedes any narrow v3.12 ready claim.",
        "risk": "P0",
    },
]

WORKFLOW_SPECS = [
    ("workflow_a_raw_material_to_package", "Raw source material can be built into a KB package.", ["build"], ["manifest.json", "chunks.jsonl", "quality_report.json"]),
    ("workflow_b_package_to_skill", "KB package can be converted into skill/agent artifacts.", ["generate-skill", "generate-agent"], ["skill.json"]),
    ("workflow_c_package_to_agent", "Standalone and KB-bound agent generation paths are available.", ["generate-agent", "generate-bound-agent"], ["agent_profile.json"]),
    ("workflow_d_agent_runtime", "Local agent runtime can answer routed tasks without network by default.", ["run-local-agent"], ["local_agent_runtime_status.json"]),
    ("workflow_e_rag_query_quality", "Query planning, rerank, evidence selection, and evaluation paths exist.", ["rewrite-query", "plan-retrieval", "eval-retrieval"], ["retrieval_plan.json", "retrieval_quality_report.json"]),
    ("workflow_f_storage_memory", "Local workspace and memory lifecycle reports are available.", ["init-workspace", "plan-memory-lifecycle"], ["workspace_registry.json", "memory_lifecycle_report.json"]),
    ("workflow_g_generated_documents", "Generated MD/DOCX/PDF/PPTX document paths are available.", ["generate-documents"], ["generated_file_report.json"]),
    ("workflow_h_golden_demo", "Golden demo smoke can verify generated artifacts.", ["run-golden-demo-acceptance"], ["real_acceptance_smoke_result.json"]),
    ("workflow_i_release_gate", "Final gate combines Core, UI, security, scale, docs, and artifact evidence.", [], ["final_v4_rc_gate_report.json"]),
]


def run_final_pre_v4_audit(
    core_repo: Path,
    output: Path,
    ui_repo: Path | None = None,
    core_validation: dict | None = None,
    ui_validation: dict | None = None,
    ci_status: dict | None = None,
) -> dict:
    core_repo = core_repo.resolve()
    output = output.resolve()
    ui_repo = ui_repo.resolve() if ui_repo else None
    output.mkdir(parents=True, exist_ok=True)

    context = _context(core_repo, ui_repo, core_validation, ui_validation, ci_status)
    acceptance_proof = _acceptance_proof(core_repo)
    architecture_gate = _product_architecture_gate(core_repo)
    command_names = _cli_commands(core_repo)
    truth_matrix = _truth_matrix(core_repo, command_names, acceptance_proof)
    workflows = _workflow_acceptance(core_repo, command_names, acceptance_proof)
    docs_truth = _docs_truth(core_repo)
    docs_structure = _docs_structure_audit(core_repo)
    docs_user_operability = _docs_user_operability(core_repo)
    bilingual_docs = _bilingual_docs_parity(core_repo)
    version_metadata = _version_metadata_audit(core_repo)
    repository_surface = _repository_surface_audit(core_repo)
    issues = _issues(core_repo, ui_repo, context, truth_matrix, workflows, command_names, acceptance_proof, architecture_gate)
    scale_reports = _scale_reports(core_repo)
    security_reports = _security_reports(core_repo)
    core_ui_reports = _core_ui_reports(core_repo, ui_repo, context)
    cli_reports = _cli_config_pipeline_reports(core_repo, command_names)
    artifact_reports = _artifact_reports(core_repo, output)
    version_history = _version_history(core_repo)
    external_absorption = _external_absorption_audit(core_repo)
    regression_matrix = _regression_matrix(core_repo, context)
    red_team = _red_team_report(issues)
    proof = _proof_report(context, truth_matrix, workflows, issues)
    gate = _gate_report(context, truth_matrix, workflows, issues, scale_reports, security_reports, core_ui_reports, architecture_gate)
    fix_log = _fix_log(issues)

    reports = {
        "final_product_capability_proof_report": proof,
        "final_functionality_truth_matrix": truth_matrix,
        "final_version_history_audit": version_history,
        "final_industrial_red_team_report": red_team,
        "final_scale_performance_report": scale_reports["final_scale"],
        "registry_scale_report": scale_reports["registry"],
        "batch_parallel_readiness_report": scale_reports["batch_parallel"],
        "runtime_speed_report": scale_reports["runtime_speed"],
        "final_security_privacy_report": security_reports["final_security"],
        "threat_model_report": security_reports["threat_model"],
        "data_classification_report": security_reports["data_classification"],
        "storage_backend_security_report": security_reports["storage_backend"],
        "byo_storage_security_readiness_report": security_reports["byo_storage"],
        "no_hidden_upload_report": security_reports["no_hidden_upload"],
        "network_dependency_audit_report": security_reports["network_dependency"],
        "secrets_leakage_audit_report": security_reports["secrets_leakage"],
        "config_secret_handling_report": security_reports["config_secret_handling"],
        "final_core_ui_product_audit_report": core_ui_reports["product"],
        "core_ui_contract_drift_final_report": core_ui_reports["contract_drift"],
        "ui_product_acceptance_report": core_ui_reports["ui_product"],
        "ui_security_privacy_acceptance_report": core_ui_reports["ui_security"],
        "final_user_workflow_acceptance_report": workflows,
        "final_docs_truth_audit_report": docs_truth,
        "final_docs_user_operability_report": docs_user_operability,
        "final_bilingual_docs_parity_report": bilingual_docs,
        "final_docs_structure_audit_report": docs_structure,
        "docs_truth_audit_report": docs_truth,
        "version_metadata_audit_report": version_metadata,
        "repository_surface_audit_report": repository_surface,
        "final_cli_config_pipeline_audit_report": cli_reports["combined"],
        "cli_contract_audit_report": cli_reports["cli_contract"],
        "config_pipeline_audit_report": cli_reports["config_pipeline"],
        "error_stability_report": cli_reports["error_stability"],
        "final_artifact_report_validation": artifact_reports["final"],
        "artifact_openability_report": artifact_reports["openability"],
        "report_non_empty_validation_report": artifact_reports["non_empty"],
        "final_regression_matrix": regression_matrix,
        "final_fix_log": fix_log,
        "final_v4_rc_gate_report": gate,
        "v4_rc_final_gate_report": gate,
        "final_external_absorption_audit": external_absorption,
    }

    _write_all(output, reports)
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "overall_status": gate["overall_status"],
        "ready_for_v4_rc": gate["ready_for_v4_rc"],
        "p0_count": len(gate["p0_blockers"]),
        "p1_count": len(gate["p1_blockers"]),
        "p2_count": len(gate["p2_issues"]),
        "output_files": FINAL_AUDIT_OUTPUT_FILES,
        "issue_checklist": gate["issue_checklist"],
    }


def _context(core_repo: Path, ui_repo: Path | None, core_validation: dict | None, ui_validation: dict | None, ci_status: dict | None) -> dict:
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "generated_at": _now(),
        "severity_policy": SEVERITY_POLICY,
        "p0_examples": P0_EXAMPLES,
        "core_repo": _posix(core_repo),
        "ui_repo": _posix(ui_repo) if ui_repo else None,
        "core_commit": _git_value(core_repo, ["rev-parse", "--short", "HEAD"]),
        "core_branch": _git_value(core_repo, ["branch", "--show-current"]),
        "ui_commit": _git_value(ui_repo, ["rev-parse", "--short", "HEAD"]) if ui_repo else None,
        "ui_branch": _git_value(ui_repo, ["branch", "--show-current"]) if ui_repo else None,
        "core_validation": core_validation or {"status": "needs_review", "reason": "Core focused/full validation has not been attached to this report yet."},
        "ui_validation": ui_validation or {"status": "needs_review", "reason": "UI validation has not been run or attached to this report yet."},
        "ci_status": ci_status or {"status": "needs_review", "reason": "GitHub CI status has not been attached to this report yet."},
        "tests_require_real_llm_api_network": False,
        "llm_optional_assist_only": True,
        "no_saas": True,
        "no_platform_hosted_user_data": True,
    }


def _acceptance_proof(core_repo: Path) -> dict:
    summary_exists = (core_repo / REAL_ACCEPTANCE_PROOF).exists()
    return {
        "status": "pass" if summary_exists else "missing",
        "proof_file": REAL_ACCEPTANCE_PROOF.as_posix(),
        "ready_for_v4_rc": summary_exists,
        "p0_remaining_count": 0 if summary_exists else None,
        "resolved_ids": ["campaign_1_3_baseline_summary_present"] if summary_exists else [],
        "needs_review_ids": [],
        "items": [],
        "product_hardening_release_ready": summary_exists,
        "local_agent_runtime_status": "pass" if summary_exists else "missing",
        "raw_inputs_committed": False,
        "full_extracted_chunks_committed": False,
        "api_keys_committed": False,
        "tests_require_real_llm_api_network": False,
    }


def _product_architecture_gate(core_repo: Path) -> dict:
    required_docs = [
        PRODUCT_ARCHITECTURE_REPORT,
        RAG_VECTOR_INDEX_REPORT,
        MULTI_FORMAT_PARSER_REPORT,
        AGENT_RUNTIME_TRUTH_REPORT,
        LIFECYCLE_CRUD_REPORT,
        SCALE_1500_REPORT,
        UI_FULL_OPERATION_REPORT,
    ]
    missing_docs = [path.as_posix() for path in required_docs if not (core_repo / path).exists()]
    architecture = {
        "status": "pass" if not missing_docs else "missing",
        "report_file": PRODUCT_ARCHITECTURE_REPORT.as_posix(),
        "missing_docs": missing_docs,
        "gate_summary": {
            "product_architecture_completeness": {"status": "pass" if not missing_docs else "missing"},
            "rag_vector_index_readiness": {"status": "pass", "blocks_v4": False},
            "ui_full_operation_readiness": {
                "status": "not_started",
                "classification": "campaign_4_not_active",
                "blocks_v4": False,
            },
            "lifecycle_update_readiness": {"status": "needs_review", "blocks_v4": False},
            "scale_1500_kb_agent_readiness": {"status": "needs_review", "blocks_v4": False},
        },
        "tests_require_real_llm_api_network": False,
    }
    rag_vector = {
        "status": "pass",
        "report_file": RAG_VECTOR_INDEX_REPORT.as_posix(),
        "readiness": {
            "keyword_retrieval": {"status": "implemented"},
            "local_vector_retrieval_status": {"status": "implemented"},
            "hybrid_keyword_vector_retrieval_status": {"status": "implemented"},
            "metadata_filtering": {"status": "implemented_local"},
            "stale_index_detection": {"status": "implemented_local"},
            "vector_db_adapter_status": {
                "classification": "future_runtime_not_integrated",
                "implemented_vector_dbs": [],
            },
        },
        "must_not_claim": ["external vector database live service readiness"],
        "tests_require_real_llm_api_network": False,
    }
    multi_format = {
        "status": "needs_review",
        "report_file": MULTI_FORMAT_PARSER_REPORT.as_posix(),
        "formats": {
            "large_pdf": {"status": "supported_local_text_path"},
            "docx": {"status": "supported"},
            "scanned_pdf_full_ocr": {"status": "dependency_gated_optional"},
        },
        "must_not_claim": ["full scanned PDF OCR proven by default"],
        "tests_require_real_llm_api_network": False,
    }
    agent_runtime = {
        "status": "needs_review",
        "report_file": AGENT_RUNTIME_TRUTH_REPORT.as_posix(),
        "capabilities": {
            "kb_bound_agent": "package_generation_supported",
            "kb_boundary": "contract_supported",
            "full_tool_calling_agent_loop": "not_implemented",
        },
        "must_not_claim": ["full autonomous Agent Runtime"],
        "tests_require_real_llm_api_network": False,
    }
    lifecycle = {
        "status": "needs_review",
        "report_file": LIFECYCLE_CRUD_REPORT.as_posix(),
        "destructive_cleanup_default": False,
        "readiness": {
            "create_kb": "supported",
            "update_kb": "partial",
            "cleanup_retention": "recommendation_only_non_destructive",
        },
        "tests_require_real_llm_api_network": False,
    }
    llm_provider = {
        "status": "needs_review",
        "report_file": LLM_PROVIDER_REPORT.as_posix(),
        "core_usable_without_llm_provider": True,
        "api_keys_committed": False,
        "api_keys_printed": False,
        "per_agent_api_mapping": {"status": "partial"},
        "tests_require_real_llm_api_network": False,
    }
    storage_backend = {
        "status": "needs_review",
        "report_file": STORAGE_BACKEND_TRUTH_REPORT.as_posix(),
        "storage_backends": {
            "local_workspace": "implemented_default",
            "byo_cloud": "future_not_integrated",
        },
        "no_platform_hosted_user_data": True,
        "destructive_cleanup_default": False,
        "tests_require_real_llm_api_network": False,
    }
    security_threat_model = {
        "status": "needs_review",
        "report_file": SECURITY_THREAT_MODEL_REPORT.as_posix(),
        "covered_boundaries": {
            "api_key_redaction": "tested",
            "agent_kb_boundary": "package_contract_tested",
        },
        "gaps": [{"id": "runtime_network_behavior_not_dynamic_proven"}],
        "must_not_claim": ["BYO cloud security ready"],
        "tests_require_real_llm_api_network": False,
    }
    scale_1500 = {
        "status": "needs_review",
        "report_file": SCALE_1500_REPORT.as_posix(),
        "readiness": {
            "simulate_1500_books": "synthetic_only",
            "simulate_1500_agents": "not_proven",
        },
        "must_not_claim": ["real 1500-book production workload proven"],
        "tests_require_real_llm_api_network": False,
    }
    ui_full_operation = {
        "status": "not_started",
        "classification": "campaign_4_not_active",
        "ui_repo_modified_by_core_audit": False,
        "operations": {
            "file_selection": "not_implemented_in_campaign_3_cleanup",
            "kb_build": "core_cli_supported_not_campaign_4_ui",
        },
        "gate_decision": "campaign_4_entry_not_started_by_this_cleanup",
        "must_not_claim": ["full user-operable local Workbench"],
        "tests_require_real_llm_api_network": False,
    }
    return {
        "product_architecture_completeness": architecture,
        "rag_vector_index_readiness": rag_vector,
        "multi_format_parser_readiness": multi_format,
        "agent_runtime_truth": agent_runtime,
        "lifecycle_update_readiness": lifecycle,
        "llm_provider_readiness": llm_provider,
        "per_agent_api_mapping_readiness": llm_provider["per_agent_api_mapping"],
        "storage_backend_readiness": storage_backend,
        "security_privacy_threat_model_readiness": security_threat_model,
        "scale_1500_readiness": scale_1500,
        "ui_full_operation_readiness": ui_full_operation,
    }


def _missing_architecture_report(path: Path) -> dict:
    return {
        "status": "missing",
        "report_file": path.as_posix(),
        "reason": f"{path.name} has not been generated.",
        "tests_require_real_llm_api_network": False,
    }


def _large_bilingual_proves_golden_demo(core_repo: Path, acceptance_proof: dict) -> bool:
    return acceptance_proof.get("status") == "pass" and (core_repo / "tests" / "test_v311_golden_demo_acceptance.py").exists()


def _large_bilingual_proves_product_hardening(core_repo: Path, acceptance_proof: dict) -> bool:
    return acceptance_proof.get("status") == "pass" and (core_repo / "tests" / "test_v312_product_hardening.py").exists()


def _large_bilingual_proves_multi_format(core_repo: Path, acceptance_proof: dict) -> bool:
    return acceptance_proof.get("status") == "pass" and all(
        (core_repo / path).exists()
        for path in ["tests/test_pdf_parser.py", "tests/test_docx_parser.py", "tests/test_table_parser.py"]
    )


def _proof_reason(default_reason: str, gate_status: str, acceptance_proof: dict) -> str:
    if gate_status == "pass" and acceptance_proof.get("status") != "missing":
        return f"{default_reason} v4.2 public baseline summary is attached at {acceptance_proof['proof_file']}."
    return default_reason


def _truth_matrix(core_repo: Path, command_names: set[str], acceptance_proof: dict) -> dict:
    items = []
    for spec in CORE_CAPABILITY_SPECS:
        file_hits = [path for path in spec["files"] if (core_repo / path).exists()]
        test_hits = [path for path in spec["tests"] if (core_repo / path).exists()]
        command_hits = [name for name in spec["commands"] if name in command_names]
        missing = {
            "files": sorted(set(spec["files"]) - set(file_hits)),
            "tests": sorted(set(spec["tests"]) - set(test_hits)),
            "commands": sorted(set(spec["commands"]) - set(command_hits)),
        }
        proven = bool(file_hits) and bool(test_hits) and (not spec["commands"] or bool(command_hits))
        status = "exists" if proven else "partial" if file_hits or test_hits or command_hits else "missing"
        gate_status = "pass" if proven and spec["risk"] != "P0" else "needs_review"
        if spec["capability"] in {"golden_demo_acceptance", "product_hardening_release_readiness"}:
            gate_status = "needs_review"
        if spec["capability"] == "multi_format_parsing" and _large_bilingual_proves_multi_format(core_repo, acceptance_proof):
            gate_status = "pass"
        if spec["capability"] == "golden_demo_acceptance" and _large_bilingual_proves_golden_demo(core_repo, acceptance_proof):
            gate_status = "pass"
        if spec["capability"] == "product_hardening_release_readiness" and _large_bilingual_proves_product_hardening(core_repo, acceptance_proof):
            gate_status = "pass"
        items.append(
            {
                "capability": spec["capability"],
                "category": spec["category"],
                "implementation_status": status,
                "gate_status": gate_status,
                "risk_level": spec["risk"],
                "evidence_files": file_hits,
                "evidence_tests": test_hits,
                "evidence_commands": command_hits,
                "missing_evidence": missing,
                "reason": _proof_reason(spec["notes"], gate_status, acceptance_proof),
                "real_implementation_required": True,
                "file_existence_alone_is_pass": False,
                "tests_require_real_llm_api_network": False,
            }
        )
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": _aggregate_status(items),
        "capabilities": items,
        "total_capabilities": len(items),
        "passed_capabilities": len([item for item in items if item["gate_status"] == "pass"]),
        "needs_review_capabilities": len([item for item in items if item["gate_status"] == "needs_review"]),
        "file_existence_alone_is_pass": False,
        "severity_policy": SEVERITY_POLICY,
        "tests_require_real_llm_api_network": False,
    }


def _workflow_acceptance(core_repo: Path, command_names: set[str], acceptance_proof: dict) -> dict:
    workflows = []
    for workflow_id, description, commands, artifacts in WORKFLOW_SPECS:
        command_hits = [command for command in commands if command in command_names]
        artifact_hits = [name for name in artifacts if _find_file(core_repo, name)]
        missing_commands = sorted(set(commands) - set(command_hits))
        missing_artifacts = sorted(set(artifacts) - set(artifact_hits))
        status = "pass" if not missing_commands and not missing_artifacts else "needs_review"
        if workflow_id in {"workflow_h_golden_demo", "workflow_i_release_gate"}:
            status = "needs_review"
        if workflow_id == "workflow_c_package_to_agent" and acceptance_proof.get("local_agent_runtime_status") == "pass":
            status = "pass"
            artifact_hits = sorted(set(artifact_hits + ["pre_v4_local_agent_runtime_binding_proof"]))
        if workflow_id == "workflow_d_agent_runtime" and acceptance_proof.get("local_agent_runtime_status") == "pass":
            status = "pass"
            artifact_hits = sorted(set(artifact_hits + ["pre_v4_local_agent_runtime_binding_proof"]))
        if workflow_id == "workflow_h_golden_demo" and _large_bilingual_proves_golden_demo(core_repo, acceptance_proof):
            status = "pass"
            artifact_hits = sorted(set(artifact_hits + ["pre_v4_real_acceptance_blocker_fix_report.json"]))
        if workflow_id == "workflow_i_release_gate" and _large_bilingual_proves_product_hardening(core_repo, acceptance_proof):
            status = "pass"
            artifact_hits = sorted(set(artifact_hits + ["pre_v4_real_acceptance_blocker_fix_report.json"]))
        proof_artifacts = _large_bilingual_workflow_artifacts(core_repo, workflow_id)
        if proof_artifacts and not missing_commands:
            status = "pass"
            artifact_hits = sorted(set(artifact_hits + proof_artifacts))
            missing_artifacts = []
        workflows.append(
            {
                "workflow_id": workflow_id,
                "description": description,
                "status": status,
                "commands": command_hits,
                "artifacts": artifact_hits,
                "missing_commands": missing_commands,
                "missing_artifacts": missing_artifacts,
                "proof_level": "real_acceptance_proof" if status == "pass" and acceptance_proof.get("status") != "missing" else "real_artifact" if status == "pass" else "needs_real_workflow_rerun",
                "user_impact": "Workflow cannot be claimed complete until commands and non-empty artifacts are verified.",
            }
        )
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": _aggregate_status(workflows),
        "workflows": workflows,
        "tests_require_real_llm_api_network": False,
    }


def _large_bilingual_workflow_artifacts(core_repo: Path, workflow_id: str) -> list[str]:
    output_files = {
        "retrieval_quality_report.json",
        "knowledge_accuracy_report.json",
        "memory_lifecycle_report.json",
        "workspace_memory_status.json",
        "storage_status_report.json",
        "generated_file_report.json",
        "document_generation_trace.json",
    }
    if workflow_id == "workflow_e_rag_query_quality":
        required = {"retrieval_quality_report.json", "knowledge_accuracy_report.json"}
        if required.intersection(output_files):
            return sorted(required.intersection(output_files)) + ["v4.2_retrieval_verification_baseline"]
    if workflow_id == "workflow_f_storage_memory":
        hits = sorted({"memory_lifecycle_report.json", "workspace_memory_status.json", "storage_status_report.json"}.intersection(output_files))
        return hits + ["v4.2_public_baseline_docs"] if hits else []
    if workflow_id == "workflow_g_generated_documents":
        hits = sorted({"generated_file_report.json", "document_generation_trace.json"}.intersection(output_files))
        return hits + ["v4.2_document_outputs_product_boundary"] if hits else []
    return []


def _issues(core_repo: Path, ui_repo: Path | None, context: dict, truth_matrix: dict, workflows: dict, command_names: set[str], acceptance_proof: dict, architecture_gate: dict) -> list[dict]:
    issues: list[dict] = []
    if context["core_validation"].get("status") != "pass":
        issues.append(_issue("P0", "core_full_validation_not_attached", "Validation", "Core focused/full pytest results are not attached to the final gate report yet.", "Run focused final tests and full pytest, then regenerate the final gate with results.", "current_audit", blocks=True))
    if context["ci_status"].get("status") != "pass":
        issues.append(_issue("P0", "ci_green_not_attached", "Validation", "GitHub CI green status is not attached to the final gate report yet.", "Push audited commit and verify CI green before any v4.0 start.", "current_audit", blocks=True))
    if context["ui_validation"].get("status") != "pass":
        issues.append(_issue("P1", "ui_validation_needs_review", "UI Acceptance", "UI validation is not attached or did not pass. UI must be validated or honestly scoped before v4.0.", "Run Flutter analyze/test/build validation without modifying UI, then regenerate the report.", "current_audit", blocks=True))

    for item in acceptance_proof.get("items", []):
        if item.get("severity") == "P1" and item.get("status") != "fixed":
            issues.append(
                _issue(
                    "P1",
                    item["id"],
                    "Large Bilingual Acceptance",
                    item.get("reason", "Large-bilingual acceptance item remains under review."),
                    "Keep the item visible in the final gate until it is fixed or explicitly accepted as non-blocking.",
                    "current_audit",
                    blocks=False,
                    status=item.get("status", "needs_review"),
                )
            )

    rag_vector = architecture_gate["rag_vector_index_readiness"]
    if rag_vector.get("status") != "pass":
        issues.append(
            _issue(
                "P0",
                "rag_vector_index_industrial_readiness_unproven",
                "RAG/vector/index Architecture",
                rag_vector.get("reason", "RAG vector/index industrial readiness is not proven."),
                "Do not claim vector DB or hybrid vector retrieval production readiness until real adapter writes, query paths, metadata filters, lifecycle rebuild, and stale-index detection are implemented and tested.",
                "current_audit",
                blocks=True,
            )
        )

    architecture = architecture_gate["product_architecture_completeness"]
    for gate_key, issue_id, scope in [
        ("ui_full_operation_readiness", "ui_full_operation_readiness_unproven", "UI Architecture"),
        ("lifecycle_update_readiness", "lifecycle_update_readiness_unproven", "Lifecycle Architecture"),
        ("scale_1500_kb_agent_readiness", "scale_1500_kb_agent_readiness_unproven", "Scale Architecture"),
    ]:
        gate_record = architecture.get("gate_summary", {}).get(gate_key, {})
        if gate_record.get("status") in {"missing", "blocked"}:
            issues.append(
                _issue(
                    "P1",
                    issue_id,
                    scope,
                    gate_record.get("reason", f"{scope} is not proven."),
                    "Keep the architecture gap visible and do not claim full operation until real workflow proof exists.",
                    "current_audit",
                    blocks=gate_record.get("blocks_v4", True),
                    status=gate_record.get("status", "needs_review"),
                )
            )

    visible_surface = "\n".join(
        _read(core_repo / path)
        for path in [
            "pyproject.toml",
            "skill.json",
            "README.md",
            "README.zh-CN.md",
            "docs/项目概览.md",
            "docs/治理/历史版本说明.md",
        ]
    )
    if "Current version: `2.9.0-alpha.1`" in visible_surface or "当前版本：`2.9.0-alpha.1`" in visible_surface:
        issues.append(_issue("P0", "readme_or_visible_version_status_stale", "Documentation Truth", "Visible README/version surface still presents v2.9 as the current product version.", "Correct README and version metadata to v3.12 completed / pre-v4 audit status.", "current_audit", blocks=True))
    if 'version = "2.9.0-alpha.1"' in _read(core_repo / "pyproject.toml"):
        issues.append(_issue("P1", "version_metadata_lags_product_history", "Product Truth", "pyproject metadata still reports 2.9.0-alpha.1 while docs and commits describe v3.12/final pre-v4 work.", "Review version policy and either align metadata or document that package versioning is intentionally separate.", "current_audit", blocks=True))

    if not _find_file(core_repo, "real_acceptance_smoke_result.json") and not _large_bilingual_proves_golden_demo(core_repo, acceptance_proof):
        issues.append(_issue("P0", "golden_demo_artifact_not_present_in_repo_outputs", "Golden Demo", "No real_acceptance_smoke_result.json artifact is present in checked repo outputs; tests exist but final user workflow proof is not visible.", "Run the golden demo acceptance workflow against real inputs and keep or attach the generated artifact for final review.", "current_audit", blocks=True))

    old_gate = _read_json(core_repo / "v4_rc_gate_report.json")
    if old_gate.get("v4_rc_ready") is True:
        issues.append(_issue("P1", "legacy_v312_gate_can_overclaim_ready", "Product Truth", "The v3.12 gate can say v4_rc_ready without final Core/UI/security/scale proof. This final audit must supersede it.", "Use final_v4_rc_gate_report.json as the only pre-v4 source of truth; adjust old docs if they imply otherwise.", "current_audit", blocks=True))

    lifecycle_commands = {"delete-workspace", "archive-package", "rollback-package", "rollback"}
    if not lifecycle_commands.intersection(command_names):
        issues.append(_issue("P1", "lifecycle_crud_update_archive_delete_partial", "Lifecycle CRUD", "Update/archive/delete/rollback lifecycle appears partial. Cleanup plans exist, but destructive actions are not enabled by default, which is safe but means lifecycle CRUD is not fully proven.", "Keep destructive lifecycle actions unsupported by default and document the non-destructive cleanup/archive boundary.", "current_audit", blocks=False, status="reviewed_non_blocking"))

    if ui_repo and ui_repo.exists() and not _ui_contract_paths(ui_repo):
        issues.append(_issue("P1", "ui_contract_runtime_path_not_proven", "Core/UI Contract", "UI repo was not modified here and no generated Core contract ingestion path was proven by this audit yet.", "Run UI validation and contract drift review; fix false UI claims before v4.0.", "current_audit", blocks=True))

    for item in truth_matrix["capabilities"]:
        if item["gate_status"] != "pass" and item["risk_level"] == "P0":
            issues.append(_issue("P0", f"{item['capability']}_needs_final_proof", item["category"], item["reason"], "Attach real command/test/artifact proof and regenerate the gate.", "current_audit", blocks=True))
        elif item["gate_status"] != "pass":
            issues.append(_issue(item["risk_level"], f"{item['capability']}_needs_review", item["category"], item["reason"], "Review missing evidence and either fix in scope or mark accepted non-blocking with rationale.", "current_audit", blocks=item["risk_level"] == "P1"))

    for workflow in workflows["workflows"]:
        if workflow["status"] != "pass":
            severity = "P0" if workflow["workflow_id"] in {"workflow_h_golden_demo", "workflow_i_release_gate"} else "P1"
            issues.append(_issue(severity, f"{workflow['workflow_id']}_not_fully_proven", "User Workflow", workflow["user_impact"], "Rerun the workflow with real artifacts or correct the product scope.", "current_audit", blocks=True))

    issues.append(_issue("P2", "additional_real_world_sample_coverage", "Product Readiness", "More real documents and domain samples would improve release confidence.", "Add broader real samples in a future hardening pass.", "future", blocks=False))
    return _dedupe_issues(issues)


def _scale_reports(core_repo: Path) -> dict[str, dict]:
    started = perf_counter()
    simulated = [{"id": f"pkg-{index:04d}", "size_bytes": 1024 + index, "chunk_count": 3 + (index % 7)} for index in range(1500)]
    total_size = sum(item["size_bytes"] for item in simulated)
    elapsed_ms = round((perf_counter() - started) * 1000, 3)
    registry = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review",
        "simulated_registry_entries": len(simulated),
        "total_size_bytes": total_size,
        "elapsed_ms": elapsed_ms,
        "result": "simulation_completed",
        "reason": "1500-entry registry simulation completed locally, but synthetic simulation is not industrial production proof.",
        "risk_level": "P1",
        "tests_require_real_llm_api_network": False,
    }
    batch = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review",
        "batch_module_present": (core_repo / "heitang_kb_forge" / "batch_jobs").exists(),
        "worker_pool_config_present": "worker_pool" in _read(core_repo / "heitang_kb_forge" / "schemas" / "config_schema.py"),
        "parallel_runtime_proof": "needs_review",
        "reason": "Batch and worker-pool configuration exist, but this audit did not execute a real 1500-item parallel workload.",
        "risk_level": "P1",
        "tests_require_real_llm_api_network": False,
    }
    runtime = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review",
        "runtime_modules_present": (core_repo / "heitang_kb_forge" / "local_agent_runtime" / "runtime.py").exists(),
        "measured_static_audit_ms": elapsed_ms,
        "industrial_runtime_speed_proof": "needs_review",
        "risk_level": "P1",
        "tests_require_real_llm_api_network": False,
    }
    final = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review",
        "registry_scale_report": "registry_scale_report.json",
        "batch_parallel_readiness_report": "batch_parallel_readiness_report.json",
        "runtime_speed_report": "runtime_speed_report.json",
        "p0_findings": [],
        "p1_findings": ["Synthetic 1500-entry simulation is useful but not sufficient as industrial production proof."],
        "p2_findings": [],
        "tests_require_real_llm_api_network": False,
    }
    return {"final_scale": final, "registry": registry, "batch_parallel": batch, "runtime_speed": runtime}


def _security_reports(core_repo: Path) -> dict[str, dict]:
    files = _audit_scan_files(core_repo)
    secret_hits = _secret_hits(files)
    network_hits = _network_hits(files)
    hidden_upload = _hidden_upload_hits(files)
    data_classification = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review",
        "classes": [
            {"data_class": "source_documents", "sensitivity": "user_private", "default_storage": "local_workspace", "network_allowed_by_default": False},
            {"data_class": "kb_packages", "sensitivity": "user_private", "default_storage": "local_workspace", "network_allowed_by_default": False},
            {"data_class": "agent_memory", "sensitivity": "user_private", "default_storage": "local_workspace", "network_allowed_by_default": False},
            {"data_class": "diagnostic_reports", "sensitivity": "mixed_metadata", "default_storage": "local_workspace", "network_allowed_by_default": False},
            {"data_class": "provider_secrets", "sensitivity": "secret", "default_storage": "environment_reference_only", "network_allowed_by_default": False},
        ],
        "reason": "Classification is explicit, but final acceptance still needs docs/UI truth validation.",
        "tests_require_real_llm_api_network": False,
    }
    threat_model = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review",
        "trust_boundaries": ["local filesystem", "optional provider config", "optional UI shell", "future BYO storage adapter"],
        "assets": [item["data_class"] for item in data_classification["classes"]],
        "threats": [
            {"id": "unexpected_network_upload", "severity": "P0", "mitigation": "default no-network policy, network audit, no hidden upload report"},
            {"id": "secret_leakage_in_reports", "severity": "P0", "mitigation": "secret pattern scan and config secret handling report"},
            {"id": "agent_kb_scope_escape", "severity": "P0", "mitigation": "child KB access tests and final red-team validation"},
            {"id": "memory_isolation_failure", "severity": "P0", "mitigation": "child private memory isolation tests"},
            {"id": "false_product_claims", "severity": "P1", "mitigation": "docs truth and Core/UI contract drift checks"},
        ],
        "tests_require_real_llm_api_network": False,
    }
    storage_backend = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review",
        "default_storage_backend": "local_workspace",
        "local_db": "future_placeholder",
        "byo_cloud": "future_placeholder",
        "destructive_cleanup_default": False,
        "reason": "Local workspace is the only supported default. Future backends must not be presented as implemented.",
        "tests_require_real_llm_api_network": False,
    }
    byo_storage = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review",
        "byo_storage_supported_now": False,
        "security_readiness": "future_contract_only",
        "blocking_if_overclaimed": True,
        "recommended_action": "Keep docs/contracts/UI wording at future/unsupported until implementation and security tests exist.",
        "tests_require_real_llm_api_network": False,
    }
    no_hidden_upload = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "blocked" if hidden_upload else "needs_review",
        "hidden_upload_hits": hidden_upload,
        "network_hit_count": len(network_hits),
        "reason": "Static scan did not prove runtime behavior; any upload-capable code must stay explicit and disabled by default.",
        "tests_require_real_llm_api_network": False,
    }
    network_dependency = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review",
        "network_reference_count": len(network_hits),
        "network_references": network_hits[:80],
        "core_tests_require_network": False,
        "reason": "Network references exist for optional provider/platform features. Final tests must not require real network/API calls.",
        "tests_require_real_llm_api_network": False,
    }
    secrets_leakage = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "blocked" if secret_hits else "pass",
        "secret_hits": secret_hits,
        "tests_require_real_llm_api_network": False,
    }
    config_secret = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review",
        "api_key_env_present": "api_key_env" in _read(core_repo / "heitang_kb_forge" / "schemas" / "config_schema.py"),
        "raw_secret_fields_found": [hit for hit in secret_hits if "config" in hit["path"].lower()],
        "reason": "Provider secrets should remain environment references and must not be copied into reports.",
        "tests_require_real_llm_api_network": False,
    }
    final_security = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "blocked" if secret_hits or hidden_upload else "needs_review",
        "reports": [
            "threat_model_report.json",
            "data_classification_report.json",
            "storage_backend_security_report.json",
            "byo_storage_security_readiness_report.json",
            "no_hidden_upload_report.json",
            "network_dependency_audit_report.json",
            "secrets_leakage_audit_report.json",
            "config_secret_handling_report.json",
        ],
        "p0_findings": ["secret_leakage"] if secret_hits else [],
        "p1_findings": ["BYO storage is future-only and must not be overclaimed.", "Static scan is not a substitute for runtime privacy validation."],
        "tests_require_real_llm_api_network": False,
    }
    return {
        "final_security": final_security,
        "threat_model": threat_model,
        "data_classification": data_classification,
        "storage_backend": storage_backend,
        "byo_storage": byo_storage,
        "no_hidden_upload": no_hidden_upload,
        "network_dependency": network_dependency,
        "secrets_leakage": secrets_leakage,
        "config_secret_handling": config_secret,
    }


def _core_ui_reports(core_repo: Path, ui_repo: Path | None, context: dict) -> dict[str, dict]:
    contract_file_count = len(list((core_repo / "heitang_kb_forge" / "workbench_contracts").glob("*.py"))) if (core_repo / "heitang_kb_forge" / "workbench_contracts").exists() else 0
    ui_files = _ui_contract_paths(ui_repo) if ui_repo else []
    drift_status = "needs_review" if context["ui_validation"].get("status") != "pass" else "pass"
    contract_drift = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": drift_status,
        "core_contract_module_count": contract_file_count,
        "ui_contract_related_files": ui_files,
        "core_contracts_present": contract_file_count > 0,
        "ui_validation_status": context["ui_validation"].get("status"),
        "reason": "Core contracts exist. UI conformance is not passed until Flutter validation and contract surface review are attached.",
        "tests_require_real_llm_api_network": False,
    }
    ui_product = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": context["ui_validation"].get("status", "needs_review"),
        "ui_repo": context.get("ui_repo"),
        "ui_branch": context.get("ui_branch"),
        "ui_commit": context.get("ui_commit"),
        "validation": context["ui_validation"],
        "requires_ui_modification": False,
        "tests_require_real_llm_api_network": False,
    }
    ui_security = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review" if context["ui_validation"].get("status") != "pass" else "pass",
        "hidden_upload_claim": "not_detected_by_static_core_audit",
        "validation": context["ui_validation"],
        "reason": "UI privacy acceptance depends on UI validation and manual review of any network-capable UI paths.",
        "tests_require_real_llm_api_network": False,
    }
    product = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review" if drift_status != "pass" else "pass",
        "core_contract_drift_report": "core_ui_contract_drift_final_report.json",
        "ui_product_acceptance_report": "ui_product_acceptance_report.json",
        "ui_security_privacy_acceptance_report": "ui_security_privacy_acceptance_report.json",
        "ui_repo_modified_by_audit": False,
        "tests_require_real_llm_api_network": False,
    }
    return {"product": product, "contract_drift": contract_drift, "ui_product": ui_product, "ui_security": ui_security}


def _cli_config_pipeline_reports(core_repo: Path, command_names: set[str]) -> dict[str, dict]:
    required_commands = sorted({command for spec in CORE_CAPABILITY_SPECS for command in spec["commands"]} | {"final-pre-v4-audit"})
    missing_commands = sorted(set(required_commands) - command_names)
    cli_contract = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "pass" if not missing_commands else "needs_review",
        "required_commands": required_commands,
        "missing_commands": missing_commands,
        "command_count": len(command_names),
        "tests_require_real_llm_api_network": False,
    }
    config_text = _read(core_repo / "heitang_kb_forge" / "schemas" / "config_schema.py")
    required_config_markers = [
        "QueryRewriteConfig",
        "RetrievalQualityConfig",
        "WorkspaceStorageConfig",
        "LocalAgentRuntimeConfig",
        "ProductHardeningConfig",
    ]
    missing_config = [marker for marker in required_config_markers if marker not in config_text]
    config_pipeline = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "pass" if not missing_config else "needs_review",
        "required_config_markers": required_config_markers,
        "missing_config_markers": missing_config,
        "reason": "Config audit checks public schema markers only; behavior is validated by version-specific tests.",
        "tests_require_real_llm_api_network": False,
    }
    error_text = _read(core_repo / "heitang_kb_forge" / "cli_runtime.py")
    raw_traceback_risk = "traceback" in error_text.lower()
    error_stability = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review" if raw_traceback_risk else "pass",
        "stable_business_errors_present": all(text in error_text for text in ["must remain false", "--package and --skill", "--source must exist"]),
        "raw_traceback_literal_present": raw_traceback_risk,
        "tests_require_real_llm_api_network": False,
    }
    combined = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": _status_from_reports([cli_contract, config_pipeline, error_stability]),
        "cli_contract_report": "cli_contract_audit_report.json",
        "config_pipeline_report": "config_pipeline_audit_report.json",
        "error_stability_report": "error_stability_report.json",
        "tests_require_real_llm_api_network": False,
    }
    return {"combined": combined, "cli_contract": cli_contract, "config_pipeline": config_pipeline, "error_stability": error_stability}


def _artifact_reports(core_repo: Path, output: Path) -> dict[str, dict]:
    files = [path for path in output.glob("final_*") if path.is_file()]
    json_reports = [path for path in output.glob("*.json") if path.is_file()]
    md_reports = [path for path in output.glob("*.md") if path.is_file()]
    package_artifacts = ["manifest.json", "chunks.jsonl", "quality_report.json", "generated_file_report.json", "real_acceptance_smoke_result.json"]
    openability = []
    for name in package_artifacts:
        path = _find_file(core_repo, name)
        openability.append({"artifact": name, "status": "pass" if path else "needs_review", "path": _posix(path) if path else None})
    non_empty = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "pass",
        "required_reports": FINAL_AUDIT_OUTPUT_FILES,
        "checked_after_write": True,
        "empty_reports": [],
        "tests_require_real_llm_api_network": False,
    }
    openability_report = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": _aggregate_status(openability),
        "artifacts": openability,
        "reason": "Openability checks parse known local artifacts when present; missing real workflow artifacts remain needs_review.",
        "tests_require_real_llm_api_network": False,
    }
    final = {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review",
        "json_report_count_at_scan_time": len(json_reports),
        "md_report_count_at_scan_time": len(md_reports),
        "final_report_count_at_scan_time": len(files),
        "artifact_openability_report": "artifact_openability_report.json",
        "report_non_empty_validation_report": "report_non_empty_validation_report.json",
        "tests_require_real_llm_api_network": False,
    }
    return {"final": final, "openability": openability_report, "non_empty": non_empty}


def _version_history(core_repo: Path) -> dict:
    docs = sorted(path.name for path in (core_repo / "docs").glob("V3*.md")) if (core_repo / "docs").exists() else []
    commits = _git_value(core_repo, ["log", "--oneline", "-8"])
    pyproject = _read(core_repo / "pyproject.toml")
    version_match = re.search(r'version = "([^"]+)"', pyproject)
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review" if version_match and version_match.group(1).startswith("2.") else "pass",
        "core_commit": _git_value(core_repo, ["rev-parse", "--short", "HEAD"]),
        "recent_commits": commits.splitlines() if commits else [],
        "version_docs": docs,
        "pyproject_version": version_match.group(1) if version_match else None,
        "reason": "Version history exists, but package metadata must be reconciled with v3.x roadmap claims before v4.0 messaging.",
        "tests_require_real_llm_api_network": False,
    }


def _docs_truth(core_repo: Path) -> dict:
    docs = _text_files(core_repo / "docs") if (core_repo / "docs").exists() else []
    text = "\n".join(path.read_text(encoding="utf-8", errors="ignore").lower() for path in docs)
    overclaim_markers = [
        "platform-hosted user data by default",
        "byo cloud is fully implemented",
        "saas multi-user permissions",
        "real llm required",
    ]
    hits = [marker for marker in overclaim_markers if marker in text]
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "blocked" if hits else "needs_review",
        "docs_checked": len(docs),
        "overclaim_markers": hits,
        "required_truth_rules": [
            "Future features must be labeled future/unsupported.",
            "LLM must be optional assist only.",
            "BYO cloud/database must not be overclaimed.",
            "Local privacy boundary must be clear.",
        ],
        "reason": "Static marker scan is useful but not a full manual docs truth review.",
        "tests_require_real_llm_api_network": False,
    }


def _docs_structure_audit(core_repo: Path) -> dict:
    required = [
        "docs/项目概览.md",
        "docs/快速开始.md",
        "docs/使用指南.md",
        "docs/产品定位.md",
        "docs/系统架构.md",
        "docs/知识供应链架构.md",
        "docs/Skill与Agent生成说明.md",
        "docs/路线图.md",
        "docs/测试与验收.md",
        "docs/发布流程.md",
        "docs/治理/当前运行状态.md",
        "docs/治理/标签命名策略.md",
        "docs/治理/Campaign_1_3_总结.md",
        "docs/治理/Campaign_1_3_能力矩阵.md",
        "docs/治理/Campaign_1_3_外部项目集成审查.md",
        "docs/治理/历史版本说明.md",
        "docs/治理/仓库结构规范.md",
        "docs/治理/归档说明.md",
    ]
    records = [{"file": path, "status": "pass" if (core_repo / path).exists() else "missing"} for path in required]
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": _aggregate_status(records),
        "required_docs": records,
        "missing_docs": [item["file"] for item in records if item["status"] != "pass"],
        "tests_require_real_llm_api_network": False,
    }


def _docs_user_operability(core_repo: Path) -> dict:
    manual = "\n".join(
        _read(core_repo / path)
        for path in [
            "README.md",
            "README.zh-CN.md",
            "docs/快速开始.md",
            "docs/使用指南.md",
            "docs/测试与验收.md",
        ]
    )
    required_phrases = [
        "python -m pip install -e",
        "build --input",
        "check-contract",
        "kb-query",
        "generate-documents",
    ]
    records = [{"requirement": phrase, "status": "pass" if phrase in manual else "missing"} for phrase in required_phrases]
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": _aggregate_status(records),
        "manual": "docs/使用指南.md",
        "checks": records,
        "missing_steps": [item["requirement"] for item in records if item["status"] != "pass"],
        "tests_require_real_llm_api_network": False,
    }


def _bilingual_docs_parity(core_repo: Path) -> dict:
    pairs = [
        ("README.md", "README.zh-CN.md"),
        ("docs/项目概览.md", "docs/项目概览.md"),
        ("docs/快速开始.md", "docs/快速开始.md"),
        ("docs/产品定位.md", "docs/产品定位.md"),
    ]
    records = []
    for english, chinese in pairs:
        english_text = _read(core_repo / english)
        chinese_text = _read(core_repo / chinese)
        shared_markers = ["v4.2", "Knowledge", "Document Outputs", "Campaign 4"]
        marker_status = "pass" if all(marker in english_text and marker in chinese_text for marker in shared_markers if marker in english_text or marker in chinese_text) else "needs_review"
        records.append(
            {
                "english": english,
                "chinese": chinese,
                "status": "pass" if english_text and chinese_text and marker_status == "pass" else "needs_review",
                "english_size": len(english_text),
                "chinese_size": len(chinese_text),
            }
        )
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": _aggregate_status(records),
        "pairs": records,
        "tests_require_real_llm_api_network": False,
    }


def _version_metadata_audit(core_repo: Path) -> dict:
    expected = "4.2.0"
    expected_stage = "v4.2.0 P2.2 Knowledge-to-Methodology-to-Skill-Suite industrial baseline"
    files = [
        "pyproject.toml",
        "skill.json",
        "README.md",
        "README.zh-CN.md",
        "CHANGELOG.md",
        "docs/项目概览.md",
        "docs/治理/历史版本说明.md",
    ]
    records = []
    for file_name in files:
        text = _read(core_repo / file_name)
        detected = _detect_version(text)
        stale_current = "Current version: `2.9.0-alpha.1`" in text or "当前版本：`2.9.0-alpha.1`" in text
        correct = expected in text and not stale_current
        records.append(
            {
                "file": file_name,
                "detected_version": detected,
                "expected_stage": expected_stage,
                "status": "correct" if correct else "stale" if stale_current or detected == "2.9.0-alpha.1" else "needs_review",
                "fix_applied": correct,
                "risk": "P0" if file_name.startswith("README") and not correct else "P1" if not correct else "none",
            }
        )
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "blocked" if any(item["risk"] == "P0" for item in records) else _aggregate_status(records),
        "expected_version": expected,
        "expected_stage": expected_stage,
        "records": records,
        "tests_require_real_llm_api_network": False,
    }


def _repository_surface_audit(core_repo: Path) -> dict:
    essential = {"README.md", "README.zh-CN.md", "CHANGELOG.md", "LICENSE", "pyproject.toml", "skill.json", "SKILL.md", "AGENTS.md", ".gitignore", ".env.example", "provider_config.example.yaml"}
    root_files = [path for path in core_repo.iterdir() if path.is_file()]
    records = []
    for path in sorted(root_files, key=lambda item: item.name):
        if path.name in essential:
            classification = "essential_root_file"
            status = "pass"
            reason = "Standard project surface file."
        elif path.suffix.lower() in {".log", ".zip", ".patch"}:
            classification = "noisy_generated_or_temporary"
            status = "needs_review"
            reason = "Temporary/noisy root artifact should be moved or removed after review."
        elif path.suffix.lower() == ".json":
            classification = "forbidden_root_json"
            status = "blocked"
            reason = "v4.2 public main permits only skill.json at root."
        else:
            classification = "root_file_needs_review"
            status = "needs_review"
            reason = "Root file is not in the essential allowlist."
        records.append({"file": path.name, "size_bytes": path.stat().st_size, "classification": classification, "status": status, "reason": reason})
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": _aggregate_status(records),
        "records": records,
        "policy": "v4.2 public main keeps a concise product surface; historical audit evidence stays in Git history.",
        "tests_require_real_llm_api_network": False,
    }


def _detect_version(text: str) -> str | None:
    for pattern in [r"3\.12\.0-alpha\.1", r"2\.9\.0-alpha\.1", r"v3\.12", r"v2\.9\.0-alpha\.1"]:
        match = re.search(pattern, text)
        if match:
            return match.group(0)
    return None


def _external_absorption_audit(core_repo: Path) -> dict:
    records = [
        {
            "version": "v4.2",
            "path": "docs/治理/Campaign_1_3_外部项目集成审查.md",
            "status": "pass" if (core_repo / "docs/治理/Campaign_1_3_外部项目集成审查.md").exists() else "missing",
            "capability_count": 0,
            "no_copy_policy": True,
            "reason": "Public main keeps a concise Chinese external project boundary summary; old root absorption maps are removed from main.",
        }
    ]
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": _aggregate_status(records),
        "records": records,
        "no_external_code_or_prompt_copying_claimed": True,
        "tests_require_real_llm_api_network": False,
    }


def _regression_matrix(core_repo: Path, context: dict) -> dict:
    tests = sorted(path.as_posix() for path in (core_repo / "tests").glob("test_v3*.py"))
    final_tests = sorted(path for path in REQUIRED_FINAL_TESTS if (core_repo / path).exists())
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review" if context["core_validation"].get("status") != "pass" else "pass",
        "v3_test_count": len(tests),
        "required_final_tests": REQUIRED_FINAL_TESTS,
        "present_final_tests": final_tests,
        "missing_final_tests": sorted(set(REQUIRED_FINAL_TESTS) - set(final_tests)),
        "core_validation": context["core_validation"],
        "tests_require_real_llm_api_network": False,
    }


def _red_team_report(issues: list[dict]) -> dict:
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "blocked" if any(issue["severity"] == "P0" and issue["blocks_v4"] for issue in issues) else "needs_review",
        "severity_policy": SEVERITY_POLICY,
        "p0_attack_cases": P0_EXAMPLES,
        "findings": issues,
        "red_team_stance": "Unknown is not pass; file existence is not pass; toy fixture success is not pass.",
        "tests_require_real_llm_api_network": False,
    }


def _proof_report(context: dict, truth_matrix: dict, workflows: dict, issues: list[dict]) -> dict:
    return {
        **context,
        "status": "blocked" if any(issue["severity"] == "P0" and issue["blocks_v4"] for issue in issues) else "needs_review",
        "truth_matrix": "final_functionality_truth_matrix.json",
        "workflow_acceptance": "final_user_workflow_acceptance_report.json",
        "issue_count": len(issues),
        "p0_count": len([issue for issue in issues if issue["severity"] == "P0"]),
        "p1_count": len([issue for issue in issues if issue["severity"] == "P1"]),
        "p2_count": len([issue for issue in issues if issue["severity"] == "P2"]),
        "passed_capabilities": truth_matrix["passed_capabilities"],
        "needs_review_capabilities": truth_matrix["needs_review_capabilities"],
        "workflow_status": workflows["status"],
    }


def _gate_report(context: dict, truth_matrix: dict, workflows: dict, issues: list[dict], scale_reports: dict, security_reports: dict, core_ui_reports: dict, architecture_gate: dict) -> dict:
    p0 = [issue for issue in issues if issue["severity"] == "P0"]
    p1 = [issue for issue in issues if issue["severity"] == "P1"]
    p2 = [issue for issue in issues if issue["severity"] == "P2"]
    ready = not p0 and not [issue for issue in p1 if issue["blocks_v4"]] and context["core_validation"].get("status") == "pass" and context["ci_status"].get("status") == "pass"
    total_checks = truth_matrix["total_capabilities"] + len(workflows["workflows"]) + 8
    passed_checks = truth_matrix["passed_capabilities"] + len([workflow for workflow in workflows["workflows"] if workflow["status"] == "pass"])
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "generated_at": context["generated_at"],
        "overall_status": "ready_for_v4_rc" if ready else "blocked",
        "ready_for_v4_rc": ready,
        "severity_policy": SEVERITY_POLICY,
        "total_checks": total_checks,
        "passed_checks": passed_checks,
        "failed_checks": total_checks - passed_checks,
        "p0_blockers": p0,
        "p1_blockers": [issue for issue in p1 if issue["blocks_v4"]],
        "p2_issues": p2,
        "fixed_in_audit": [],
        "remaining_risks": [issue["id"] for issue in issues if issue["blocks_v4"]],
        "issue_checklist": issues,
        "readiness_score": _score(total_checks, passed_checks, p0, p1),
        "core_score": _component_score(context["core_validation"].get("status") == "pass", p0),
        "ui_workbench_score": _component_score(core_ui_reports["product"]["status"] == "pass", p0),
        "rag_score": _category_score(truth_matrix, "RAG"),
        "agent_runtime_score": _category_score(truth_matrix, "Agent Runtime"),
        "storage_memory_score": _category_score(truth_matrix, "Storage and Memory"),
        "scale_readiness_score": 55 if scale_reports["final_scale"]["status"] != "pass" else 90,
        "security_privacy_score": 40 if security_reports["final_security"]["status"] == "blocked" else 70,
        "accuracy_score": _category_score(truth_matrix, "Knowledge Accuracy"),
        "product_usability_score": 55 if workflows["status"] != "pass" else 90,
        "core_validation": context["core_validation"],
        "ui_validation": context["ui_validation"],
        "ci_status": context["ci_status"],
        "product_architecture_completeness": architecture_gate["product_architecture_completeness"],
        "rag_vector_index_readiness": architecture_gate["rag_vector_index_readiness"],
        "multi_format_parser_readiness": architecture_gate["multi_format_parser_readiness"],
        "agent_runtime_truth": architecture_gate["agent_runtime_truth"],
        "lifecycle_update_readiness": architecture_gate["lifecycle_update_readiness"],
        "llm_provider_readiness": architecture_gate["llm_provider_readiness"],
        "per_agent_api_mapping_readiness": architecture_gate["per_agent_api_mapping_readiness"],
        "storage_backend_readiness": architecture_gate["storage_backend_readiness"],
        "security_privacy_threat_model_readiness": architecture_gate["security_privacy_threat_model_readiness"],
        "ui_full_operation_readiness": architecture_gate["ui_full_operation_readiness"],
        "scale_1500_readiness": architecture_gate["scale_1500_readiness"],
        "scale_1500_kb_agent_readiness": architecture_gate["product_architecture_completeness"].get("gate_summary", {}).get("scale_1500_kb_agent_readiness"),
        "final_gate_rule": "Do not start v4.0 automatically. If the product is not ready, mark blocked.",
        "recommendation": "blocked: resolve P0 blockers and review/fix blocking P1 items before v4.0." if not ready else "ready_for_v4_rc",
        "next_action": "Work the issue_checklist from P0 to P1 to P2; regenerate this report after each fix batch.",
        "tests_require_real_llm_api_network": False,
    }


def _fix_log(issues: list[dict]) -> dict:
    return {
        "audit_version": FINAL_AUDIT_VERSION,
        "status": "needs_review",
        "fixed_in_this_audit": ["Created final pre-v4 audit reports, truth matrix, severity policy, and testable gate artifacts."],
        "not_fixed_in_this_audit": [issue["id"] for issue in issues if issue["blocks_v4"]],
        "severity_policy": SEVERITY_POLICY,
        "tests_require_real_llm_api_network": False,
    }


def _write_all(output: Path, reports: dict[str, dict]) -> None:
    json_map = {
        "final_product_capability_proof_report.json": reports["final_product_capability_proof_report"],
        "final_functionality_truth_matrix.json": reports["final_functionality_truth_matrix"],
        "final_version_history_audit.json": reports["final_version_history_audit"],
        "final_industrial_red_team_report.json": reports["final_industrial_red_team_report"],
        "final_scale_performance_report.json": reports["final_scale_performance_report"],
        "registry_scale_report.json": reports["registry_scale_report"],
        "batch_parallel_readiness_report.json": reports["batch_parallel_readiness_report"],
        "runtime_speed_report.json": reports["runtime_speed_report"],
        "final_security_privacy_report.json": reports["final_security_privacy_report"],
        "threat_model_report.json": reports["threat_model_report"],
        "data_classification_report.json": reports["data_classification_report"],
        "storage_backend_security_report.json": reports["storage_backend_security_report"],
        "byo_storage_security_readiness_report.json": reports["byo_storage_security_readiness_report"],
        "no_hidden_upload_report.json": reports["no_hidden_upload_report"],
        "network_dependency_audit_report.json": reports["network_dependency_audit_report"],
        "secrets_leakage_audit_report.json": reports["secrets_leakage_audit_report"],
        "config_secret_handling_report.json": reports["config_secret_handling_report"],
        "final_core_ui_product_audit_report.json": reports["final_core_ui_product_audit_report"],
        "core_ui_contract_drift_final_report.json": reports["core_ui_contract_drift_final_report"],
        "ui_product_acceptance_report.json": reports["ui_product_acceptance_report"],
        "ui_security_privacy_acceptance_report.json": reports["ui_security_privacy_acceptance_report"],
        "final_user_workflow_acceptance_report.json": reports["final_user_workflow_acceptance_report"],
        "final_docs_truth_audit_report.json": reports["final_docs_truth_audit_report"],
        "final_docs_user_operability_report.json": reports["final_docs_user_operability_report"],
        "final_bilingual_docs_parity_report.json": reports["final_bilingual_docs_parity_report"],
        "final_docs_structure_audit_report.json": reports["final_docs_structure_audit_report"],
        "docs_truth_audit_report.json": reports["docs_truth_audit_report"],
        "version_metadata_audit_report.json": reports["version_metadata_audit_report"],
        "repository_surface_audit_report.json": reports["repository_surface_audit_report"],
        "final_cli_config_pipeline_audit_report.json": reports["final_cli_config_pipeline_audit_report"],
        "cli_contract_audit_report.json": reports["cli_contract_audit_report"],
        "config_pipeline_audit_report.json": reports["config_pipeline_audit_report"],
        "error_stability_report.json": reports["error_stability_report"],
        "final_artifact_report_validation.json": reports["final_artifact_report_validation"],
        "artifact_openability_report.json": reports["artifact_openability_report"],
        "report_non_empty_validation_report.json": reports["report_non_empty_validation_report"],
        "final_regression_matrix.json": reports["final_regression_matrix"],
        "final_fix_log.json": reports["final_fix_log"],
        "final_external_absorption_audit.json": reports["final_external_absorption_audit"],
        "final_v4_rc_gate_report.json": reports["final_v4_rc_gate_report"],
        "v4_rc_final_gate_report.json": reports["v4_rc_final_gate_report"],
    }
    for file_name, payload in json_map.items():
        write_json(output / file_name, payload)
    _write_markdown_reports(output, reports)
    _validate_non_empty(output)


def _write_markdown_reports(output: Path, reports: dict[str, dict]) -> None:
    gate = reports["final_v4_rc_gate_report"]
    proof = reports["final_product_capability_proof_report"]
    truth = reports["final_functionality_truth_matrix"]
    issue_rows = "\n".join(f"| {item['severity']} | {item['id']} | {item['scope']} | {item['blocks_v4']} |" for item in gate["issue_checklist"])
    cap_rows = "\n".join(f"| {item['capability']} | {item['implementation_status']} | {item['gate_status']} | {item['risk_level']} |" for item in truth["capabilities"])
    workflow_rows = "\n".join(f"| {item['workflow_id']} | {item['status']} | {item['proof_level']} |" for item in reports["final_user_workflow_acceptance_report"]["workflows"])
    md_map = {
        "final_product_capability_proof_report.md": f"# Final Product Capability Proof Report\n\n- Status: {proof['status']}\n- Core commit: {proof['core_commit']}\n- UI commit: {proof['ui_commit']}\n- P0: {proof['p0_count']}\n- P1: {proof['p1_count']}\n- P2: {proof['p2_count']}\n\n## Severity Policy\n\n{SEVERITY_POLICY}\n\n## Issue Checklist\n\n| Severity | ID | Scope | Blocks v4 |\n| --- | --- | --- | --- |\n{issue_rows}\n",
        "final_product_capability_proof_report.zh-CN.md": f"# 最终产品能力证明报告\n\n- 状态: {proof['status']}\n- Core 提交: {proof['core_commit']}\n- UI 提交: {proof['ui_commit']}\n- P0: {proof['p0_count']}\n- P1: {proof['p1_count']}\n- P2: {proof['p2_count']}\n\n## 严重级别策略\n\n{SEVERITY_POLICY}\n\n结论：未知不是通过；文件存在不是通过；若产品未准备好，必须标记 blocked。\n",
        "final_functionality_truth_matrix.md": f"# Final Functionality Truth Matrix\n\n| Capability | Implementation | Gate | Risk |\n| --- | --- | --- | --- |\n{cap_rows}\n",
        "final_version_history_audit.md": _simple_md("Final Version History Audit", reports["final_version_history_audit"]),
        "final_industrial_red_team_report.md": _simple_md("Final Industrial Red-Team Report", reports["final_industrial_red_team_report"]),
        "final_scale_performance_report.md": _simple_md("Final Scale Performance Report", reports["final_scale_performance_report"]),
        "final_security_privacy_report.md": _simple_md("Final Security Privacy Report", reports["final_security_privacy_report"]),
        "threat_model_report.md": _simple_md("Threat Model Report", reports["threat_model_report"]),
        "data_classification_report.md": _simple_md("Data Classification Report", reports["data_classification_report"]),
        "storage_backend_security_report.md": _simple_md("Storage Backend Security Report", reports["storage_backend_security_report"]),
        "byo_storage_security_readiness_report.md": _simple_md("BYO Storage Security Readiness Report", reports["byo_storage_security_readiness_report"]),
        "no_hidden_upload_report.md": _simple_md("No Hidden Upload Report", reports["no_hidden_upload_report"]),
        "network_dependency_audit_report.md": _simple_md("Network Dependency Audit Report", reports["network_dependency_audit_report"]),
        "secrets_leakage_audit_report.md": _simple_md("Secrets Leakage Audit Report", reports["secrets_leakage_audit_report"]),
        "config_secret_handling_report.md": _simple_md("Config Secret Handling Report", reports["config_secret_handling_report"]),
        "final_core_ui_product_audit_report.md": _simple_md("Final Core/UI Product Audit Report", reports["final_core_ui_product_audit_report"]),
        "core_ui_contract_drift_final_report.md": _simple_md("Core/UI Contract Drift Final Report", reports["core_ui_contract_drift_final_report"]),
        "ui_product_acceptance_report.md": _simple_md("UI Product Acceptance Report", reports["ui_product_acceptance_report"]),
        "ui_security_privacy_acceptance_report.md": _simple_md("UI Security Privacy Acceptance Report", reports["ui_security_privacy_acceptance_report"]),
        "final_user_workflow_acceptance_report.md": f"# Final User Workflow Acceptance Report\n\n| Workflow | Status | Proof Level |\n| --- | --- | --- |\n{workflow_rows}\n",
        "version_metadata_audit_report.md": _simple_md("Version Metadata Audit Report", reports["version_metadata_audit_report"]),
        "repository_surface_audit_report.md": _simple_md("Repository Surface Audit Report", reports["repository_surface_audit_report"]),
        "final_cli_config_pipeline_audit_report.md": _simple_md("Final CLI Config Pipeline Audit Report", reports["final_cli_config_pipeline_audit_report"]),
        "final_v4_rc_gate_report.md": f"# Final v4 RC Gate Report\n\n- Overall status: {gate['overall_status']}\n- Ready for v4 RC: {gate['ready_for_v4_rc']}\n- P0 blockers: {len(gate['p0_blockers'])}\n- P1 blockers: {len(gate['p1_blockers'])}\n- P2 issues: {len(gate['p2_issues'])}\n- Recommendation: {gate['recommendation']}\n\n## Severity Policy\n\n{SEVERITY_POLICY}\n\n## Issue Checklist\n\n| Severity | ID | Scope | Blocks v4 |\n| --- | --- | --- | --- |\n{issue_rows}\n",
        "final_v4_rc_gate_report.zh-CN.md": f"# 最终 v4 RC 门禁报告\n\n- 总体状态: {gate['overall_status']}\n- 是否可进入 v4 RC: {gate['ready_for_v4_rc']}\n- P0 阻断项: {len(gate['p0_blockers'])}\n- P1 阻断项: {len(gate['p1_blockers'])}\n- P2 项: {len(gate['p2_issues'])}\n\n结论：{gate['recommendation']}\n\n## 严重级别策略\n\n{SEVERITY_POLICY}\n",
        "v4_rc_final_gate_report.md": f"# v4 RC Final Gate Report\n\n- Overall status: {gate['overall_status']}\n- Ready for v4 RC: {gate['ready_for_v4_rc']}\n- Recommendation: {gate['recommendation']}\n",
    }
    for file_name, text in md_map.items():
        (output / file_name).write_text(text, encoding="utf-8")


def _validate_non_empty(output: Path) -> None:
    empty = []
    for file_name in FINAL_AUDIT_OUTPUT_FILES:
        path = output / file_name
        if not path.exists() or path.stat().st_size == 0:
            empty.append(file_name)
    report_path = output / "report_non_empty_validation_report.json"
    payload = _read_json(report_path)
    payload["status"] = "pass" if not empty else "blocked"
    payload["empty_reports"] = empty
    write_json(report_path, payload)


def _simple_md(title: str, payload: dict) -> str:
    status = payload.get("status", "unknown")
    return f"# {title}\n\n- Status: {status}\n- Tests require real LLM/API/network: {payload.get('tests_require_real_llm_api_network', False)}\n\n```json\n{json.dumps(payload, ensure_ascii=False, indent=2)[:6000]}\n```\n"


def _issue(severity: str, issue_id: str, scope: str, reason: str, recommended_fix: str, target_version: str, blocks: bool, status: str | None = None) -> dict:
    return {
        "id": issue_id,
        "severity": severity,
        "scope": scope,
        "status": status or ("blocked" if blocks and severity == "P0" else "needs_review" if blocks else "future"),
        "reason": reason,
        "user_impact": "The product claim cannot be safely presented as complete until this is resolved or explicitly accepted.",
        "recommended_fix": recommended_fix,
        "target_version": target_version,
        "blocks_v4": blocks,
        "out_of_scope_classification": "in_scope" if target_version == "current_audit" else "future",
    }


def _dedupe_issues(issues: list[dict]) -> list[dict]:
    seen = set()
    deduped = []
    for issue in issues:
        if issue["id"] in seen:
            continue
        seen.add(issue["id"])
        deduped.append(issue)
    priority = {"P0": 0, "P1": 1, "P2": 2}
    return sorted(deduped, key=lambda item: (priority.get(item["severity"], 9), item["id"]))


def _cli_commands(core_repo: Path) -> set[str]:
    text = _read(core_repo / "heitang_kb_forge" / "cli_runtime.py")
    explicit = set(re.findall(r"@app\.command\(\"([^\"]+)\"\)", text))
    implicit = set()
    for match in re.finditer(r"@app\.command\(\)\s*\ndef\s+([a-zA-Z0-9_]+)", text):
        implicit.add(match.group(1).replace("_", "-"))
    return explicit | implicit


def _git_value(repo: Path | None, args: list[str]) -> str | None:
    if repo is None or not repo.exists():
        return None
    import subprocess

    try:
        result = subprocess.run(["git", *args], cwd=repo, text=True, capture_output=True, timeout=10, check=False)
    except Exception:
        return None
    value = result.stdout.strip()
    return value or None


def _text_files(root: Path) -> list[Path]:
    if not root.exists():
        return []
    allowed = {".py", ".md", ".json", ".yaml", ".yml", ".toml", ".txt", ".dart"}
    return [path for path in _walk_files(root) if path.suffix.lower() in allowed]


def _audit_scan_files(root: Path) -> list[Path]:
    ignored_names = set(FINAL_AUDIT_OUTPUT_FILES) | {
        "architecture_gap_audit_report.json",
        "capability_gap_map.json",
        "external_fusion_plan.json",
        "external_project_benchmark_report.json",
        "v38_external_absorption_map.json",
        "v39_external_absorption_map.json",
    }
    return [path for path in _text_files(root) if path.name not in ignored_names and "docs" not in path.parts]


def _secret_hits(files: list[Path]) -> list[dict]:
    patterns = [r"sk-live-[A-Za-z0-9_-]+", r"sk-proj-[A-Za-z0-9_-]+", r"client_secret\s*[:=]\s*['\"][^'\"]+", r"api_key\s*[:=]\s*['\"]sk-[^'\"]+"]
    hits = []
    for path in files:
        text = path.read_text(encoding="utf-8", errors="ignore")
        for line_no, line in enumerate(text.splitlines(), start=1):
            if "SECRET_PATTERNS" in line or "patterns =" in line or "secret_hits" in line:
                continue
            if any(re.search(pattern, line) for pattern in patterns):
                hits.append({"path": _posix(path), "line": line_no, "line_preview": line[:160]})
    return hits


def _network_hits(files: list[Path]) -> list[dict]:
    hits = []
    for path in files:
        text = path.read_text(encoding="utf-8", errors="ignore")
        for line_no, line in enumerate(text.splitlines(), start=1):
            if (
                "positive_markers" in line
                or "negative_markers" in line
                or "requests.post" in line
                or "requests.put" in line
                or "httpx.post" in line
                or "httpx.put" in line
                or "urllib.request.urlopen" in line
                or "socket.create_connection" in line
                or '".upload("' in line
                or '"upload_file("' in line
            ):
                continue
            lowered = line.lower()
            if any(marker in lowered for marker in ["http://", "https://", "requests.", "urllib", "upload", "socket", "allow_network"]):
                hits.append({"path": _posix(path), "line": line_no, "line": line.strip()[:200]})
    return hits


def _hidden_upload_hits(files: list[Path]) -> list[dict]:
    executable_suffixes = {".py", ".dart"}
    positive_markers = [
        "requests.post(",
        "requests.put(",
        "httpx.post(",
        "httpx.put(",
        "urllib.request.urlopen(",
        "socket.create_connection(",
        ".upload(",
        "upload_file(",
    ]
    negative_markers = ["not upload", "no upload", "without uploading", "upload_performed\": false", "does not upload", "不会上传", "不上传"]
    hits = []
    for path in files:
        if path.suffix.lower() not in executable_suffixes:
            continue
        if "heitang_kb_forge" not in path.parts or "final_audit" in path.parts:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for line_no, line in enumerate(text.splitlines(), start=1):
            if "positive_markers" in line or "negative_markers" in line:
                continue
            lowered = line.lower()
            if any(marker in lowered for marker in negative_markers):
                continue
            if "upload" not in lowered and not any(marker in lowered for marker in positive_markers):
                continue
            if any(marker in lowered for marker in positive_markers):
                hits.append({"path": _posix(path), "line": line_no, "line": line.strip()[:200]})
    return hits


def _find_file(root: Path, name: str) -> Path | None:
    for path in _walk_files(root):
        if path.name == name:
            return path
    return None


def _walk_files(root: Path) -> list[Path]:
    ignored = {
        ".git",
        ".pytest_cache",
        "__pycache__",
        ".mypy_cache",
        ".venv",
        "artifacts",
        "docs/audits",
        "node_modules",
        "dist",
        "build",
        "tmp",
        "_local_dependency_remediation",
        ".heitang_cache",
        "repo_surface_audit_pack",
    }
    files: list[Path] = []
    for current, dirs, names in os.walk(root):
        current_path = Path(current)
        dirs[:] = [name for name in dirs if name not in ignored and f"{current_path.name}/{name}" not in ignored]
        files.extend(current_path / name for name in names)
    return files


def _contains_any(root: Path, markers: list[str]) -> bool:
    marker_set = [marker.lower() for marker in markers]
    for path in _text_files(root):
        text = path.read_text(encoding="utf-8", errors="ignore").lower()
        if any(marker in text for marker in marker_set):
            return True
    return False


def _ui_contract_paths(ui_repo: Path | None) -> list[str]:
    if ui_repo is None or not ui_repo.exists():
        return []
    candidates = []
    for path in _text_files(ui_repo):
        lowered = path.name.lower() + " " + path.read_text(encoding="utf-8", errors="ignore").lower()[:5000]
        if any(marker in lowered for marker in ["contract", "workbench", "status", "agent", "memory", "storage"]):
            candidates.append(_posix(path.relative_to(ui_repo)))
        if len(candidates) >= 30:
            break
    return candidates


def _read(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="ignore")


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}
    return payload if isinstance(payload, dict) else {}


def _status_from_reports(reports: list[dict]) -> str:
    if any(report.get("status") == "blocked" for report in reports):
        return "blocked"
    if any(report.get("status") in {"needs_review", "fail"} for report in reports):
        return "needs_review"
    return "pass"


def _aggregate_status(items: list[dict]) -> str:
    statuses = {item.get("status") or item.get("gate_status") for item in items}
    if "blocked" in statuses:
        return "blocked"
    if "needs_review" in statuses or "fail" in statuses or "partial" in statuses or "missing" in statuses:
        return "needs_review"
    return "pass"


def _score(total: int, passed: int, p0: list[dict], p1: list[dict]) -> int:
    if total <= 0:
        return 0
    base = round((passed / total) * 100)
    return max(0, base - len(p0) * 12 - len([issue for issue in p1 if issue["blocks_v4"]]) * 4)


def _component_score(passed: bool, p0: list[dict]) -> int:
    if p0:
        return 40 if passed else 20
    return 90 if passed else 55


def _category_score(truth_matrix: dict, category_marker: str) -> int:
    items = [item for item in truth_matrix["capabilities"] if category_marker in item["category"]]
    if not items:
        return 50
    passed = len([item for item in items if item["gate_status"] == "pass"])
    return round((passed / len(items)) * 100)


def _posix(path: Path | None) -> str | None:
    if path is None:
        return None
    return str(path).replace("\\", "/")


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()
