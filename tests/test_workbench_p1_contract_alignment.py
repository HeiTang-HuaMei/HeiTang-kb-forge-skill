import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKBENCH = ROOT / "web" / "workbench"
FIXTURE = ROOT / "examples" / "ui_mock_data" / "p1_core_contract_fixture.json"
REPORT = ROOT / "docs" / "audits" / "core_ui_acceptance" / "core_ui_acceptance_report.json"
CORE_COMMIT = "a793247ff8704275891ff9a1aefcb78888bcc9f2"


DEDICATED_ROUTES = {
    "workspace",
    "vector-hub-provider-storage",
    "skill-factory",
    "artifact-management",
    "error-repair-center",
    "operation-gate",
    "capability-matrix",
}


def load_fixture():
    return json.loads(FIXTURE.read_text(encoding="utf-8"))


def test_p1_core_contract_fixture_declares_source_and_counts():
    fixture = load_fixture()

    assert fixture["source"]["copied_from"] == "Core workbench-contracts --profile p1"
    assert fixture["source"]["core_commit"] == CORE_COMMIT
    assert fixture["not_v4_0_workbench_rc"] is True
    assert fixture["not_full_operation_yet"] is True
    assert fixture["p1_full_operation_gate_status"] == "blocked"
    assert fixture["counts"] == {
        "pages": 16,
        "ui_routes": 18,
        "actions": 110,
        "reports": 109,
        "artifacts": 101,
        "errors": 20,
        "templates": 6,
    }


def test_flutter_p1_asset_matches_ui_core_contract_fixture():
    flutter_asset = WORKBENCH / "flutter_app" / "assets" / "contracts" / "p1_core_contract_fixture.json"

    assert flutter_asset.exists()
    assert json.loads(flutter_asset.read_text(encoding="utf-8")) == load_fixture()


def test_dedicated_p1_routes_have_sidebar_and_renderers():
    contracts = json.loads((WORKBENCH / "contracts.json").read_text(encoding="utf-8"))
    app = (WORKBENCH / "src" / "app.js").read_text(encoding="utf-8")
    flutter_main = (WORKBENCH / "flutter_app" / "lib" / "main.dart").read_text(encoding="utf-8")
    route_ids = {page["id"] for page in contracts["pages"]}

    assert DEDICATED_ROUTES <= route_ids
    for route in DEDICATED_ROUTES:
        assert f'id: "{route}"' in app or f'"{route}"' in app
        assert f"WorkbenchPage('{route}'" in flutter_main

    assert '"operation-gate": renderOperationGate' in app
    assert '"capability-matrix": renderCapabilityMatrix' in app


def test_core_contract_ids_are_cross_referenced():
    fixture = load_fixture()
    action_ids = {action["action_id"] for action in fixture["actions"]}
    report_ids = {report["report_id"] for report in fixture["reports"]}
    artifact_ids = {artifact["artifact_id"] for artifact in fixture["artifacts"]}
    error_codes = {error["error_code"] for error in fixture["errors"]}
    task_statuses = set(fixture["task_schema"]["statuses"])

    assert {"workspace_inspect", "rag_query", "book_to_skill", "run_agent"} <= action_ids
    assert {"report_workspace_health", "report_p1_gate_summary"} <= report_ids
    assert {"artifact_workspace_registry_snapshot", "artifact_skill_package"} <= artifact_ids
    assert {"secret_risk", "provider_auth_failed"} <= error_codes
    assert task_statuses == {"queued", "running", "succeeded", "failed", "blocked", "cancelled", "timed_out", "review_required"}

    for area in fixture["capability_matrix"]:
        assert set(area["action_ids"]) <= action_ids
        assert set(area["report_ids"]) <= report_ids
        assert set(area["artifact_ids"]) <= artifact_ids
    for action in fixture["actions"]:
        assert set(action["report_ids"]) <= report_ids
        assert set(action["artifact_ids"]) <= artifact_ids
        assert set(action["error_codes"]) <= error_codes
        assert set(action["task_statuses"]) <= task_statuses


def test_corrected_core_cli_action_commands_are_synced():
    fixture = load_fixture()
    actions = {action["action_id"]: action for action in fixture["actions"]}

    assert actions["ocr_required_detection"]["command"] == "full-ocr-acceptance --source <source> --output <output>"
    assert actions["package_export"]["command"] == "export-platform --skill <skill> --output <output>"
    assert "--core-repo" not in actions["ocr_required_detection"]["command"]
    assert "--package" not in actions["package_export"]["command"]


def test_unsupported_actions_are_disabled_with_blocked_reason():
    fixture = load_fixture()
    disabled = [action for action in fixture["actions"] if not action["desktop_enabled"]]

    assert disabled
    assert any(action["desktop_blocked_reason"] == "planned_adapter" for action in disabled)
    assert any(action["desktop_blocked_reason"] == "provider_required" for action in disabled)
    assert any(action["desktop_blocked_reason"] == "secret_required" for action in disabled)
    assert any(action["desktop_blocked_reason"] == "mock_only" for action in disabled)
    assert all(action["web_enabled"] is False for action in fixture["actions"])
    assert any(action["web_blocked_reason"] == "web_local_cli_unsupported" for action in fixture["actions"])


def test_web_and_flutter_surface_consume_blocked_reasons_and_action_ids():
    app = (WORKBENCH / "src" / "app.js").read_text(encoding="utf-8")
    panel = (WORKBENCH / "flutter_app" / "lib" / "core_actions" / "core_action_panel.dart").read_text(encoding="utf-8")
    request_builder = (WORKBENCH / "flutter_app" / "lib" / "core_actions" / "workbench_actions.dart").read_text(encoding="utf-8")

    assert "data-action-id" in app
    assert "data-blocked-reason" in app
    assert "web_local_cli_unsupported" in app
    assert "if (action.desktop_enabled)" not in app
    assert "web_local_cli_unsupported" in panel
    assert "blocked_reason:" in panel
    assert "realLocalWorkflow" in request_builder
    assert "commandKind == 'core_cli'" in request_builder
    assert "deterministicSmoke" in request_builder


def test_flutter_bridge_allowlist_covers_real_local_and_deterministic_smoke_actions():
    fixture = load_fixture()
    bridge = (WORKBENCH / "flutter_app" / "lib" / "core_bridge" / "local_core_bridge.dart").read_text(encoding="utf-8")
    ready_actions = [
        action
        for action in fixture["actions"]
        if action["status"] == "ready"
        and action["command_kind"] == "core_cli"
        and action["desktop_enabled"] is True
    ]
    smoke_actions = [
        action
        for action in fixture["actions"]
        if action["status"] == "dry_run"
        and action["command_kind"] == "ui_safe_wrapper"
        and action["desktop_blocked_reason"] == "mock_only"
    ]

    assert len(ready_actions) == 57
    assert len(smoke_actions) == 36
    for action in ready_actions + smoke_actions:
        command_name = action["command"].split()[0]
        assert f"'{action['action_id']}': <String>['{command_name}']" in bridge


def test_core_ui_acceptance_report_matches_fixture_classification():
    fixture = load_fixture()
    report = json.loads(REPORT.read_text(encoding="utf-8"))
    real_local = [
        action
        for action in fixture["actions"]
        if action["status"] == "ready"
        and action["command_kind"] == "core_cli"
        and action["desktop_enabled"] is True
    ]
    smoke = [
        action
        for action in fixture["actions"]
        if action["status"] == "dry_run"
        and action["command_kind"] == "ui_safe_wrapper"
        and action["desktop_blocked_reason"] == "mock_only"
    ]
    blocked = len(fixture["actions"]) - len(real_local) - len(smoke)

    assert report["core_commit"] == CORE_COMMIT
    assert report["ui_fixture_commit"] == CORE_COMMIT
    assert report["gate_status"] == "blocked"
    assert report["drift_check"]["status"] == "pass"
    assert report["drift_check"]["drift_count"] == 0
    assert report["known_command_surface_blockers"] == [
        {
            "action_id": "package_build",
            "contract_command": "build --config <config> --output <output>",
            "blocker": "The ready/core_cli contract references build, but the current Core CLI does not expose a registered build command surface.",
            "status": "known_blocker_not_fixed_in_this_checkpoint",
        }
    ]
    assert report["action_classification"]["total_actions"] == len(fixture["actions"])
    assert report["action_classification"]["real_local_workflow_actions"] == len(real_local)
    assert report["action_classification"]["deterministic_smoke_actions"] == len(smoke)
    assert report["action_classification"]["disabled_blocked_actions"] == blocked
    assert report["runtime_boundaries"]["web_static_runtime"] == "disabled_with_blocked_reason"
