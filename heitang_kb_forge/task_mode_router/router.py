from heitang_kb_forge.schemas.task_mode_router_schema import (
    TaskModeRouterDecision,
    TaskModeRouterInput,
)


def route_task_mode(payload: TaskModeRouterInput | dict) -> TaskModeRouterDecision:
    data = payload if isinstance(payload, TaskModeRouterInput) else TaskModeRouterInput.model_validate(payload)
    reason_codes: list[str] = []

    if data.hard_blocker_risk:
        return _decision(
            "owner_review_gate",
            False,
            True,
            ["hard_blocker_risk"],
            ["owner_decision", "checkpoint", "failure_report"],
        )

    if data.stage_gate_requested or _contains_any(data.task_text, ["stage gate", "release gate", "owner review"]):
        return _decision(
            "stage_gate_review",
            False,
            True,
            ["stage_gate_requested"],
            ["status_consistency", "regression", "boundary_scan"],
        )

    if data.review_requested or _contains_any(data.task_text, ["review", "verify", "audit", "验收", "审查"]):
        return _decision(
            "review_verify",
            True,
            False,
            ["review_or_verify_requested"],
            ["findings", "evidence_paths", "residual_risk"],
        )

    if (
        data.estimated_minutes >= 120
        or data.changed_file_count >= 8
        or data.affects_ui
        or data.affects_runtime
        or data.user_blackbox_required
    ):
        if data.estimated_minutes >= 120:
            reason_codes.append("long_running_task")
        if data.changed_file_count >= 8:
            reason_codes.append("broad_file_surface")
        if data.affects_ui:
            reason_codes.append("ui_path_affected")
        if data.affects_runtime:
            reason_codes.append("runtime_path_affected")
        if data.user_blackbox_required:
            reason_codes.append("blackbox_required")
        return _decision("night_long_build", True, False, reason_codes, ["tests", "matrix", "checkpoint"])

    if data.changed_file_count <= 2 and data.estimated_minutes <= 30:
        return _decision("task_gate_lite", True, False, ["small_change"], ["narrow_check"])

    return _decision("standard_build", True, False, ["normal_build_scope"], ["unit_tests", "diff_review"])


def _decision(
    mode: str,
    auto_execute_allowed: bool,
    owner_review_required: bool,
    reason_codes: list[str],
    validation_focus: list[str],
) -> TaskModeRouterDecision:
    return TaskModeRouterDecision(
        mode=mode,
        auto_execute_allowed=auto_execute_allowed,
        owner_review_required=owner_review_required,
        reason_codes=reason_codes,
        validation_focus=validation_focus,
        summary=f"route to {mode} because {', '.join(reason_codes)}",
    )


def _contains_any(value: str, terms: list[str]) -> bool:
    lowered = str(value).lower()
    return any(term in lowered for term in terms)
