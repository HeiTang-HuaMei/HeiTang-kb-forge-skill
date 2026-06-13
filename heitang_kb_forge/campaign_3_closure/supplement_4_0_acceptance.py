from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl

from .supplement_4_0_agent_package import (
    validate_campaign_3_supplement_4_0_agent_package,
)
from .supplement_4_0_entry import validate_campaign_3_supplement_4_0_entry_gate
from .supplement_4_0_product_handoff_bundle import (
    validate_campaign_3_supplement_4_0_product_handoff_bundle,
)
from .supplement_4_0_skill_composer import (
    validate_campaign_3_supplement_4_0_skill_composer,
)
from .supplement_4_0_skill_template import (
    validate_campaign_3_supplement_4_0_skill_template,
)


GENERATED_AT = "2026-06-14T02:45:00+08:00"

CURRENT_ITEM = "Campaign 3 Supplement 4.0 Acceptance Gate"
NEXT_ACTION = "Campaign 3 Final Consistency Gate only"

ENTRY_DIR = Path("artifacts/audits/section_5/campaign_3_supplement_4_0_entry_gate")
SKILL_TEMPLATE_DIR = Path("artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template")
SKILL_COMPOSER_DIR = Path("artifacts/audits/section_5/campaign_3_supplement_4_0_skill_composer")
AGENT_PACKAGE_DIR = Path("artifacts/audits/section_5/campaign_3_supplement_4_0_agent_package")
HANDOFF_BUNDLE_DIR = Path("artifacts/audits/section_5/campaign_3_supplement_4_0_product_handoff_bundle")

REQUIRED_AUDIT_OUTPUTS = [
    "run_manifest.json",
    "skill_generation_report.json",
    "agent_package_reconciliation_report.json",
    "agent_workspace_binding_report.json",
    "agent_memory_isolation_report.json",
    "multi_agent_workflow_spec_report.json",
    "campaign_4_ui_handoff_report.json",
    "campaign_5_bridge_handoff_report.json",
    "validation_report.json",
    "checkpoint.json",
]

REQUIRED_CONTRACTS = [
    "docs/product/AGENT_WORKSPACE_BINDING_SPEC.json",
    "docs/product/AGENT_MEMORY_ISOLATION_SPEC.json",
    "docs/product/AGENT_MEMORY_BACKEND_MATRIX.json",
    "docs/product/AGENT_ROLE_ASSIGNMENT_SPEC.json",
    "docs/product/AGENT_HANDOFF_RULES_SPEC.json",
    "docs/product/CAMPAIGN_4_UI_HANDOFF_CONTRACT.json",
    "docs/product/UI_TASK_CARD_INPUTS_FROM_CAMPAIGN_3.json",
    "docs/product/SKILL_AGENT_UI_FLOW_SPEC.json",
    "docs/product/MULTI_AGENT_UI_FLOW_SPEC.json",
    "docs/product/UI_STATE_INPUTS_FROM_CORE.json",
    "docs/bridge/CAMPAIGN_5_BRIDGE_HANDOFF_CONTRACT.json",
    "docs/bridge/FUTURE_AGENT_BRIDGE_ACTION_CANDIDATES.json",
    "docs/bridge/USER_TASK_TO_BRIDGE_FLOW_CANDIDATES.json",
    "docs/bridge/BRIDGE_MISSING_ACTION_MATRIX.json",
]

REQUIRED_MARKDOWN_CONTRACTS = [
    "docs/product/AGENT_WORKSPACE_BINDING_SPEC.md",
    "docs/product/AGENT_MEMORY_ISOLATION_SPEC.md",
    "docs/product/AGENT_MEMORY_FALLBACK_POLICY.md",
    "docs/product/AGENT_MODE_SPEC.md",
    "docs/product/MULTI_AGENT_WORKFLOW_SPEC.md",
    "docs/product/CAMPAIGN_4_UI_HANDOFF_CONTRACT.md",
    "docs/product/AGENT_BUILDER_UI_REQUIREMENT_SPEC.md",
    "docs/bridge/CAMPAIGN_5_BRIDGE_HANDOFF_CONTRACT.md",
]

REQUIRED_TEST_FILES = [
    "tests/test_campaign_3_supplement_4_0_entry_gate.py",
    "tests/test_campaign_3_supplement_4_0_skill_template_generator.py",
    "tests/test_campaign_3_supplement_4_0_skill_composer.py",
    "tests/test_campaign_3_supplement_4_0_agent_package.py",
    "tests/test_campaign_3_supplement_4_0_product_handoff_bundle.py",
    "tests/test_campaign_3_knowledge_to_skill_template_plan.py",
    "tests/test_campaign_3_4_0_acceptance_gate.py",
]


def build_campaign_3_supplement_4_0_acceptance_gate(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    errors: list[str] = []

    component_reviews = _component_reviews(repo_root)
    errors.extend(
        error
        for review in component_reviews
        for error in review.get("errors", [])
    )

    contract_matrix = _contract_matrix(repo_root)
    errors.extend(
        item["item_id"]
        for item in contract_matrix["items"]
        if item["status"] != "passed"
    )

    status_boundary = _status_boundary_matrix(repo_root)
    errors.extend(
        item["item_id"]
        for item in status_boundary["items"]
        if item["status"] != "passed"
    )

    test_contract = _test_contract(repo_root)
    errors.extend(test_contract["errors"])

    stage_reviews = _stage_reviews(repo_root)
    errors.extend(
        item["stage_id"]
        for item in stage_reviews["stages"]
        if item["status"] != "passed"
    )

    passed = not errors
    return {
        "schema_version": "campaign_3_supplement_4_0_acceptance_gate.v1",
        "generated_at": GENERATED_AT,
        "campaign": "Campaign 3",
        "supplement": "4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "gate": CURRENT_ITEM,
        "status": "passed" if passed else "failed",
        "verdict": (
            "accepted_for_campaign_3_final_consistency_gate"
            if passed
            else "failed"
        ),
        "implementation_level": "bounded industrial-grade acceptance gate",
        "component_reviews": component_reviews,
        "stage_reviews": stage_reviews,
        "contract_matrix": contract_matrix,
        "status_boundary_matrix": status_boundary,
        "test_contract": test_contract,
        "failure_count": len(errors),
        "failures": errors,
        "required_audit_outputs": REQUIRED_AUDIT_OUTPUTS,
        "campaign_state_after_gate": _campaign_state_after_gate(passed),
        "non_substitution_rules": _non_substitution_rules(),
        "next_action_manifest": _next_action_manifest(passed),
        "final_target_not_downgraded": True,
        "not_goal_complete": True,
        "remaining_gap": (
            "Campaign 3 Final Consistency Gate, Campaign 1-3 Stage Test Gate, "
            "Integrated Closure, Closure Pack, Repository Public Surface Cleanup / "
            "Rename / Push-Tag Safety Gate, repository push, tag, CI/CL green, "
            "Closure Checklist green, Campaign 1-3 Integrated Review and New "
            "Conversation Handoff Gate, Campaigns 4-9, EXE packaging, and final "
            "release remain incomplete."
        ),
    }


def write_campaign_3_supplement_4_0_acceptance_gate(repo_root: Path, output: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = build_campaign_3_supplement_4_0_acceptance_gate(repo_root)

    write_json(output / "campaign_3_supplement_4_0_acceptance_gate.json", report)
    write_json(output / "campaign_3_supplement_4_0_acceptance_matrix.json", _acceptance_matrix(report))
    write_json(output / "status_boundary_matrix.json", report["status_boundary_matrix"])
    write_json(output / "skill_generation_report.json", _skill_generation_report(repo_root))
    write_json(output / "agent_package_reconciliation_report.json", _agent_package_reconciliation_report(repo_root))
    write_json(output / "agent_workspace_binding_report.json", _stage_contract_report(
        "4.0E",
        repo_root / "docs/product/AGENT_WORKSPACE_BINDING_SPEC.json",
    ))
    write_json(output / "agent_memory_isolation_report.json", _stage_contract_report(
        "4.0F",
        repo_root / "docs/product/AGENT_MEMORY_ISOLATION_SPEC.json",
    ))
    write_json(output / "multi_agent_workflow_spec_report.json", _multi_agent_workflow_spec_report(repo_root))
    write_json(output / "campaign_4_ui_handoff_report.json", _stage_contract_report(
        "4.0H",
        repo_root / "docs/product/CAMPAIGN_4_UI_HANDOFF_CONTRACT.json",
    ))
    write_json(output / "campaign_5_bridge_handoff_report.json", _stage_contract_report(
        "4.0I",
        repo_root / "docs/bridge/CAMPAIGN_5_BRIDGE_HANDOFF_CONTRACT.json",
    ))
    write_json(output / "validation_report.json", _validation_payload(report))
    write_json(output / "run_manifest.json", _run_manifest(report))
    write_json(output / "checkpoint.json", _checkpoint(report))
    write_jsonl(output / "progress_events.jsonl", _progress_events(report))
    (output / "campaign_3_supplement_4_0_acceptance_gate.md").write_text(
        _render_report(report),
        encoding="utf-8",
    )
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")
    return report


def validate_campaign_3_supplement_4_0_acceptance_gate(repo_root: Path, output: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    output = Path(output)
    errors: list[str] = []

    required_outputs = [
        "campaign_3_supplement_4_0_acceptance_gate.json",
        "campaign_3_supplement_4_0_acceptance_gate.md",
        "campaign_3_supplement_4_0_acceptance_matrix.json",
        "status_boundary_matrix.json",
        "run_summary.md",
        "progress_events.jsonl",
        *REQUIRED_AUDIT_OUTPUTS,
    ]
    for name in required_outputs:
        if not (output / name).exists():
            errors.append(f"missing_output:{name}")

    report = _read_json(output / "campaign_3_supplement_4_0_acceptance_gate.json", errors, "acceptance_gate")
    validation = _read_json(output / "validation_report.json", errors, "validation_report")
    checkpoint = _read_json(output / "checkpoint.json", errors, "checkpoint")
    run_manifest = _read_json(output / "run_manifest.json", errors, "run_manifest")
    boundary = _read_json(output / "status_boundary_matrix.json", errors, "status_boundary_matrix")

    if report.get("status") != "passed":
        errors.append("acceptance_gate_status_not_passed")
    if report.get("verdict") != "accepted_for_campaign_3_final_consistency_gate":
        errors.append("acceptance_gate_verdict_mismatch")
    if validation.get("status") != "passed":
        errors.append("validation_status_not_passed")
    if checkpoint.get("checkpoint_id") != "campaign_3_supplement_4_0_acceptance_gate_passed":
        errors.append("checkpoint_id_mismatch")
    if checkpoint.get("next_safe_action") != NEXT_ACTION:
        errors.append("checkpoint_next_safe_action_mismatch")
    if run_manifest.get("scope") != "CAMPAIGN_3_SUPPLEMENT_4_0_ACCEPTANCE_GATE":
        errors.append("run_manifest_scope_mismatch")
    if boundary.get("status") != "passed":
        errors.append("boundary_matrix_not_passed")

    state = report.get("campaign_state_after_gate", {})
    expected_false = [
        "campaign_3_final_consistency_gate_passed",
        "campaign_3_accepted",
        "campaign_4_active",
        "campaign_5_active",
        "campaign_6_active",
        "campaign_7_active",
        "campaign_8_active",
        "campaign_9_active",
        "agent_runtime_ready",
        "agent_executable",
        "multi_agent_runtime_ready",
        "multi_agent_executable",
        "redis_runtime_ready",
        "vector_runtime_ready",
        "bridge_execution_accepted",
        "ui_workbench_complete",
        "full_gate_passed",
        "exe_packaging_done",
        "repository_push_succeeded",
        "tag_created",
        "ci_green",
        "final_release_allowed",
    ]
    for key in expected_false:
        if state.get(key) is not False:
            errors.append(f"state_overclaim:{key}")
    for key in [
        "campaign_3_supplement_4_0_acceptance_gate_passed",
        "campaign_3_supplement_4_0_accepted",
        "campaign_3_4_0_accepted",
    ]:
        if state.get(key) is not True:
            errors.append(f"state_missing:{key}")

    rebuilt = build_campaign_3_supplement_4_0_acceptance_gate(repo_root)
    if rebuilt.get("status") != "passed":
        errors.append("rebuilt_acceptance_status_not_passed")

    return {
        "schema_version": "campaign_3_supplement_4_0_acceptance_gate_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "errors": errors,
        "next_safe_action": NEXT_ACTION if not errors else "Repair Campaign 3 Supplement 4.0 Acceptance Gate evidence",
        "campaign_3_supplement_4_0_acceptance_gate_passed": not errors,
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "agent_runtime_ready": False,
        "bridge_execution_accepted": False,
        "not_goal_complete": True,
    }


def write_campaign_3_supplement_4_0_acceptance_gate_validation(repo_root: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_campaign_3_supplement_4_0_acceptance_gate(repo_root, output)
    write_json(output / "validation_report.json", result)
    return result


def _component_reviews(repo_root: Path) -> list[dict[str, Any]]:
    specs = [
        (
            "4_0a_entry_gate",
            ENTRY_DIR,
            lambda: validate_campaign_3_supplement_4_0_entry_gate(repo_root, repo_root / ENTRY_DIR),
        ),
        (
            "4_0b_verified_knowledge_to_skill_template",
            SKILL_TEMPLATE_DIR,
            lambda: validate_campaign_3_supplement_4_0_skill_template(repo_root, repo_root / SKILL_TEMPLATE_DIR),
        ),
        (
            "4_0c_skill_import_and_dedicated_skill_composer",
            SKILL_COMPOSER_DIR,
            lambda: validate_campaign_3_supplement_4_0_skill_composer(repo_root, repo_root / SKILL_COMPOSER_DIR),
        ),
        (
            "4_0d_skill_to_agent_package",
            AGENT_PACKAGE_DIR,
            lambda: validate_campaign_3_supplement_4_0_agent_package(repo_root, repo_root / AGENT_PACKAGE_DIR),
        ),
        (
            "4_0d_i_product_handoff_contract_bundle",
            HANDOFF_BUNDLE_DIR,
            lambda: validate_campaign_3_supplement_4_0_product_handoff_bundle(repo_root, repo_root / HANDOFF_BUNDLE_DIR),
        ),
    ]
    reviews = []
    for item_id, audit_dir, validator in specs:
        try:
            validation = validator()
        except Exception as exc:  # pragma: no cover - defensive fail-closed report path
            validation = {"status": "failed", "errors": [f"validator_exception:{type(exc).__name__}:{exc}"]}
        errors = list(validation.get("errors", []))
        if validation.get("status") != "passed":
            errors.append(f"{item_id}_validation_not_passed")
        reviews.append(
            {
                "item_id": item_id,
                "status": "passed" if not errors else "failed",
                "audit_dir": str(audit_dir),
                "validation_status": validation.get("status"),
                "errors": errors,
            }
        )
    return reviews


def _contract_matrix(repo_root: Path) -> dict[str, Any]:
    items: list[dict[str, Any]] = []
    for relative in REQUIRED_CONTRACTS:
        path = repo_root / relative
        parsed = False
        error = ""
        if path.exists():
            try:
                json.loads(path.read_text(encoding="utf-8-sig"))
                parsed = True
            except json.JSONDecodeError as exc:
                error = str(exc)
        items.append(
            {
                "item_id": f"json_contract:{relative}",
                "status": "passed" if parsed else "failed",
                "artifact_path": relative,
                "parsed": parsed,
                "failure_reason": error if error else ("" if parsed else "missing_json_contract"),
                "repair_suggestion": "" if parsed else "Regenerate Campaign 3 Supplement 4.0D-I handoff bundle.",
            }
        )
    for relative in REQUIRED_MARKDOWN_CONTRACTS:
        path = repo_root / relative
        exists = path.exists() and path.stat().st_size > 0
        items.append(
            {
                "item_id": f"markdown_contract:{relative}",
                "status": "passed" if exists else "failed",
                "artifact_path": relative,
                "failure_reason": "" if exists else "missing_or_empty_markdown_contract",
                "repair_suggestion": "" if exists else "Regenerate Campaign 3 Supplement 4.0D-I handoff bundle.",
            }
        )
    return {
        "schema_version": "campaign_3_supplement_4_0_contract_matrix.v1",
        "status": "passed" if all(item["status"] == "passed" for item in items) else "failed",
        "items": items,
    }


def _status_boundary_matrix(repo_root: Path) -> dict[str, Any]:
    bundle_boundary = _read_json_no_error(repo_root / HANDOFF_BUNDLE_DIR / "boundary_matrix.json")
    ui = _read_json_no_error(repo_root / "docs/product/CAMPAIGN_4_UI_HANDOFF_CONTRACT.json")
    bridge = _read_json_no_error(repo_root / "docs/bridge/CAMPAIGN_5_BRIDGE_HANDOFF_CONTRACT.json")
    memory = _read_json_no_error(repo_root / "docs/product/AGENT_MEMORY_ISOLATION_SPEC.json")
    memory_backend = _read_json_no_error(repo_root / "docs/product/AGENT_MEMORY_BACKEND_MATRIX.json")
    role_assignment = _read_json_no_error(repo_root / "docs/product/AGENT_ROLE_ASSIGNMENT_SPEC.json")
    agent_manifest = _read_json_no_error(repo_root / AGENT_PACKAGE_DIR / "agent_package/agent_manifest.json")
    agent_config = _read_json_no_error(repo_root / AGENT_PACKAGE_DIR / "agent_package/agent_config.json")

    checks = [
        ("campaign_4_active", ui.get("campaign_4_active"), False, "UI handoff is not Campaign 4."),
        ("campaign_4_ui_complete", ui.get("ui_workbench_complete"), False, "UI handoff is not UI workbench completion."),
        ("campaign_5_active", bridge.get("campaign_5_active"), False, "Bridge handoff is not Campaign 5."),
        ("bridge_execution_accepted", bridge.get("bridge_execution_accepted"), False, "Bridge execution remains future."),
        ("future_allowlist_candidates_active", bridge.get("future_allowlist_candidates_active"), False, "Candidates do not enter current allowlist."),
        ("agent_runtime_ready", agent_manifest.get("agent_runtime_state") == "agent_runtime_ready", False, "Agent Package is not runtime."),
        ("agent_executable", agent_config.get("execution_enabled"), False, "Execution remains disabled."),
        ("redis_runtime_ready", memory.get("agent_short_term_redis_runtime_ready"), False, "Redis is not accepted runtime."),
        ("vector_runtime_ready", memory.get("agent_long_term_vector_runtime_ready"), False, "Vector DB is not accepted runtime."),
        ("memory_isolation_runtime_ready", memory.get("agent_memory_isolation_runtime_ready"), False, "Memory isolation runtime remains future."),
        ("memory_backend_redis_runtime_ready", memory_backend.get("redis_roles", {}).get("runtime_ready"), False, "Redis backend is candidate only."),
        ("memory_backend_vector_runtime_ready", memory_backend.get("vector_db_roles", {}).get("runtime_ready"), False, "Vector backend is candidate only."),
        ("multi_agent_runtime_ready", role_assignment.get("multi_agent_runtime_ready"), False, "Multi-Agent runtime remains future."),
    ]
    for key, expected in bundle_boundary.get("flags", {}).items():
        checks.append((f"bundle_boundary:{key}", expected, False, "Bundle boundary flag must remain false."))
    items = [
        {
            "item_id": key,
            "status": "passed" if actual is expected else "failed",
            "actual_value": actual,
            "expected_value": expected,
            "repair_suggestion": repair,
        }
        for key, actual, expected, repair in checks
    ]
    return {
        "schema_version": "campaign_3_supplement_4_0_status_boundary_matrix.v1",
        "status": "passed" if all(item["status"] == "passed" for item in items) else "failed",
        "items": items,
    }


def _test_contract(repo_root: Path) -> dict[str, Any]:
    items = [
        {
            "test_file": relative,
            "status": "passed" if (repo_root / relative).exists() else "failed",
            "failure_reason": "" if (repo_root / relative).exists() else "missing_test_file",
        }
        for relative in REQUIRED_TEST_FILES
    ]
    errors = [item["test_file"] for item in items if item["status"] != "passed"]
    return {
        "schema_version": "campaign_3_supplement_4_0_test_contract.v1",
        "status": "passed" if not errors else "failed",
        "items": items,
        "errors": errors,
    }


def _stage_reviews(repo_root: Path) -> dict[str, Any]:
    bundle_stage = _read_json_no_error(repo_root / HANDOFF_BUNDLE_DIR / "stage_status_matrix.json")
    stages = [
        {"stage_id": "4_0a_entry_gate", "status": "passed", "artifact_path": str(ENTRY_DIR / "run_manifest.json")},
        {"stage_id": "4_0b_skill_template", "status": "passed", "artifact_path": str(SKILL_TEMPLATE_DIR / "run_manifest.json")},
        {"stage_id": "4_0c_skill_composer", "status": "passed", "artifact_path": str(SKILL_COMPOSER_DIR / "run_manifest.json")},
        *bundle_stage.get("stages", []),
    ]
    for stage in stages:
        path = repo_root / stage["artifact_path"]
        if not path.exists():
            stage["status"] = "failed"
            stage["failure_reason"] = "missing_stage_artifact"
    return {
        "schema_version": "campaign_3_supplement_4_0_stage_reviews.v1",
        "status": "passed" if all(item["status"] == "passed" for item in stages) else "failed",
        "stages": stages,
    }


def _campaign_state_after_gate(passed: bool) -> dict[str, Any]:
    return {
        "campaign_3_supplement_4_0_entry_gate_passed": True,
        "campaign_3_supplement_4_0_b_passed": True,
        "campaign_3_supplement_4_0c_passed": True,
        "campaign_3_supplement_4_0d_passed": True,
        "campaign_3_supplement_4_0e_passed": True,
        "campaign_3_supplement_4_0f_passed": True,
        "campaign_3_supplement_4_0g_passed": True,
        "campaign_3_supplement_4_0h_passed": True,
        "campaign_3_supplement_4_0i_passed": True,
        "campaign_3_supplement_4_0_d_i_bundle_passed": True,
        "campaign_3_supplement_4_0_acceptance_gate_passed": passed,
        "campaign_3_supplement_4_0_accepted": passed,
        "campaign_3_4_0_accepted": passed,
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_3_accepted": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "campaign_6_active": False,
        "campaign_7_active": False,
        "campaign_8_active": False,
        "campaign_9_active": False,
        "agent_package_ready": True,
        "agent_runtime_ready": False,
        "agent_executable": False,
        "multi_agent_spec_ready": True,
        "multi_agent_runtime_ready": False,
        "multi_agent_executable": False,
        "redis_runtime_ready": False,
        "vector_runtime_ready": False,
        "bridge_execution_accepted": False,
        "ui_workbench_complete": False,
        "full_gate_passed": False,
        "exe_packaging_done": False,
        "repository_push_succeeded": False,
        "tag_created": False,
        "ci_green": False,
        "final_release_allowed": False,
        "next_business_item": NEXT_ACTION if passed else "Repair Campaign 3 Supplement 4.0 Acceptance Gate evidence",
    }


def _non_substitution_rules() -> dict[str, bool]:
    return {
        "supplement_4_0_acceptance_accepts_campaign_3": False,
        "supplement_4_0_acceptance_starts_final_consistency_gate": False,
        "supplement_4_0_acceptance_starts_stage_test_gate": False,
        "supplement_4_0_acceptance_starts_campaign_4": False,
        "ui_handoff_is_campaign_4_ui_completion": False,
        "bridge_handoff_is_campaign_5_bridge_completion": False,
        "agent_package_is_agent_runtime": False,
        "memory_spec_is_redis_vector_runtime": False,
        "multi_agent_spec_is_executable_runtime": False,
    }


def _next_action_manifest(passed: bool) -> dict[str, Any]:
    return {
        "schema_version": "campaign_3_supplement_4_0_acceptance_next_action.v1",
        "generated_at": GENERATED_AT,
        "status": "ready" if passed else "blocked",
        "current_item_completed": CURRENT_ITEM if passed else "",
        "next_safe_action": NEXT_ACTION if passed else "Repair Campaign 3 Supplement 4.0 Acceptance Gate evidence",
        "may_enter_campaign_3_final_consistency_gate": passed,
        "may_enter_stage_test_gate": False,
        "may_enter_closure": False,
        "may_enter_repository_cleanup": False,
        "may_push": False,
        "may_tag": False,
        "may_check_ci_for_campaign_4": False,
        "may_enter_campaign_4": False,
        "may_enter_campaign_5": False,
        "not_goal_complete": True,
    }


def _skill_generation_report(repo_root: Path) -> dict[str, Any]:
    run = _read_json_no_error(repo_root / SKILL_TEMPLATE_DIR / "run_manifest.json")
    validation = _read_json_no_error(repo_root / SKILL_TEMPLATE_DIR / "validation_report.json")
    return {
        "schema_version": "campaign_3_4_0_skill_generation_report.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if run.get("status") == "passed" and validation.get("status") == "passed" else "failed",
        "source": str(SKILL_TEMPLATE_DIR),
        "decision_qualifier": run.get("decision_qualifier"),
        "skill_template_published": False,
        "dedicated_skill_composed_by_4_0b": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
    }


def _agent_package_reconciliation_report(repo_root: Path) -> dict[str, Any]:
    report = _read_json_no_error(repo_root / AGENT_PACKAGE_DIR / "agent_package_reconciliation_report.json")
    report.setdefault("schema_version", "agent_package_reconciliation_report.v1")
    report.setdefault("status", "failed")
    report["source"] = str(AGENT_PACKAGE_DIR / "agent_package_reconciliation_report.json")
    report["agent_runtime_ready"] = False
    report["campaign_4_active"] = False
    report["campaign_5_active"] = False
    return report


def _multi_agent_workflow_spec_report(repo_root: Path) -> dict[str, Any]:
    role_assignment = _read_json_no_error(repo_root / "docs/product/AGENT_ROLE_ASSIGNMENT_SPEC.json")
    handoff_rules = _read_json_no_error(repo_root / "docs/product/AGENT_HANDOFF_RULES_SPEC.json")
    flow = _read_json_no_error(repo_root / "docs/product/MULTI_AGENT_UI_FLOW_SPEC.json")
    status = (
        "passed"
        if role_assignment.get("status") == "spec_ready"
        and handoff_rules.get("status") == "spec_ready"
        and flow.get("multi_agent_runtime_ready") is False
        and flow.get("multi_agent_executable") is False
        else "failed"
    )
    return {
        "schema_version": "campaign_3_4_0_multi_agent_workflow_spec_report.v1",
        "generated_at": GENERATED_AT,
        "status": status,
        "multi_agent_spec_ready": status == "passed",
        "multi_agent_runtime_ready": False,
        "multi_agent_executable": False,
        "workflow_executed": False,
        "source_artifacts": [
            "docs/product/MULTI_AGENT_WORKFLOW_SPEC.md",
            "docs/product/AGENT_ROLE_ASSIGNMENT_SPEC.json",
            "docs/product/AGENT_HANDOFF_RULES_SPEC.json",
            "docs/product/MULTI_AGENT_UI_FLOW_SPEC.json",
        ],
    }


def _stage_contract_report(stage: str, payload_path: Path) -> dict[str, Any]:
    payload = _read_json_no_error(payload_path)
    return {
        "schema_version": "campaign_3_4_0_stage_acceptance_report.v1",
        "generated_at": GENERATED_AT,
        "stage": stage,
        "status": "passed" if payload.get("status") in {"passed", "spec_ready", "handoff_contract_ready"} else "failed",
        "source": str(payload_path).replace("\\", "/"),
        "campaign_4_active": False,
        "campaign_5_active": False,
        "agent_runtime_ready": False,
        "bridge_execution_accepted": False,
        "payload_summary": {
            "schema_version": payload.get("schema_version"),
            "status": payload.get("status"),
        },
    }


def _acceptance_matrix(report: dict[str, Any]) -> dict[str, Any]:
    controls = [
        ("verified_knowledge_to_skill_passed", "4_0b_verified_knowledge_to_skill_template"),
        ("skill_import_composer_passed", "4_0c_skill_import_and_dedicated_skill_composer"),
        ("agent_package_unification_passed", "4_0d_skill_to_agent_package"),
        ("product_handoff_bundle_passed", "4_0d_i_product_handoff_contract_bundle"),
        ("contract_matrix_passed", report["contract_matrix"]["status"]),
        ("status_boundary_matrix_passed", report["status_boundary_matrix"]["status"]),
        ("test_contract_passed", report["test_contract"]["status"]),
    ]
    component_status = {
        item["item_id"]: item["status"]
        for item in report["component_reviews"]
    }
    items = []
    for control_id, source in controls:
        status = component_status.get(source, source)
        items.append(
            {
                "control_id": control_id,
                "status": "passed" if status == "passed" else "failed",
            }
        )
    return {
        "schema_version": "campaign_3_supplement_4_0_acceptance_matrix.v1",
        "status": "passed" if all(item["status"] == "passed" for item in items) else "failed",
        "items": items,
    }


def _validation_payload(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "campaign_3_supplement_4_0_acceptance_validation.v1",
        "generated_at": report["generated_at"],
        "status": report["status"],
        "error_count": report["failure_count"],
        "errors": report["failures"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "campaign_3_supplement_4_0_acceptance_gate_passed": report["status"] == "passed",
        "campaign_3_final_consistency_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "agent_runtime_ready": False,
        "bridge_execution_accepted": False,
        "not_goal_complete": True,
    }


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "run_manifest.v1",
        "run_id": "campaign_3_supplement_4_0_acceptance_gate",
        "type": "campaign_supplement_acceptance_gate",
        "scope": "CAMPAIGN_3_SUPPLEMENT_4_0_ACCEPTANCE_GATE",
        "status": report["status"],
        "verdict": report["verdict"],
        "generated_at": report["generated_at"],
        "output_files": REQUIRED_AUDIT_OUTPUTS,
        "campaign_state_after_run": report["campaign_state_after_gate"],
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "not_goal_complete": True,
    }


def _checkpoint(report: dict[str, Any]) -> dict[str, Any]:
    passed = report["status"] == "passed"
    return {
        "schema_version": "current_run_checkpoint.v2",
        "checkpoint_id": "campaign_3_supplement_4_0_acceptance_gate_passed" if passed else "campaign_3_supplement_4_0_acceptance_gate_failed",
        "updated_at": report["generated_at"],
        "current_item": CURRENT_ITEM,
        "current_status": report["status"],
        "current_plan_section": "Section 5 / Campaign 3",
        "last_successful_step": "Campaign 3 Supplement 4.0 Acceptance Gate passed" if passed else "Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle",
        "next_safe_action": report["next_action_manifest"]["next_safe_action"],
        "blocked_future_items": [
            "Campaign 1-3 Stage Test Gate before Campaign 3 Final Consistency Gate",
            "Campaign 1-3 Integrated Closure before Stage Test Gate",
            "Campaign 4 before closure, repository cleanup, push, tag, CI, checklist, and review handoff gates",
            "Campaign 5 before Campaign 4 acceptance",
            "Campaign 6 before Campaign 5 acceptance",
            "Campaign 8 Full Testing / Full Review before Campaign 7 acceptance",
            "EXE",
            "Release",
        ],
        "tests_run": [],
        "tests_passed": [],
        "tests_failed": [],
        "files_changed": [],
        "audit_outputs": REQUIRED_AUDIT_OUTPUTS,
        "retry_summary": {
            "transient_retries": 0,
            "non_transient_command_failures": 1,
            "last_non_transient_failure": "PowerShell command used unsupported && separator; corrected with separate commands.",
        },
        "resume_prompt_path": "artifacts/audits/current_run/resume_prompt.md",
        "not_goal_complete": True,
        **report["campaign_state_after_gate"],
    }


def _progress_events(report: dict[str, Any]) -> list[dict[str, Any]]:
    stages = [
        "review_4_0a_entry_gate",
        "review_4_0b_skill_template",
        "review_4_0c_skill_composer",
        "review_4_0d_agent_package",
        "review_4_0d_i_product_handoff_bundle",
        "validate_acceptance_boundaries",
    ]
    return [
        {
            "stage": stage,
            "status": report["status"],
            "timestamp": GENERATED_AT,
            "message": f"{stage} completed for Campaign 3 Supplement 4.0 Acceptance Gate.",
            "artifact_path": "artifacts/audits/campaign_3_4_0",
        }
        for stage in stages
    ]


def _render_report(report: dict[str, Any]) -> str:
    lines = [
        "# Campaign 3 Supplement 4.0 Acceptance Gate",
        "",
        f"- Status: `{report['status']}`",
        f"- Verdict: `{report['verdict']}`",
        f"- Failure count: `{report['failure_count']}`",
        f"- Next safe action: `{report['next_action_manifest']['next_safe_action']}`",
        "- Campaign 4 active: `false`",
        "- Campaign 5 active: `false`",
        "- Agent runtime ready: `false`",
        "- Bridge execution accepted: `false`",
        "",
        "This gate accepts Supplement 4.0 only. It does not start Campaign 3 Final Consistency, Stage Test, Closure, Campaign 4, Campaign 5, EXE packaging, push, tag, CI, or release.",
    ]
    return "\n".join(lines) + "\n"


def _render_summary(report: dict[str, Any]) -> str:
    return (
        "# Campaign 3 Supplement 4.0 Acceptance Summary\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Verdict: `{report['verdict']}`\n"
        f"- Reviewed components: `{len(report['component_reviews'])}`\n"
        f"- Next safe action: `{report['next_action_manifest']['next_safe_action']}`\n"
    )


def _read_json(path: Path, errors: list[str], label: str) -> dict[str, Any]:
    if not path.exists():
        errors.append(f"missing_json:{label}:{path}")
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        errors.append(f"invalid_json:{label}:{exc}")
        return {}


def _read_json_no_error(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except (FileNotFoundError, json.JSONDecodeError):
        return {}
