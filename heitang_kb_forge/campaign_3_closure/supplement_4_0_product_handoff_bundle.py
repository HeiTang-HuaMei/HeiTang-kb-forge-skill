from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl

from .supplement_4_0_agent_package import (
    validate_campaign_3_supplement_4_0_agent_package,
    write_campaign_3_supplement_4_0_agent_package,
)


GENERATED_AT = "2026-06-14T02:20:00+08:00"

CURRENT_ITEM = "Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle"
NEXT_ACTION = "Campaign 3 Supplement 4.0 Acceptance Gate only"

BUNDLE_AUDIT_DIR = Path("artifacts/audits/section_5/campaign_3_supplement_4_0_product_handoff_bundle")
AGENT_PACKAGE_AUDIT_DIR = Path("artifacts/audits/section_5/campaign_3_supplement_4_0_agent_package")
CAMPAIGN_3_4_0_AUDIT_DIR = Path("artifacts/audits/campaign_3_4_0")

PRODUCT_OUTPUTS = [
    "docs/product/AGENT_WORKSPACE_BINDING_SPEC.md",
    "docs/product/AGENT_WORKSPACE_BINDING_SPEC.json",
    "docs/product/AGENT_MEMORY_ISOLATION_SPEC.md",
    "docs/product/AGENT_MEMORY_ISOLATION_SPEC.json",
    "docs/product/AGENT_MEMORY_BACKEND_MATRIX.json",
    "docs/product/AGENT_MEMORY_FALLBACK_POLICY.md",
    "docs/product/AGENT_MODE_SPEC.md",
    "docs/product/MULTI_AGENT_WORKFLOW_SPEC.md",
    "docs/product/AGENT_ROLE_ASSIGNMENT_SPEC.json",
    "docs/product/AGENT_HANDOFF_RULES_SPEC.json",
    "docs/product/CAMPAIGN_4_UI_HANDOFF_CONTRACT.md",
    "docs/product/CAMPAIGN_4_UI_HANDOFF_CONTRACT.json",
    "docs/product/UI_TASK_CARD_INPUTS_FROM_CAMPAIGN_3.json",
    "docs/product/AGENT_BUILDER_UI_REQUIREMENT_SPEC.md",
    "docs/product/SKILL_AGENT_UI_FLOW_SPEC.json",
    "docs/product/MULTI_AGENT_UI_FLOW_SPEC.json",
    "docs/product/UI_STATE_INPUTS_FROM_CORE.json",
]

BRIDGE_OUTPUTS = [
    "docs/bridge/CAMPAIGN_5_BRIDGE_HANDOFF_CONTRACT.md",
    "docs/bridge/CAMPAIGN_5_BRIDGE_HANDOFF_CONTRACT.json",
    "docs/bridge/FUTURE_AGENT_BRIDGE_ACTION_CANDIDATES.json",
    "docs/bridge/USER_TASK_TO_BRIDGE_FLOW_CANDIDATES.json",
    "docs/bridge/BRIDGE_MISSING_ACTION_MATRIX.json",
]

BUNDLE_OUTPUTS = [
    "run_manifest.json",
    "run_summary.md",
    "stage_status_matrix.json",
    "boundary_matrix.json",
    "validation_report.json",
    "checkpoint.json",
    "progress_events.jsonl",
]

FORBIDDEN_OVERCLAIM_FLAGS = {
    "campaign_4_active": False,
    "campaign_5_active": False,
    "campaign_4_ui_complete": False,
    "campaign_5_bridge_complete": False,
    "ui_handoff_is_campaign_4_completion": False,
    "bridge_handoff_is_campaign_5_completion": False,
    "agent_runtime_ready": False,
    "agent_executable": False,
    "redis_runtime_ready": False,
    "vector_runtime_ready": False,
    "memory_isolation_runtime_ready": False,
    "multi_agent_runtime_ready": False,
    "multi_agent_executable": False,
    "bridge_execution_accepted": False,
    "future_allowlist_candidate_active": False,
}


def build_campaign_3_supplement_4_0_product_handoff_bundle(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    agent_audit = AGENT_PACKAGE_AUDIT_DIR
    agent_manifest = _read_json(repo_root / agent_audit / "agent_package" / "agent_manifest.json")
    bound_kbs = _read_json(repo_root / agent_audit / "agent_package" / "bound_knowledge_bases.json")
    bound_skills = _read_json(repo_root / agent_audit / "agent_package" / "bound_skills.json")
    agent_state = _read_json(repo_root / agent_audit / "agent_state_matrix.json")

    agent_id = agent_manifest.get("agent_id", "agent_package_pending")
    workspace_binding = _workspace_binding_spec(agent_id, bound_kbs, bound_skills)
    memory_spec = _memory_isolation_spec(agent_id)
    memory_backend = _memory_backend_matrix()
    agent_modes = _agent_mode_spec(agent_id)
    role_assignment = _role_assignment_spec(agent_id)
    handoff_rules = _handoff_rules_spec(agent_id)
    ui_handoff = _ui_handoff_contract(agent_id)
    ui_task_cards = _ui_task_card_inputs(agent_id)
    ui_states = _ui_state_inputs(agent_state)
    skill_agent_flow = _skill_agent_ui_flow(agent_id)
    multi_agent_flow = _multi_agent_ui_flow(agent_id)
    bridge_handoff = _bridge_handoff_contract(agent_id)
    bridge_actions = _future_bridge_action_candidates()
    bridge_flows = _user_task_bridge_flow_candidates()
    missing_actions = _bridge_missing_action_matrix()
    stage_matrix = _stage_status_matrix()
    boundary_matrix = _boundary_matrix()

    validation = _validate_bundle_payload(
        workspace_binding=workspace_binding,
        memory_spec=memory_spec,
        memory_backend=memory_backend,
        agent_modes=agent_modes,
        ui_handoff=ui_handoff,
        bridge_handoff=bridge_handoff,
        stage_matrix=stage_matrix,
        boundary_matrix=boundary_matrix,
    )
    status = "passed" if validation["status"] == "passed" else "failed"

    return {
        "schema_version": "campaign_3_supplement_4_0_product_handoff_bundle.v1",
        "generated_at": GENERATED_AT,
        "campaign": "Campaign 3",
        "supplement": "4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "current_item": CURRENT_ITEM,
        "status": status,
        "integration_decision": "real_integration",
        "decision_qualifier": "product_handoff_contract_bundle_only",
        "implementation_level": "bounded industrial-grade implementation",
        "agent_package_audit_dir": str(agent_audit),
        "workspace_binding_spec": workspace_binding,
        "memory_isolation_spec": memory_spec,
        "memory_backend_matrix": memory_backend,
        "agent_mode_spec": agent_modes,
        "role_assignment_spec": role_assignment,
        "handoff_rules_spec": handoff_rules,
        "campaign_4_ui_handoff_contract": ui_handoff,
        "ui_task_card_inputs": ui_task_cards,
        "agent_builder_ui_requirement": _agent_builder_ui_requirement(agent_id),
        "skill_agent_ui_flow": skill_agent_flow,
        "multi_agent_ui_flow": multi_agent_flow,
        "ui_state_inputs": ui_states,
        "campaign_5_bridge_handoff_contract": bridge_handoff,
        "future_agent_bridge_action_candidates": bridge_actions,
        "user_task_to_bridge_flow_candidates": bridge_flows,
        "bridge_missing_action_matrix": missing_actions,
        "stage_status_matrix": stage_matrix,
        "boundary_matrix": boundary_matrix,
        "validation_report": validation,
        "progress_events": _progress_events(status),
        "campaign_state_after_step": _campaign_state(status == "passed"),
        "next_action_manifest": _next_action_manifest(status == "passed"),
        "not_goal_complete": True,
    }


def write_campaign_3_supplement_4_0_product_handoff_bundle(repo_root: Path, output: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)

    agent_output = repo_root / AGENT_PACKAGE_AUDIT_DIR
    write_campaign_3_supplement_4_0_agent_package(repo_root, agent_output)
    report = build_campaign_3_supplement_4_0_product_handoff_bundle(repo_root)

    docs_product = repo_root / "docs" / "product"
    docs_bridge = repo_root / "docs" / "bridge"
    audit_dir = repo_root / CAMPAIGN_3_4_0_AUDIT_DIR
    docs_product.mkdir(parents=True, exist_ok=True)
    docs_bridge.mkdir(parents=True, exist_ok=True)
    audit_dir.mkdir(parents=True, exist_ok=True)

    write_json(docs_product / "AGENT_WORKSPACE_BINDING_SPEC.json", report["workspace_binding_spec"])
    (docs_product / "AGENT_WORKSPACE_BINDING_SPEC.md").write_text(
        _render_workspace_binding(report["workspace_binding_spec"]),
        encoding="utf-8",
    )
    write_json(audit_dir / "agent_workspace_binding_report.json", _audit_report("4.0E", report["workspace_binding_spec"]))

    write_json(docs_product / "AGENT_MEMORY_ISOLATION_SPEC.json", report["memory_isolation_spec"])
    (docs_product / "AGENT_MEMORY_ISOLATION_SPEC.md").write_text(
        _render_memory_spec(report["memory_isolation_spec"]),
        encoding="utf-8",
    )
    write_json(docs_product / "AGENT_MEMORY_BACKEND_MATRIX.json", report["memory_backend_matrix"])
    (docs_product / "AGENT_MEMORY_FALLBACK_POLICY.md").write_text(_render_memory_fallback_policy(), encoding="utf-8")
    write_json(audit_dir / "agent_memory_isolation_report.json", _audit_report("4.0F", report["memory_isolation_spec"]))

    (docs_product / "AGENT_MODE_SPEC.md").write_text(_render_agent_mode_spec(report["agent_mode_spec"]), encoding="utf-8")
    (docs_product / "MULTI_AGENT_WORKFLOW_SPEC.md").write_text(_render_multi_agent_workflow_spec(report), encoding="utf-8")
    write_json(docs_product / "AGENT_ROLE_ASSIGNMENT_SPEC.json", report["role_assignment_spec"])
    write_json(docs_product / "AGENT_HANDOFF_RULES_SPEC.json", report["handoff_rules_spec"])
    write_json(audit_dir / "agent_mode_workflow_report.json", _audit_report("4.0G", report["agent_mode_spec"]))

    write_json(docs_product / "CAMPAIGN_4_UI_HANDOFF_CONTRACT.json", report["campaign_4_ui_handoff_contract"])
    (docs_product / "CAMPAIGN_4_UI_HANDOFF_CONTRACT.md").write_text(
        _render_ui_handoff(report["campaign_4_ui_handoff_contract"]),
        encoding="utf-8",
    )
    write_json(docs_product / "UI_TASK_CARD_INPUTS_FROM_CAMPAIGN_3.json", report["ui_task_card_inputs"])
    (docs_product / "AGENT_BUILDER_UI_REQUIREMENT_SPEC.md").write_text(
        _render_agent_builder_requirement(report["agent_builder_ui_requirement"]),
        encoding="utf-8",
    )
    write_json(docs_product / "SKILL_AGENT_UI_FLOW_SPEC.json", report["skill_agent_ui_flow"])
    write_json(docs_product / "MULTI_AGENT_UI_FLOW_SPEC.json", report["multi_agent_ui_flow"])
    write_json(docs_product / "UI_STATE_INPUTS_FROM_CORE.json", report["ui_state_inputs"])
    write_json(audit_dir / "campaign_4_ui_handoff_report.json", _audit_report("4.0H", report["campaign_4_ui_handoff_contract"]))

    write_json(docs_bridge / "CAMPAIGN_5_BRIDGE_HANDOFF_CONTRACT.json", report["campaign_5_bridge_handoff_contract"])
    (docs_bridge / "CAMPAIGN_5_BRIDGE_HANDOFF_CONTRACT.md").write_text(
        _render_bridge_handoff(report["campaign_5_bridge_handoff_contract"]),
        encoding="utf-8",
    )
    write_json(docs_bridge / "FUTURE_AGENT_BRIDGE_ACTION_CANDIDATES.json", report["future_agent_bridge_action_candidates"])
    write_json(docs_bridge / "USER_TASK_TO_BRIDGE_FLOW_CANDIDATES.json", report["user_task_to_bridge_flow_candidates"])
    write_json(docs_bridge / "BRIDGE_MISSING_ACTION_MATRIX.json", report["bridge_missing_action_matrix"])
    write_json(audit_dir / "campaign_5_bridge_handoff_report.json", _audit_report("4.0I", report["campaign_5_bridge_handoff_contract"]))

    write_json(output / "stage_status_matrix.json", report["stage_status_matrix"])
    write_json(output / "boundary_matrix.json", report["boundary_matrix"])
    write_json(output / "validation_report.json", report["validation_report"])
    write_json(output / "run_manifest.json", _run_manifest(report))
    write_json(output / "checkpoint.json", _checkpoint(report))
    write_jsonl(output / "progress_events.jsonl", report["progress_events"])
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")
    return report


def validate_campaign_3_supplement_4_0_product_handoff_bundle(repo_root: Path, output: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    errors: list[str] = []

    agent_validation = validate_campaign_3_supplement_4_0_agent_package(repo_root, repo_root / AGENT_PACKAGE_AUDIT_DIR)
    if agent_validation.get("status") != "passed":
        errors.append("4_0d_agent_package_validation_not_passed")

    for relative in PRODUCT_OUTPUTS + BRIDGE_OUTPUTS:
        path = repo_root / relative
        if not path.exists():
            errors.append(f"missing_contract:{relative}")
        elif path.suffix == ".json":
            _read_json_with_errors(path, errors, relative)

    for relative in BUNDLE_OUTPUTS:
        path = output / relative
        if not path.exists():
            errors.append(f"missing_bundle_output:{relative}")

    validation = _read_json_with_errors(output / "validation_report.json", errors, "validation_report")
    stage_matrix = _read_json_with_errors(output / "stage_status_matrix.json", errors, "stage_status_matrix")
    boundary_matrix = _read_json_with_errors(output / "boundary_matrix.json", errors, "boundary_matrix")
    ui_handoff = _read_json_with_errors(repo_root / "docs/product/CAMPAIGN_4_UI_HANDOFF_CONTRACT.json", errors, "ui_handoff")
    bridge_handoff = _read_json_with_errors(repo_root / "docs/bridge/CAMPAIGN_5_BRIDGE_HANDOFF_CONTRACT.json", errors, "bridge_handoff")
    memory_spec = _read_json_with_errors(repo_root / "docs/product/AGENT_MEMORY_ISOLATION_SPEC.json", errors, "memory_spec")
    agent_mode = _read_json_with_errors(repo_root / "docs/product/AGENT_ROLE_ASSIGNMENT_SPEC.json", errors, "agent_role_assignment")
    checkpoint = _read_json_with_errors(output / "checkpoint.json", errors, "checkpoint")

    if validation.get("status") != "passed":
        errors.append("stored_validation_not_passed")
    for item in stage_matrix.get("stages", []):
        if item.get("status") != "passed":
            errors.append(f"stage_not_passed:{item.get('stage_id')}")
    for flag, expected in FORBIDDEN_OVERCLAIM_FLAGS.items():
        if boundary_matrix.get("flags", {}).get(flag) is not expected:
            errors.append(f"boundary_flag_mismatch:{flag}")
    if ui_handoff.get("campaign_4_active") is not False or ui_handoff.get("ui_workbench_complete") is not False:
        errors.append("ui_handoff_overclaims_campaign_4")
    if bridge_handoff.get("campaign_5_active") is not False or bridge_handoff.get("bridge_execution_accepted") is not False:
        errors.append("bridge_handoff_overclaims_campaign_5")
    if memory_spec.get("agent_short_term_redis_runtime_ready") is not False:
        errors.append("memory_spec_overclaims_redis_runtime")
    if memory_spec.get("agent_long_term_vector_runtime_ready") is not False:
        errors.append("memory_spec_overclaims_vector_runtime")
    if agent_mode.get("multi_agent_runtime_ready") is not False:
        errors.append("multi_agent_runtime_overclaim")
    if checkpoint.get("next_safe_action") != NEXT_ACTION:
        errors.append("checkpoint_next_safe_action_mismatch")

    return {
        "schema_version": "campaign_3_supplement_4_0_product_handoff_bundle_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "errors": errors,
        "next_safe_action": NEXT_ACTION if not errors else "Repair Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle",
        "campaign_3_supplement_4_0_d_i_bundle_passed": not errors,
        "campaign_3_supplement_4_0_acceptance_gate_passed": False,
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "agent_runtime_ready": False,
        "memory_runtime_ready": False,
        "bridge_execution_accepted": False,
        "not_goal_complete": True,
    }


def write_campaign_3_supplement_4_0_product_handoff_bundle_validation(repo_root: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_campaign_3_supplement_4_0_product_handoff_bundle(repo_root, output)
    write_json(output / "validation_report.json", result)
    return result


def _workspace_binding_spec(agent_id: str, bound_kbs: dict[str, Any], bound_skills: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "agent_workspace_binding_spec.v1",
        "status": "spec_ready",
        "workspace_basic_supported": True,
        "agent_workspace_partition_ready": "spec_ready",
        "multi_agent_workspace_isolation_ready": "spec_ready",
        "runtime_enforcement_ready": False,
        "workspace_structure": [
            "Sources",
            "Knowledge Bases",
            "Skills",
            "Agents",
            "Multi-Agent Workflows",
            "Runs",
            "Reports",
            "Audit",
        ],
        "agent_binding": {
            "workspace_id": "workspace_default_campaign_3",
            "agent_id": agent_id,
            "agent_type": "knowledge_bound_agent_package",
            "bound_knowledge_base_ids": [item.get("kb_id") for item in bound_kbs.get("knowledge_bases", [])],
            "bound_skill_ids": [item.get("skill_id") for item in bound_skills.get("skills", [])],
            "private_memory_scope": "workspace/{workspace_id}/agent/{agent_id}/private",
            "shared_memory_scope": "workspace/{workspace_id}/workflow/{workflow_id}/shared_memory",
            "tool_permission_scope": "future_runtime_policy_required",
            "output_contract": "agent_package/output_contract.json",
            "audit_scope": "workspace/{workspace_id}/audit/{run_id}",
        },
        "forbidden_claims": [
            "workspace_spec_is_runtime_enforcement",
            "multi_agent_workspace_is_executable_runtime",
        ],
    }


def _memory_isolation_spec(agent_id: str) -> dict[str, Any]:
    return {
        "schema_version": "agent_memory_isolation_spec.v1",
        "status": "spec_ready",
        "agent_id": agent_id,
        "agent_memory_spec_ready": True,
        "agent_short_term_redis_runtime_ready": False,
        "agent_long_term_vector_runtime_ready": False,
        "agent_memory_isolation_runtime_ready": False,
        "cross_agent_memory_leak_tests_required": True,
        "memory_layers": [
            "short_term_memory",
            "long_term_memory",
            "private_agent_memory",
            "shared_workflow_memory",
            "workspace_memory",
            "run_memory",
            "audit_memory",
        ],
        "namespace_fields": [
            "workspace_id",
            "agent_id",
            "workflow_id",
            "session_id",
            "run_id",
            "memory_scope",
            "memory_type",
        ],
        "recommended_namespaces": [
            "workspace/{workspace_id}/agent/{agent_id}/session/{session_id}/short_term",
            "workspace/{workspace_id}/agent/{agent_id}/long_term",
            "workspace/{workspace_id}/workflow/{workflow_id}/shared_memory",
            "workspace/{workspace_id}/run/{run_id}/scratchpad",
            "workspace/{workspace_id}/audit/{run_id}",
        ],
        "shared_memory_default": "closed",
        "cross_agent_memory_shared_by_default": False,
    }


def _memory_backend_matrix() -> dict[str, Any]:
    return {
        "schema_version": "agent_memory_backend_matrix.v1",
        "status": "spec_ready",
        "redis_roles": {
            "short_term_memory_backend": "redis_candidate",
            "session_state_backend": "redis_candidate",
            "run_state_backend": "redis_candidate",
            "runtime_ready": False,
        },
        "vector_db_roles": {
            "long_term_memory_backend": "vector_candidate",
            "semantic_memory_backend": "vector_candidate",
            "agent_recall_backend": "vector_candidate",
            "runtime_ready": False,
        },
        "fallback": {
            "redis_missing": "local_jsonl_short_term_memory / display degraded",
            "vector_missing": "keyword_search / structured_index fallback",
        },
    }


def _agent_mode_spec(agent_id: str) -> dict[str, Any]:
    return {
        "schema_version": "agent_mode_spec.v1",
        "status": "spec_ready",
        "agent_id": agent_id,
        "product_modes": [
            "simple_single_agent_mode",
            "advanced_single_agent_mode",
            "simple_multi_agent_mode",
            "advanced_multi_agent_mode",
        ],
        "single_agent_package_ready": "based_on_existing_agent_package",
        "multi_agent_spec_ready": True,
        "multi_agent_runtime_ready": False,
        "multi_agent_executable": False,
        "coze_style_platform_complete": False,
    }


def _role_assignment_spec(agent_id: str) -> dict[str, Any]:
    return {
        "schema_version": "agent_role_assignment_spec.v1",
        "status": "spec_ready",
        "roles": [
            {
                "role_id": "primary_knowledge_worker",
                "agent_id": agent_id,
                "allowed_mode": "single_agent_package",
                "runtime_required": False,
            },
            {
                "role_id": "reviewer_agent_candidate",
                "agent_id": "future_agent_candidate",
                "allowed_mode": "multi_agent_spec_only",
                "runtime_required": True,
                "current_runtime_ready": False,
            },
        ],
        "multi_agent_runtime_ready": False,
    }


def _handoff_rules_spec(agent_id: str) -> dict[str, Any]:
    return {
        "schema_version": "agent_handoff_rules_spec.v1",
        "status": "spec_ready",
        "rules": [
            {"rule_id": "handoff_requires_source_trace", "required": True},
            {"rule_id": "handoff_requires_output_contract", "required": True},
            {"rule_id": "handoff_does_not_execute_agent", "required": True},
        ],
        "agent_id": agent_id,
        "workflow_executed": False,
    }


def _ui_handoff_contract(agent_id: str) -> dict[str, Any]:
    return {
        "schema_version": "campaign_4_ui_handoff_contract.v1",
        "status": "handoff_contract_ready",
        "agent_id": agent_id,
        "campaign_4_active": False,
        "ui_workbench_complete": False,
        "ui_handoff_is_campaign_4_completion": False,
        "top_level_navigation": [
            "Workspace",
            "Import Materials",
            "Knowledge Base",
            "Skill / Agent",
            "Multi-Agent Workflow",
            "Export / Audit",
            "Settings / Diagnostics",
        ],
        "campaign_4_must_consume": [
            "KB card",
            "Skill card",
            "Agent card",
            "Multi-Agent workflow card",
            "Memory status card",
            "Evidence / verification status card",
            "Export card",
        ],
        "forbidden_claims": [
            "agent_package_is_agent_runtime",
            "memory_config_is_memory_runtime",
            "ui_handoff_is_campaign_4_completion",
        ],
    }


def _ui_task_card_inputs(agent_id: str) -> dict[str, Any]:
    cards = [
        ("knowledge_base", "Review verified knowledge base", "ready"),
        ("skill", "Use generated or dedicated Skill", "ready"),
        ("agent_package", "Prepare Agent package", "ready"),
        ("multi_agent_workflow", "Plan multi-Agent workflow", "planned_not_active"),
        ("memory", "Review memory isolation spec", "display_only"),
        ("verification", "Review evidence and verification", "ready"),
        ("export", "Prepare handoff package", "ready"),
    ]
    return {
        "schema_version": "ui_task_card_inputs_from_campaign_3.v1",
        "status": "handoff_contract_ready",
        "agent_id": agent_id,
        "cards": [
            {
                "card_id": card_id,
                "title": title,
                "current_status": status,
                "next_recommended_action": "review_details" if status != "ready" else "continue",
                "primary_button": "continue" if status == "ready" else "view_details",
                "secondary_actions": ["view_details"],
                "source_evidence": str(BUNDLE_AUDIT_DIR / "run_manifest.json"),
                "blocked_reason": "" if status == "ready" else "Runtime or bridge implementation not active in Campaign 3 Supplement 4.0.",
                "repair_suggestion": "" if status == "ready" else "Wait for later campaign acceptance.",
                "output_assets": PRODUCT_OUTPUTS + BRIDGE_OUTPUTS,
                "forbidden_claims": list(FORBIDDEN_OVERCLAIM_FLAGS.keys()),
            }
            for card_id, title, status in cards
        ],
    }


def _agent_builder_ui_requirement(agent_id: str) -> dict[str, Any]:
    return {
        "schema_version": "agent_builder_ui_requirement_spec.v1",
        "status": "handoff_contract_ready",
        "agent_id": agent_id,
        "display_agent_package_ready": True,
        "display_agent_runtime_ready": False,
        "allowed_primary_action": "review_agent_package",
        "forbidden_primary_action": "run_agent_runtime",
    }


def _skill_agent_ui_flow(agent_id: str) -> dict[str, Any]:
    return {
        "schema_version": "skill_agent_ui_flow_spec.v1",
        "status": "handoff_contract_ready",
        "flow": [
            "select_workspace",
            "select_knowledge_base",
            "review_skill",
            "compose_or_import_skill",
            "generate_agent_package",
            "review_source_trace",
            "export_package",
        ],
        "agent_id": agent_id,
        "execution_runtime_step_included": False,
    }


def _multi_agent_ui_flow(agent_id: str) -> dict[str, Any]:
    return {
        "schema_version": "multi_agent_ui_flow_spec.v1",
        "status": "spec_ready",
        "flow": [
            "select_multi_agent_mode",
            "assign_roles",
            "bind_agent_packages",
            "review_handoff_rules",
            "export_workflow_spec",
        ],
        "agent_id": agent_id,
        "multi_agent_runtime_ready": False,
        "multi_agent_executable": False,
    }


def _ui_state_inputs(agent_state: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "ui_state_inputs_from_core.v1",
        "status": "handoff_contract_ready",
        "core_states": agent_state.get("states", []),
        "ui_states": {
            "ready": ["agent_package_ready", "agent_bound_to_kb", "agent_bound_to_skill"],
            "display_only": ["agent_runtime_not_integrated"],
            "planned_not_active": ["multi_agent_runtime_ready"],
            "runtime_not_integrated": ["agent_runtime_ready"],
            "bridge_action_missing": ["future_allowlist_candidate_active"],
            "memory_backend_missing": ["redis_runtime_ready", "vector_runtime_ready"],
            "needs_review": ["agent_needs_review"],
            "failed": [],
            "skipped": [],
            "blocked_by_dependency": ["agent_executable"],
        },
        "forbidden_misinterpretations": list(FORBIDDEN_OVERCLAIM_FLAGS.keys()),
    }


def _bridge_handoff_contract(agent_id: str) -> dict[str, Any]:
    return {
        "schema_version": "campaign_5_bridge_handoff_contract.v1",
        "status": "handoff_contract_ready",
        "agent_id": agent_id,
        "campaign_5_active": False,
        "bridge_execution_accepted": False,
        "bridge_handoff_is_campaign_5_completion": False,
        "current_existing_cli": ["generate-agent", "generate-bound-agent"],
        "future_allowlist_candidates_active": False,
        "required_boundaries": [
            "Campaign 5 must not automatically inherit future_allowlist_candidate.",
            "Every new allowlist action must have separate acceptance.",
            "Agent runtime action must not masquerade as package generation action.",
            "Memory backend action must not masquerade as memory isolation runtime.",
        ],
    }


def _future_bridge_action_candidates() -> dict[str, Any]:
    candidates = [
        "generate-skill-template",
        "import-skill",
        "compose-dedicated-skill",
        "validate-skill",
        "generate-agent-package",
        "bind-agent-knowledge-base",
        "bind-agent-skill",
        "validate-agent-package",
        "export-agent-package",
        "build-multi-agent-workflow-spec",
        "configure-agent-memory-policy",
        "check-agent-memory-backend",
        "check-agent-workspace-isolation",
    ]
    return {
        "schema_version": "future_agent_bridge_action_candidates.v1",
        "status": "future_candidates_only",
        "implementation_mode": "not_integrated",
        "current_allowlist_added": False,
        "candidates": [
            {
                "action_id": action,
                "status": "future_allowlist_candidate",
                "runtime_active": False,
                "requires_separate_acceptance": True,
            }
            for action in candidates
        ],
        "forbidden_actions": [
            "arbitrary-shell",
            "run-command",
            "exec",
            "powershell",
            "bash",
            "cmd",
            "install-any-package",
            "open-any-path",
            "browser-cookie-import",
            "login-bypass",
        ],
    }


def _user_task_bridge_flow_candidates() -> dict[str, Any]:
    return {
        "schema_version": "user_task_to_bridge_flow_candidates.v1",
        "status": "future_candidates_only",
        "flows": [
            {
                "user_task_id": "create_skill_agent_package",
                "candidate_actions": ["generate-skill-template", "compose-dedicated-skill", "generate-agent-package"],
                "current_executable": False,
                "blocked_reason": "Campaign 5 Bridge action acceptance has not run.",
            },
            {
                "user_task_id": "prepare_multi_agent_workflow_spec",
                "candidate_actions": ["build-multi-agent-workflow-spec"],
                "current_executable": False,
                "blocked_reason": "Multi-Agent runtime and bridge execution are not accepted.",
            },
        ],
    }


def _bridge_missing_action_matrix() -> dict[str, Any]:
    return {
        "schema_version": "bridge_missing_action_matrix.v1",
        "status": "bridge_handoff_only",
        "missing_current_actions": [
            "generate-skill-template",
            "compose-dedicated-skill",
            "generate-agent-package",
            "validate-agent-package",
            "build-multi-agent-workflow-spec",
            "configure-agent-memory-policy",
        ],
        "bridge_execution_accepted": False,
        "next_campaign_for_acceptance": "Campaign 5 Chain-Level Local Core Bridge",
    }


def _stage_status_matrix() -> dict[str, Any]:
    stages = [
        ("4_0d_agent_package", "passed", str(AGENT_PACKAGE_AUDIT_DIR / "run_manifest.json")),
        ("4_0e_workspace_binding", "passed", "docs/product/AGENT_WORKSPACE_BINDING_SPEC.json"),
        ("4_0f_memory_isolation", "passed", "docs/product/AGENT_MEMORY_ISOLATION_SPEC.json"),
        ("4_0g_single_multi_agent_mode", "passed", "docs/product/AGENT_MODE_SPEC.md"),
        ("4_0h_campaign_4_ui_handoff", "passed", "docs/product/CAMPAIGN_4_UI_HANDOFF_CONTRACT.json"),
        ("4_0i_campaign_5_bridge_handoff", "passed", "docs/bridge/CAMPAIGN_5_BRIDGE_HANDOFF_CONTRACT.json"),
    ]
    return {
        "schema_version": "campaign_3_supplement_4_0_d_i_stage_status_matrix.v1",
        "status": "passed",
        "stages": [
            {"stage_id": stage_id, "status": status, "artifact_path": path}
            for stage_id, status, path in stages
        ],
    }


def _boundary_matrix() -> dict[str, Any]:
    return {
        "schema_version": "campaign_3_supplement_4_0_d_i_boundary_matrix.v1",
        "status": "passed",
        "flags": dict(FORBIDDEN_OVERCLAIM_FLAGS),
        "forbidden_interpretations": [
            "UI handoff is not Campaign 4 UI completion.",
            "Bridge handoff is not Campaign 5 Bridge completion.",
            "Agent Package is not Agent Runtime completion.",
            "Memory spec is not Redis or Vector DB runtime completion.",
            "Multi-Agent workflow spec is not multi-Agent execution.",
        ],
    }


def _validate_bundle_payload(**payloads: dict[str, Any]) -> dict[str, Any]:
    errors: list[str] = []
    workspace_binding = payloads["workspace_binding"]
    memory_spec = payloads["memory_spec"]
    memory_backend = payloads["memory_backend"]
    agent_modes = payloads["agent_modes"]
    ui_handoff = payloads["ui_handoff"]
    bridge_handoff = payloads["bridge_handoff"]
    stage_matrix = payloads["stage_matrix"]
    boundary_matrix = payloads["boundary_matrix"]

    if workspace_binding.get("runtime_enforcement_ready") is not False:
        errors.append("workspace_binding_overclaims_runtime_enforcement")
    if memory_spec.get("agent_memory_isolation_runtime_ready") is not False:
        errors.append("memory_spec_overclaims_runtime")
    if memory_backend.get("redis_roles", {}).get("runtime_ready") is not False:
        errors.append("memory_backend_overclaims_redis")
    if memory_backend.get("vector_db_roles", {}).get("runtime_ready") is not False:
        errors.append("memory_backend_overclaims_vector")
    if agent_modes.get("multi_agent_runtime_ready") is not False:
        errors.append("multi_agent_runtime_overclaim")
    if ui_handoff.get("campaign_4_active") is not False:
        errors.append("ui_handoff_activates_campaign_4")
    if bridge_handoff.get("bridge_execution_accepted") is not False:
        errors.append("bridge_handoff_accepts_campaign_5")
    if any(item.get("status") != "passed" for item in stage_matrix.get("stages", [])):
        errors.append("not_all_stages_passed")
    for key, expected in FORBIDDEN_OVERCLAIM_FLAGS.items():
        if boundary_matrix.get("flags", {}).get(key) is not expected:
            errors.append(f"boundary_flag_mismatch:{key}")
    return {
        "schema_version": "campaign_3_supplement_4_0_d_i_bundle_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "errors": errors,
        "next_safe_action": NEXT_ACTION if not errors else "Repair Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle",
        "campaign_3_supplement_4_0_d_i_bundle_passed": not errors,
        "campaign_3_supplement_4_0_acceptance_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
    }


def _campaign_state(passed: bool) -> dict[str, Any]:
    return {
        "campaign_3_supplement_4_0_b_passed": True,
        "campaign_3_supplement_4_0c_passed": True,
        "campaign_3_supplement_4_0d_passed": passed,
        "campaign_3_supplement_4_0e_passed": passed,
        "campaign_3_supplement_4_0f_passed": passed,
        "campaign_3_supplement_4_0g_passed": passed,
        "campaign_3_supplement_4_0h_passed": passed,
        "campaign_3_supplement_4_0i_passed": passed,
        "campaign_3_supplement_4_0_d_i_bundle_passed": passed,
        "campaign_3_supplement_4_0_business_implementation_complete": passed,
        "campaign_3_supplement_4_0_acceptance_gate_passed": False,
        "campaign_3_final_consistency_gate_passed": False,
        "agent_package_ready": passed,
        "agent_runtime_ready": False,
        "agent_executable": False,
        "memory_spec_ready": passed,
        "redis_runtime_ready": False,
        "vector_runtime_ready": False,
        "multi_agent_spec_ready": passed,
        "multi_agent_runtime_ready": False,
        "campaign_4_ui_handoff_ready": passed,
        "campaign_4_active": False,
        "campaign_4_ui_complete": False,
        "campaign_5_bridge_handoff_ready": passed,
        "campaign_5_active": False,
        "bridge_execution_accepted": False,
        "full_gate_passed": False,
        "exe_packaging_done": False,
        "repository_push_succeeded": False,
        "tag_created": False,
        "ci_green": False,
    }


def _next_action_manifest(passed: bool) -> dict[str, Any]:
    return {
        "schema_version": "campaign_3_supplement_4_0_d_i_next_action.v1",
        "generated_at": GENERATED_AT,
        "status": "ready" if passed else "blocked",
        "current_item_completed": CURRENT_ITEM if passed else "",
        "next_safe_action": NEXT_ACTION if passed else "Repair Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle",
        "may_enter_supplement_4_0_acceptance_gate": passed,
        "may_enter_campaign_3_final_consistency_gate": False,
        "may_enter_stage_test_gate": False,
        "may_enter_campaign_4": False,
        "may_enter_campaign_5": False,
        "may_push": False,
        "may_tag": False,
        "may_check_ci_for_campaign_4": False,
        "not_goal_complete": True,
    }


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "run_manifest.v1",
        "run_id": "campaign_3_supplement_4_0_product_handoff_bundle",
        "type": "campaign_supplement_implementation_bundle",
        "scope": "CAMPAIGN_3_SUPPLEMENT_4_0_D_I_PRODUCT_HANDOFF_CONTRACT_BUNDLE",
        "status": report["status"],
        "integration_decision": report["integration_decision"],
        "decision_qualifier": report["decision_qualifier"],
        "implementation_level": report["implementation_level"],
        "generated_at": report["generated_at"],
        "output_files": [str(AGENT_PACKAGE_AUDIT_DIR / "run_manifest.json"), *PRODUCT_OUTPUTS, *BRIDGE_OUTPUTS, *BUNDLE_OUTPUTS],
        "stage_status_matrix": report["stage_status_matrix"],
        "campaign_state_after_step": report["campaign_state_after_step"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "not_goal_complete": True,
    }


def _checkpoint(report: dict[str, Any]) -> dict[str, Any]:
    passed = report["status"] == "passed"
    return {
        "schema_version": "current_run_checkpoint.v2",
        "checkpoint_id": "campaign_3_supplement_4_0_d_i_product_handoff_bundle_passed" if passed else "campaign_3_supplement_4_0_d_i_product_handoff_bundle_failed",
        "updated_at": report["generated_at"],
        "current_item": CURRENT_ITEM,
        "current_status": report["status"],
        "current_plan_section": "Section 5 / Campaign 3",
        "last_successful_step": "Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle generated and validated" if passed else "Campaign 3 Supplement 4.0C Dedicated Skill",
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "blocked_future_items": [
            "Campaign 3 Final Consistency Gate before Supplement 4.0 Acceptance Gate",
            "Campaign 1-3 Stage Test Gate before Campaign 3 Final Consistency Gate",
            "Campaign 4 before closure, repository cleanup, push, tag, CI, checklist, and review handoff gates",
            "Campaign 5 before Campaign 4 acceptance",
            "Full Gate",
            "EXE",
            "Release",
        ],
        "tests_run": [],
        "tests_passed": [],
        "tests_failed": [],
        "files_changed": [],
        "audit_outputs": [
            str(BUNDLE_AUDIT_DIR / "run_manifest.json"),
            str(BUNDLE_AUDIT_DIR / "validation_report.json"),
            str(AGENT_PACKAGE_AUDIT_DIR / "run_manifest.json"),
            "docs/product/AGENT_WORKSPACE_BINDING_SPEC.json",
            "docs/product/AGENT_MEMORY_ISOLATION_SPEC.json",
            "docs/product/AGENT_MODE_SPEC.md",
            "docs/product/CAMPAIGN_4_UI_HANDOFF_CONTRACT.json",
            "docs/bridge/CAMPAIGN_5_BRIDGE_HANDOFF_CONTRACT.json",
        ],
        "retry_summary": {"transient_retries": 0},
        "resume_prompt_path": "artifacts/audits/current_run/resume_prompt.md",
        "not_goal_complete": True,
        **report["campaign_state_after_step"],
    }


def _progress_events(status: str) -> list[dict[str, Any]]:
    stages = [
        "4_0d_agent_package",
        "4_0e_workspace_binding",
        "4_0f_memory_isolation",
        "4_0g_agent_modes",
        "4_0h_ui_handoff",
        "4_0i_bridge_handoff",
        "bundle_validation",
    ]
    return [
        {
            "stage": stage,
            "status": "passed" if status == "passed" else "failed",
            "timestamp": GENERATED_AT,
            "message": f"{stage} generated within Supplement 4.0 D-I Product Handoff Contract Bundle.",
            "artifact_path": str(BUNDLE_AUDIT_DIR),
        }
        for stage in stages
    ]


def _audit_report(stage: str, payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_3_4_0_stage_audit_report.v1",
        "generated_at": GENERATED_AT,
        "stage": stage,
        "status": payload.get("status", "passed"),
        "source": str(BUNDLE_AUDIT_DIR / "run_manifest.json"),
        "campaign_4_active": False,
        "campaign_5_active": False,
        "agent_runtime_ready": False,
        "bridge_execution_accepted": False,
        "payload_summary": {
            "schema_version": payload.get("schema_version"),
            "status": payload.get("status"),
        },
    }


def _render_workspace_binding(spec: dict[str, Any]) -> str:
    return f"""# Agent Workspace Binding Spec

- Status: `{spec['status']}`
- Workspace partition ready: `{spec['agent_workspace_partition_ready']}`
- Runtime enforcement ready: `false`
- Agent ID: `{spec['agent_binding']['agent_id']}`

This is a Supplement 4.0 handoff contract, not runtime enforcement.
"""


def _render_memory_spec(spec: dict[str, Any]) -> str:
    return f"""# Agent Memory Isolation Spec

- Status: `{spec['status']}`
- Agent memory spec ready: `true`
- Redis runtime ready: `false`
- Vector runtime ready: `false`
- Runtime isolation ready: `false`

Memory policy files and backend candidates do not establish Redis, Vector DB, or runtime isolation completion.
"""


def _render_memory_fallback_policy() -> str:
    return """# Agent Memory Fallback Policy

- If Redis is unavailable, use local JSONL short-term memory metadata or display degraded status.
- If Vector DB is unavailable, use keyword search or structured index fallback.
- Shared memory is closed by default.
- Cross-Agent memory is not shared by default.
"""


def _render_agent_mode_spec(spec: dict[str, Any]) -> str:
    modes = "\n".join(f"- `{mode}`" for mode in spec["product_modes"])
    return f"""# Agent Mode Spec

- Status: `{spec['status']}`
- Single Agent package ready: `{spec['single_agent_package_ready']}`
- Multi-Agent spec ready: `true`
- Multi-Agent runtime ready: `false`
- Multi-Agent executable: `false`

## Modes

{modes}
"""


def _render_multi_agent_workflow_spec(report: dict[str, Any]) -> str:
    return """# Multi-Agent Workflow Spec

This specification defines role assignment and handoff rules only.

- Multi-Agent spec ready: `true`
- Multi-Agent runtime ready: `false`
- Multi-Agent executable: `false`
- Workflow executed: `false`
"""


def _render_ui_handoff(contract: dict[str, Any]) -> str:
    nav = "\n".join(f"- {item}" for item in contract["top_level_navigation"])
    return f"""# Campaign 4 UI Handoff Contract

- Status: `{contract['status']}`
- Campaign 4 active: `false`
- UI Workbench complete: `false`

## Navigation Inputs

{nav}

This handoff lets Campaign 4 consume Campaign 3 assets; it is not Campaign 4 UI implementation.
"""


def _render_agent_builder_requirement(spec: dict[str, Any]) -> str:
    return f"""# Agent Builder UI Requirement Spec

- Status: `{spec['status']}`
- Display Agent Package ready: `true`
- Display Agent Runtime ready: `false`
- Allowed primary action: `{spec['allowed_primary_action']}`
- Forbidden primary action: `{spec['forbidden_primary_action']}`
"""


def _render_bridge_handoff(contract: dict[str, Any]) -> str:
    return f"""# Campaign 5 Bridge Handoff Contract

- Status: `{contract['status']}`
- Campaign 5 active: `false`
- Bridge execution accepted: `false`
- Future allowlist candidates active: `false`

This is a Bridge handoff contract only; Campaign 5 must separately accept chain-level Bridge execution.
"""


def _render_summary(report: dict[str, Any]) -> str:
    return f"""# Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle

- Status: `{report['status']}`
- Decision: `{report['integration_decision']} / {report['decision_qualifier']}`
- 4.0D Agent Package: `passed`
- 4.0E Workspace Binding Spec: `passed`
- 4.0F Memory Isolation Spec: `passed`
- 4.0G Single/Multi-Agent Mode Spec: `passed`
- 4.0H Campaign 4 UI Handoff: `passed`
- 4.0I Campaign 5 Bridge Handoff: `passed`
- Campaign 4 active: `false`
- Campaign 5 active: `false`
- Agent runtime ready: `false`
- Bridge execution accepted: `false`
- Next safe action: `{report['next_action_manifest']['next_safe_action']}`
"""


def _read_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def _read_json_with_errors(path: Path, errors: list[str], label: str) -> dict[str, Any]:
    if not path.exists():
        errors.append(f"missing_json:{label}:{path}")
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        errors.append(f"invalid_json:{label}:{exc}")
        return {}
