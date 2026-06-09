from __future__ import annotations

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workbench.cli_surface_truth import audit_p1_ready_core_cli_surface
from heitang_kb_forge.workbench.productization import make_p1_workbench_bundle


ACTION_CLASSIFICATIONS = [
    "executable_with_demo_input",
    "executable_with_generated_workspace",
    "executable_with_previous_artifact",
    "deterministic_smoke_only",
    "blocked_provider_required",
    "blocked_secret_required",
    "blocked_planned_adapter",
    "blocked_missing_safe_input",
    "blocked_unsafe_to_execute",
]

PROVIDER_SECRET_NETWORK_ERRORS = {"provider_auth_failed", "secret_risk", "network_unavailable"}
P1_RWF_V2_READY_ACTION_TARGET_COUNT = 57


def ready_core_cli_actions() -> list:
    bundle = make_p1_workbench_bundle()
    return [
        action
        for action in bundle.action_contracts
        if action.status == "ready" and action.command_kind == "core_cli"
    ]


def is_p1_v2_execution_target(action) -> bool:
    return (
        action.status == "ready"
        and action.command_kind == "core_cli"
        and not action.requires_explicit_user_config
        and not (set(action.error_codes) & PROVIDER_SECRET_NETWORK_ERRORS)
    )


def p1_v2_execution_target_actions() -> list:
    return [action for action in ready_core_cli_actions() if is_p1_v2_execution_target(action)]


def classify_ready_action(action) -> str:
    errors = set(action.error_codes)
    if action.command_kind == "planned_adapter":
        return "blocked_planned_adapter"
    if "secret_risk" in errors:
        return "blocked_secret_required"
    if action.requires_explicit_user_config or errors & {"provider_auth_failed", "network_unavailable"}:
        return "blocked_provider_required"
    if not action.command:
        return "blocked_missing_safe_input"
    if "<package>" in action.command or "<skill>" in action.command or "<agent>" in action.command:
        return "executable_with_previous_artifact"
    if "<old>" in action.command or "<new>" in action.command or "<packages>" in action.command:
        return "executable_with_previous_artifact"
    if "<workspace>" in action.command or "<repo>" in action.command:
        return "executable_with_generated_workspace"
    return "executable_with_demo_input"


def build_full_ready_action_matrix() -> dict:
    actions = ready_core_cli_actions()
    rows = [_matrix_row(action) for action in actions]
    target_rows = [row for row in rows if row["execution_target"]]
    command_surface = audit_p1_ready_core_cli_surface()
    status = (
        "pass"
        if len(target_rows) == P1_RWF_V2_READY_ACTION_TARGET_COUNT
        and command_surface["drift_count"] == 0
        and all(row["classification"] in ACTION_CLASSIFICATIONS for row in rows)
        else "fail"
    )
    return {
        "report_id": "p1_rwf_v2_full_ready_action_execution_matrix",
        "status": status,
        "ready_core_cli_action_count": len(rows),
        "execution_target_count": len(target_rows),
        "excluded_explicit_config_count": len(rows) - len(target_rows),
        "expected_execution_target_count": P1_RWF_V2_READY_ACTION_TARGET_COUNT,
        "command_surface_drift_count": command_surface["drift_count"],
        "classification_values": ACTION_CLASSIFICATIONS,
        "actions": rows,
        "tests_require_real_llm_api_network": False,
        "network_required": False,
    }


def write_full_ready_action_matrix(output) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    matrix = build_full_ready_action_matrix()
    write_json(output / "full_ready_action_execution_matrix.json", matrix)
    (output / "full_ready_action_execution_matrix.md").write_text(
        render_full_ready_action_matrix(matrix),
        encoding="utf-8",
    )
    return matrix


def render_full_ready_action_matrix(matrix: dict) -> str:
    rows = [
        "| Action | Target | Classification | Command |",
        "| --- | --- | --- | --- |",
    ]
    for action in matrix["actions"]:
        rows.append(
            f"| {action['action_id']} | {str(action['execution_target']).lower()} | "
            f"{action['classification']} | `{action['command']}` |"
        )
    return "\n".join(
        [
            "# P1-RWF-V2 Full Ready Action Execution Matrix",
            "",
            f"Status: {matrix['status']}",
            f"Ready/core_cli actions: {matrix['ready_core_cli_action_count']}",
            f"Execution targets: {matrix['execution_target_count']}",
            f"Command surface drift count: {matrix['command_surface_drift_count']}",
            "",
            *rows,
            "",
        ]
    )


def _matrix_row(action) -> dict:
    classification = classify_ready_action(action)
    execution_target = is_p1_v2_execution_target(action)
    blocked_reason = None
    if not execution_target:
        blocked_reason = _excluded_reason(action, classification)
    return {
        "action_id": action.action_id,
        "page_id": action.page_id,
        "status": action.status,
        "command_kind": action.command_kind,
        "command": action.command,
        "classification": classification,
        "desktop_enabled": execution_target,
        "execution_target": execution_target,
        "requires_explicit_user_config": action.requires_explicit_user_config,
        "expected_reports": action.report_ids,
        "expected_artifacts": action.artifact_ids,
        "error_codes": action.error_codes,
        "blocked_reason": blocked_reason,
    }


def _excluded_reason(action, classification: str) -> str:
    if classification == "blocked_secret_required":
        return "Excluded from the 57 local execution targets because secret-risk handling must remain blocked."
    if classification == "blocked_provider_required":
        return "Excluded from the 57 local execution targets because provider, network, or explicit user config is required."
    if classification == "blocked_planned_adapter":
        return "Excluded because planned adapters are not marked ready in P1."
    return "Excluded because no safe deterministic local input is available."
