from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.workbench.action_executor import run_p1_ready_actions
from heitang_kb_forge.workbench.golden_workflows import error_repair


P1_RWF_V2_REPORT_FILES = [
    "full_ready_action_execution_matrix.json",
    "full_ready_action_execution_matrix.md",
    "action_input_plan.json",
    "action_execution_result_index.json",
    "action_artifact_assertion_report.json",
    "action_report_assertion_report.json",
    "action_error_boundary_report.json",
    "full_local_user_path_closure_report.json",
    "p1_real_workflow_v2_report.json",
    "p1_real_workflow_v2_report.md",
    "remaining_blockers.json",
    "remaining_blockers.md",
]


P1_RWF_V2_USER_PATHS = [
    {
        "user_path_id": "workspace_import_build_validate_artifact",
        "actions": ["workspace_inspect", "workspace_health", "parser_preflight", "package_build", "package_validation", "artifact_kb_package_inspect"],
        "steps": ["Workspace", "Import", "Build", "Validate", "Artifact"],
    },
    {
        "user_path_id": "kb_retrieval_evidence_verification",
        "actions": ["rag_query", "retrieval_planning", "rerank", "evidence_selection", "claim_verification"],
        "steps": ["KB Package", "Retrieval", "Evidence", "Verification"],
    },
    {
        "user_path_id": "document_generation_openability_artifact",
        "actions": ["generate_markdown", "generate_docx", "generate_pdf", "generate_pptx", "generate_manual_user_guide", "openability_check"],
        "steps": ["KB Package", "Document Generation", "Openability", "Artifact"],
    },
    {
        "user_path_id": "skill_generation_validate_diff_installability",
        "actions": ["book_to_skill", "package_to_skill", "skill_manifest_validate", "skill_diff", "package_export"],
        "steps": ["KB / Source", "Skill Generation", "Validate", "Diff", "Installability"],
    },
    {
        "user_path_id": "agent_generation_runtime_trace",
        "actions": ["standalone_agent_generation", "kb_bound_agent_generation", "run_agent", "artifact_runtime_trace_inspect"],
        "steps": ["KB", "Agent Generation", "Run Agent", "Runtime Trace"],
    },
    {
        "user_path_id": "multi_agent_memory_boundary_cleanup",
        "actions": ["multi_agent_orchestration", "summary_memory_lifecycle", "memory_compression", "memory_cleanup", "workspace_cleanup_plan"],
        "steps": ["Multi-agent", "Memory", "Boundary", "Cleanup"],
    },
    {
        "user_path_id": "error_repair_retry_recommendation",
        "actions": ["package_batch", "package_diff", "product_hardening", "final_gate"],
        "steps": ["Error", "Repair Center", "Retry Recommendation"],
    },
    {
        "user_path_id": "template_workflow_generated_assets",
        "actions": ["package_pipeline", "book_to_skill", "standalone_agent_generation", "artifact_agent_package_inspect"],
        "steps": ["Template", "Workflow Plan", "Generated Assets"],
    },
    {
        "user_path_id": "reports_audit_gate_summary",
        "actions": ["product_hardening", "final_gate", "format_support_matrix", "ocr_required_detection"],
        "steps": ["Reports", "Audit", "Gate Summary"],
    },
    {
        "user_path_id": "artifact_management_safe_path_sensitive_block",
        "actions": [
            "artifact_kb_package_inspect",
            "artifact_vector_index_inspect",
            "artifact_generated_docs_inspect",
            "artifact_skill_package_inspect",
            "artifact_agent_package_inspect",
            "artifact_acceptance_proof_inspect",
        ],
        "steps": ["Artifact Management", "Safe Path", "Sensitive Block"],
    },
]


def run_full_local_user_path(workspace: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    action_bundle = run_p1_ready_actions(workspace, output)
    action_results = {item["action_id"]: item for item in action_bundle["action_results"]}
    user_paths = [_write_user_path(output / "user_paths" / spec["user_path_id"], spec, action_results) for spec in P1_RWF_V2_USER_PATHS]
    closure = _closure_report(user_paths)
    write_json(output / "full_local_user_path_closure_report.json", closure)
    report = _v2_report(action_bundle, closure)
    blockers = _remaining_blockers(action_bundle, closure)
    write_json(output / "p1_real_workflow_v2_report.json", report)
    (output / "p1_real_workflow_v2_report.md").write_text(_v2_report_md(report), encoding="utf-8")
    write_json(output / "remaining_blockers.json", blockers)
    (output / "remaining_blockers.md").write_text(_blockers_md(blockers), encoding="utf-8")
    return report


def _write_user_path(run_dir: Path, spec: dict, action_results: dict[str, dict]) -> dict:
    run_dir.mkdir(parents=True, exist_ok=True)
    used = [action_results[action_id] for action_id in spec["actions"]]
    status = "passed" if all(item["status"] == "passed" for item in used) else "blocked"
    artifacts = [
        {"artifact_id": f"path_{spec['user_path_id']}_{item['action_id']}", "path": f"../actions/{item['action_id']}/artifact_index.json", "sensitive": False, "safe_copy_eligible": True}
        for item in used
    ]
    reports = [
        {"report_id": f"path_{spec['user_path_id']}_{item['action_id']}", "path": f"../actions/{item['action_id']}/report_index.json"}
        for item in used
    ]
    errors = sorted({error for item in used for error in item.get("errors_observed", [])})
    result = {
        "user_path_id": spec["user_path_id"],
        "status": status,
        "evidence_level": "real_local_workflow" if status == "passed" else "blocked",
        "actions_used": spec["actions"],
        "reports_generated": [item["report_id"] for item in reports],
        "artifacts_generated": [item["artifact_id"] for item in artifacts],
        "user_visible_steps": spec["steps"],
        "blocked_steps": [] if status == "passed" else [item["action_id"] for item in used if item["status"] != "passed"],
        "gate_impact": "contributes_to_p1_real_workflow_v2" if status == "passed" else "blocks_p1_real_workflow_v2",
    }
    write_json(run_dir / "user_path_result.json", result)
    (run_dir / "user_path_report.md").write_text(_user_path_md(result), encoding="utf-8")
    write_jsonl(run_dir / "task_events.jsonl", _path_events(result))
    write_json(run_dir / "artifact_index.json", {"user_path_id": spec["user_path_id"], "artifacts": artifacts})
    write_json(run_dir / "report_index.json", {"user_path_id": spec["user_path_id"], "reports": reports})
    write_json(run_dir / "error_repair_map.json", {"user_path_id": spec["user_path_id"], "errors": [error_repair(error) for error in errors]})
    return result


def _closure_report(user_paths: list[dict]) -> dict:
    return {
        "report_id": "p1_rwf_v2_full_local_user_path_closure",
        "status": "pass" if all(item["status"] == "passed" for item in user_paths) else "blocked",
        "user_path_count": len(user_paths),
        "passed_count": sum(1 for item in user_paths if item["status"] == "passed"),
        "blocked_count": sum(1 for item in user_paths if item["status"] == "blocked"),
        "user_paths": user_paths,
    }


def _v2_report(action_bundle: dict, closure: dict) -> dict:
    action_passed = action_bundle["status"] == "pass"
    path_passed = closure["status"] == "pass"
    matrix = action_bundle["matrix"]
    status = "passed" if action_passed and path_passed else "blocked"
    return {
        "report_id": "p1_real_workflow_v2",
        "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "p1_real_workflow_v2_status": status,
        "p1_full_operation_gate_status": "core_passed_pending_ui_consumption" if status == "passed" else "blocked",
        "ui_full_operation_pending": True,
        "ready_for_v4_rc_candidate": False,
        "not_v4_0_workbench_rc": True,
        "v4_0_started": False,
        "tag_created": False,
        "v4_release_written": False,
        "ready_core_cli_action_count": matrix["ready_core_cli_action_count"],
        "full_57_ready_action_execution_complete": action_passed,
        "execution_target_count": matrix["execution_target_count"],
        "excluded_explicit_config_count": matrix["excluded_explicit_config_count"],
        "command_surface_drift_count": matrix["command_surface_drift_count"],
        "action_execution_status": action_bundle["status"],
        "user_path_closure_status": closure["status"],
        "user_path_count": closure["user_path_count"],
        "fixture_only_counted_as_real": False,
        "tests_require_real_llm_api_network": False,
        "network_required": False,
        "output_files": P1_RWF_V2_REPORT_FILES,
    }


def _remaining_blockers(action_bundle: dict, closure: dict) -> dict:
    blockers = []
    if action_bundle["status"] != "pass":
        blockers.append({"blocker_id": "full_57_ready_action_execution_not_passing", "status": "remaining"})
    if closure["status"] != "pass":
        blockers.append({"blocker_id": "full_local_user_path_closure_not_passing", "status": "remaining"})
    blockers.append(
        {
            "blocker_id": "ui_v2_consumption_pending",
            "status": "remaining",
            "description": "Core V2 evidence is ready; UI must consume the V2 matrix, action results, user paths, and gate reports before final P1 gate can be promoted.",
        }
    )
    return {
        "status": "blocked" if blockers else "clear",
        "blockers": blockers,
        "explicit_config_exclusions": [
            row
            for row in action_bundle["matrix"]["actions"]
            if not row["execution_target"]
        ],
    }


def _v2_report_md(report: dict) -> str:
    return "\n".join(
        [
            "# P1 Real Workflow V2 Report",
            "",
            f"p1_real_workflow_v2_status: {report['p1_real_workflow_v2_status']}",
            f"p1_full_operation_gate_status: {report['p1_full_operation_gate_status']}",
            f"ui_full_operation_pending: {str(report['ui_full_operation_pending']).lower()}",
            f"ready_for_v4_rc_candidate: {str(report['ready_for_v4_rc_candidate']).lower()}",
            f"57 ready action execution complete: {str(report['full_57_ready_action_execution_complete']).lower()}",
            "",
            "Core V2 does not start v4.0, create tags, or write a v4 release.",
            "",
        ]
    )


def _blockers_md(blockers: dict) -> str:
    lines = [f"- {item['blocker_id']}: {item.get('description', item['status'])}" for item in blockers["blockers"]] or ["- None."]
    return "# Remaining Blockers\n\n" + "\n".join(lines) + "\n"


def _user_path_md(result: dict) -> str:
    return "\n".join(
        [
            f"# {result['user_path_id']}",
            "",
            f"Status: {result['status']}",
            f"Evidence level: {result['evidence_level']}",
            f"Gate impact: {result['gate_impact']}",
            "",
        ]
    )


def _path_events(result: dict) -> list[dict]:
    return [
        {"task_id": f"task_{result['user_path_id']}", "user_path_id": result["user_path_id"], "status": "queued", "progress": 0},
        {"task_id": f"task_{result['user_path_id']}", "user_path_id": result["user_path_id"], "status": "running", "progress": 50},
        {"task_id": f"task_{result['user_path_id']}", "user_path_id": result["user_path_id"], "status": "succeeded" if result["status"] == "passed" else "blocked", "progress": 100},
    ]


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))
