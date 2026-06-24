from heitang_kb_forge.task_mode_router import route_task_mode


def test_task_mode_router_selects_lite_for_small_change():
    decision = route_task_mode({"task_text": "fix typo", "changed_file_count": 1, "estimated_minutes": 10})

    assert decision.mode == "task_gate_lite"
    assert decision.auto_execute_allowed is True
    assert decision.owner_review_required is False
    assert decision.reason_codes == ["small_change"]


def test_task_mode_router_selects_long_build_for_runtime_blackbox_work():
    decision = route_task_mode(
        {
            "task_text": "implement runtime flow",
            "changed_file_count": 5,
            "estimated_minutes": 90,
            "affects_runtime": True,
            "user_blackbox_required": True,
        }
    )

    assert decision.mode == "night_long_build"
    assert "runtime_path_affected" in decision.reason_codes
    assert "blackbox_required" in decision.reason_codes
    assert "matrix" in decision.validation_focus


def test_task_mode_router_routes_stage_gate_to_owner_review():
    decision = route_task_mode({"task_text": "run release gate", "stage_gate_requested": True})

    assert decision.mode == "stage_gate_review"
    assert decision.auto_execute_allowed is False
    assert decision.owner_review_required is True


def test_task_mode_router_blocks_hard_risk_for_owner_decision():
    decision = route_task_mode({"task_text": "delete user data", "hard_blocker_risk": True})

    assert decision.mode == "owner_review_gate"
    assert decision.auto_execute_allowed is False
    assert decision.owner_review_required is True
    assert decision.reason_codes == ["hard_blocker_risk"]
