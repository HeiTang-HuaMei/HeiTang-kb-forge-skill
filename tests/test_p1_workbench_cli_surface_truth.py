from heitang_kb_forge.workbench.cli_surface_truth import audit_p1_ready_core_cli_surface
from heitang_kb_forge.workbench import make_p1_workbench_bundle


def test_all_ready_core_cli_actions_match_registered_cli_surface():
    report = audit_p1_ready_core_cli_surface()

    assert report["status"] == "pass"
    assert report["ready_core_cli_action_count"] >= 50
    assert report["drift_count"] == 0
    assert report["drifts"] == []
    assert "build" in report["unique_commands"]


def test_planned_adapter_and_provider_secret_network_actions_are_not_misclassified():
    bundle = make_p1_workbench_bundle()
    planned_ready = [
        action.action_id
        for action in bundle.action_contracts
        if action.status == "ready" and action.command_kind == "planned_adapter"
    ]
    explicit_config_ready = [
        action.action_id
        for action in bundle.action_contracts
        if action.status == "ready"
        and (
            action.requires_explicit_user_config
            or set(action.error_codes) & {"provider_auth_failed", "secret_risk", "network_unavailable"}
        )
    ]

    assert planned_ready == []
    assert {"llm_provider_validate", "provider_redaction_check", "offline_fallback_status"} <= set(explicit_config_ready)
