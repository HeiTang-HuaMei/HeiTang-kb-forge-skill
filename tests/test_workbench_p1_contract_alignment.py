import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKBENCH = ROOT / "web" / "workbench"
FIXTURE = ROOT / "examples" / "ui_mock_data" / "p1_core_contract_fixture.json"


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
    assert fixture["source"]["core_commit"] == "1e786cd1da1f557cd22eae622a721c431902e6b4"
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
    mapping = (WORKBENCH / "flutter_app" / "lib" / "core_actions" / "page_action_mapping.dart").read_text(encoding="utf-8")

    assert "data-action-id" in app
    assert "data-blocked-reason" in app
    assert "web_local_cli_unsupported" in panel
    assert "blocked_reason:" in panel
    for action_id in ["workspace_inspect", "rag_query", "book_to_skill", "run_agent", "artifact_kb_package_inspect"]:
        assert action_id in mapping
