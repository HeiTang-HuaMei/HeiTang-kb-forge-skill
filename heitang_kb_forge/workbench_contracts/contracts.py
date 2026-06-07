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
            {"id": "memory_policy", "label": "Memory Policy", "asset_types": ["report"]},
            {"id": "memory_writeback", "label": "Memory Writeback", "asset_types": ["report"]},
            {"id": "storage_status", "label": "Storage Status", "asset_types": ["storage", "report"]},
            {"id": "reports", "label": "Reports", "asset_types": ["report"]},
        ],
    }
    actions = {
        "workbench_action_contract_version": "3.4.0-alpha.1",
        "actions": [
            {"id": "build_package", "label": "Build Package", "command": "build", "requires": ["input", "output"]},
            {"id": "generate_documents", "label": "Generate Documents", "command": "generate-documents", "requires": ["package", "output"]},
            {"id": "generate_bound_agent", "label": "Generate Bound Agent", "command": "generate-bound-agent", "requires": ["package", "output"]},
            {"id": "create_standalone_agent", "label": "Create Standalone Agent", "command": "generate-agent --mode standalone", "requires": ["output"]},
            {"id": "create_kb_bound_agent", "label": "Create KB-bound Agent", "command": "generate-agent --mode kb_bound", "requires": ["package", "skill", "output"]},
            {"id": "validate_agent_package", "label": "Validate Agent Package", "command": "local-validation", "requires": ["agent"]},
            {"id": "run_agent_smoke_test", "label": "Run Agent Smoke Test", "command": "local-smoke-test", "requires": ["agent"]},
            {"id": "configure_agent_hierarchy", "label": "Configure Agent Hierarchy", "command": "orchestrate-multi-kb --mother-agent", "requires": ["mother_agent", "child_agents"]},
            {"id": "bind_child_agent", "label": "Bind Child Agent", "command": "orchestrate-multi-kb --agents", "requires": ["child_agent"]},
            {"id": "queue_memory_writeback", "label": "Queue Memory Writeback", "command": "orchestrate-multi-kb --parent-writeback", "requires": ["child_agent", "candidate"]},
            {"id": "review_memory_candidate", "label": "Review Memory Candidate", "command": "review-memory-candidate", "requires": ["candidate"]},
            {"id": "promote_memory_candidate", "label": "Promote Memory Candidate", "command": "promote-memory-candidate", "requires": ["candidate", "approval"]},
            {"id": "inspect_storage_status", "label": "Inspect Storage Status", "command": "workbench-contracts", "requires": ["core_output"]},
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
        ("generated_file_report.json", "report"),
        ("knowledge_bound_factory_manifest.json", "report"),
        ("multi_kb_orchestration_manifest.json", "report"),
        ("hierarchy_trace.json", "report"),
        ("memory_writeback_report.json", "report"),
        ("memory_promotion_report.json", "report"),
        ("memory_isolation_report.json", "report"),
        ("memory_lifecycle_report.json", "report"),
        ("skill_reverse_fusion_manifest.json", "report"),
        ("agent_manifest.json", "agent_package"),
        ("workbench_agent_contract.json", "report"),
        ("workbench_hierarchy_contract.json", "report"),
        ("workbench_memory_contract.json", "report"),
        ("workbench_storage_contract.json", "storage"),
        ("workbench_error_contract.json", "report"),
        ("skill_package/SKILL.md", "skill_package"),
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
        ],
        "trace_files": ["hierarchy_trace.json", "memory_writeback_report.json"],
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
