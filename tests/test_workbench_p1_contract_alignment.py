import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKBENCH = ROOT / "web" / "workbench"
FIXTURE = ROOT / "examples" / "ui_mock_data" / "p1_core_contract_fixture.json"
REPORT = ROOT / "docs" / "audits" / "core_ui_acceptance" / "core_ui_acceptance_report.json"
P1_RWF_V1 = ROOT / "examples" / "ui_mock_data" / "p1_real_workflow_v1_evidence.json"
P1_RWF_V2 = ROOT / "examples" / "ui_mock_data" / "p1_real_workflow_v2_evidence.json"
P1_RWF_V2_REPORT_DIR = ROOT / "examples" / "ui_mock_data" / "p1_real_workflow_v2"
P1_FINAL_GATE = ROOT / "examples" / "ui_mock_data" / "p1_final_gate_rerun"
CORE_COMMIT = "f5fa13bb11211abb0bcecaccd845e545a2dacad3"


DEDICATED_ROUTES = {
    "workspace",
    "vector-hub-provider-storage",
    "skill-factory",
    "artifact-management",
    "error-repair-center",
    "operation-gate",
    "capability-matrix",
}

FUTURE_RUNTIME_BOUNDARY_ACTIONS = {
    "run_agent",
    "multi_agent_orchestration",
    "summary_memory_lifecycle",
    "memory_compression",
    "memory_cleanup",
    "artifact_runtime_trace_inspect",
    "artifact_memory_files_inspect",
}


def load_fixture():
    return json.loads(FIXTURE.read_text(encoding="utf-8"))


def flutter_pages_block() -> str:
    flutter_main = (WORKBENCH / "flutter_app" / "lib" / "main.dart").read_text(encoding="utf-8")
    return flutter_main.split("const pages = <WorkbenchPage>[", 1)[1].split("class WorkbenchPage", 1)[0]


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


def test_flutter_p1_real_workflow_asset_matches_ui_fixture():
    flutter_asset = WORKBENCH / "flutter_app" / "assets" / "workflows" / "p1_real_workflow_v1_evidence.json"

    assert flutter_asset.exists()
    assert json.loads(flutter_asset.read_text(encoding="utf-8")) == json.loads(P1_RWF_V1.read_text(encoding="utf-8"))


def test_flutter_p1_real_workflow_v2_asset_matches_ui_fixture_and_reports():
    flutter_asset = WORKBENCH / "flutter_app" / "assets" / "workflows" / "p1_real_workflow_v2_evidence.json"
    flutter_report_dir = WORKBENCH / "flutter_app" / "assets" / "workflows" / "p1_real_workflow_v2"
    report_files = [
        "full_ready_action_execution_matrix.json",
        "action_execution_result_index.json",
        "action_artifact_assertion_report.json",
        "action_report_assertion_report.json",
        "action_error_boundary_report.json",
        "full_local_user_path_closure_report.json",
        "p1_real_workflow_v2_report.json",
        "remaining_blockers.json",
    ]

    assert flutter_asset.exists()
    assert json.loads(flutter_asset.read_text(encoding="utf-8")) == json.loads(P1_RWF_V2.read_text(encoding="utf-8"))
    for file_name in report_files:
        fixture = P1_RWF_V2_REPORT_DIR / file_name
        asset = flutter_report_dir / file_name
        assert asset.exists()
        assert json.loads(asset.read_text(encoding="utf-8")) == json.loads(fixture.read_text(encoding="utf-8"))


def test_flutter_p1_final_gate_assets_match_ui_fixture():
    flutter_report_dir = WORKBENCH / "flutter_app" / "assets" / "workflows" / "p1_final_gate_rerun"
    report_files = [
        "p1_final_gate_report.json",
        "p1_core_validation_summary.json",
        "p1_ui_validation_summary.json",
        "p1_rwf_v1_v2_evidence_index.json",
        "p1_action_execution_evidence_index.json",
        "p1_user_path_evidence_index.json",
        "p1_provider_blocked_boundary_report.json",
        "p1_security_release_hygiene_report.json",
        "p1_remaining_risks.json",
    ]

    for file_name in report_files:
        fixture = P1_FINAL_GATE / file_name
        asset = flutter_report_dir / file_name
        assert asset.exists()
        assert json.loads(asset.read_text(encoding="utf-8")) == json.loads(fixture.read_text(encoding="utf-8"))

    final_gate = json.loads((P1_FINAL_GATE / "p1_final_gate_report.json").read_text(encoding="utf-8"))
    assert final_gate["core_commit"] == CORE_COMMIT
    assert final_gate["core_ci_run_id"] == "27210849617"
    assert final_gate["p1_final_gate_status"] == "ready_for_v4_rc"
    assert final_gate["ready_for_v4_rc"] is True
    assert final_gate["v4_0_started"] is False
    assert final_gate["tag_created"] is False
    assert final_gate["v4_release_written"] is False


def test_dedicated_p1_routes_have_sidebar_and_renderers():
    contracts = json.loads((WORKBENCH / "contracts.json").read_text(encoding="utf-8"))
    app = (WORKBENCH / "src" / "app.js").read_text(encoding="utf-8")
    flutter_main = (WORKBENCH / "flutter_app" / "lib" / "main.dart").read_text(encoding="utf-8")
    route_ids = {page["id"] for page in contracts["pages"]}

    assert DEDICATED_ROUTES <= route_ids
    for route in DEDICATED_ROUTES:
        assert f'id: "{route}"' in app or f'"{route}"' in app
        assert f"'{route}'" in flutter_pages_block()

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
    assert "label: 'blocked_reason'" in panel
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
        if action["action_id"] in FUTURE_RUNTIME_BOUNDARY_ACTIONS:
            continue
        command_name = action["command"].split()[0]
        assert f"'{action['action_id']}': <String>['{command_name}']" in bridge
    for action_id in FUTURE_RUNTIME_BOUNDARY_ACTIONS:
        assert f"'{action_id}':" not in bridge


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
    assert report["gate_status"] == "ready_for_v4_rc"
    assert report["p1_final_gate_status"] == "ready_for_v4_rc"
    assert report["p1_real_workflow_v2_status"] == "passed"
    assert report["ui_full_operation_pending"] is False
    assert report["ready_for_v4_rc_candidate"] is True
    assert report["ready_for_v4_rc"] is True
    assert report["not_v4_0_workbench_rc"] is True
    assert report["v4_0_started"] is False
    assert report["tag_created"] is False
    assert report["v4_release_written"] is False
    assert report["drift_check"]["status"] == "pass"
    assert report["drift_check"]["drift_count"] == 0
    assert report["drift_check"]["command_surface_drift_count"] == 0
    assert report["drift_check"]["flutter_asset_matches_ui_fixture"] is True
    assert report["drift_check"]["p1_real_workflow_v1_asset_matches_fixture"] is True
    assert report["drift_check"]["p1_real_workflow_v2_asset_matches_fixture"] is True
    assert report["drift_check"]["p1_final_gate_asset_matches_fixture"] is True
    assert report["action_execution"] == {
        "ready_core_cli_action_count": 62,
        "execution_target_count": 57,
        "passed_action_count": 57,
        "failed_action_count": 0,
        "blocked_provider_secret_network_actions": 5,
        "full_57_ready_action_execution_complete": True,
    }
    assert report["user_path_closure"] == {
        "status": "pass",
        "user_path_count": 10,
        "passed_count": 10,
        "blocked_count": 0,
    }
    assert report["ui_consumption"]["status"] == "pass"
    assert report["ui_consumption"]["fixture_matches_flutter_asset"] is True
    assert report["ui_consumption"]["web_local_cli_disabled"] is True
    assert report["remaining_blockers"] == []
    assert report["action_classification"]["total_actions"] == len(fixture["actions"])
    assert report["action_classification"]["real_local_workflow_actions"] == len(real_local)
    assert report["action_classification"]["deterministic_smoke_actions"] == len(smoke)
    assert report["action_classification"]["disabled_blocked_actions"] == blocked
    assert report["runtime_boundaries"]["web_static_runtime"] == "disabled_with_blocked_reason"


def test_p1_real_workflow_v1_evidence_keeps_gate_boundary():
    evidence = json.loads(P1_RWF_V1.read_text(encoding="utf-8"))

    assert evidence["source"]["core_commit"] == CORE_COMMIT
    assert evidence["p1_real_workflow_v1_status"] == "passed"
    assert evidence["p1_full_operation_gate_status"] == "blocked"
    assert evidence["ready_for_v4_rc"] is False
    assert evidence["not_v4_0_workbench_rc"] is True
    assert evidence["drift_count"] == 0
    assert evidence["command_surface_drift_count"] == 0
    assert evidence["fixture_only_counted_as_real"] is False
    assert evidence["full_57_ready_action_execution_complete"] is False
    assert evidence["workflow_count"] == 8
    assert "full_57_ready_action_business_input_execution_not_complete" in {
        item["blocker_id"] for item in evidence["remaining_blockers"]
    }


def test_p1_real_workflow_v2_evidence_promotes_ui_gate_candidate_without_v4_release():
    evidence = json.loads(P1_RWF_V2.read_text(encoding="utf-8"))
    blocked_actions = {action["action_id"]: action for action in evidence["blocked_actions"]}

    assert evidence["source"]["core_commit"] == CORE_COMMIT
    assert evidence["p1_real_workflow_v2_status"] == "passed"
    assert evidence["p1_final_gate_status"] == "ready_for_v4_rc"
    assert evidence["p1_full_operation_gate_status"] == "ready_for_v4_rc"
    assert evidence["ui_full_operation_pending"] is False
    assert evidence["ready_for_v4_rc_candidate"] is True
    assert evidence["ready_for_v4_rc"] is True
    assert evidence["not_v4_0_workbench_rc"] is True
    assert evidence["v4_0_started"] is False
    assert evidence["tag_created"] is False
    assert evidence["v4_release_written"] is False
    assert evidence["drift_count"] == 0
    assert evidence["command_surface_drift_count"] == 0
    assert evidence["fixture_only_counted_as_real"] is False
    assert evidence["ready_core_cli_action_count"] == 62
    assert evidence["execution_target_count"] == 57
    assert evidence["passed_action_count"] == 57
    assert evidence["failed_action_count"] == 0
    assert evidence["blocked_action_count"] == 5
    assert evidence["full_57_ready_action_execution_complete"] is True
    assert evidence["artifact_assertion_status"] == "pass"
    assert evidence["report_assertion_status"] == "pass"
    assert evidence["error_boundary_status"] == "pass"
    assert evidence["user_path_closure_status"] == "pass"
    assert evidence["user_path_count"] == 10
    assert evidence["user_path_passed_count"] == 10
    assert evidence["remaining_blockers"] == []
    assert blocked_actions["provider_redaction_check"]["classification"] == "blocked_secret_required"
    assert blocked_actions["llm_provider_validate"]["classification"] == "blocked_provider_required"


def test_p1_real_workflow_v2_report_files_have_expected_gate_inputs():
    matrix = json.loads((P1_RWF_V2_REPORT_DIR / "full_ready_action_execution_matrix.json").read_text(encoding="utf-8"))
    results = json.loads((P1_RWF_V2_REPORT_DIR / "action_execution_result_index.json").read_text(encoding="utf-8"))
    artifacts = json.loads((P1_RWF_V2_REPORT_DIR / "action_artifact_assertion_report.json").read_text(encoding="utf-8"))
    reports = json.loads((P1_RWF_V2_REPORT_DIR / "action_report_assertion_report.json").read_text(encoding="utf-8"))
    errors = json.loads((P1_RWF_V2_REPORT_DIR / "action_error_boundary_report.json").read_text(encoding="utf-8"))
    paths = json.loads((P1_RWF_V2_REPORT_DIR / "full_local_user_path_closure_report.json").read_text(encoding="utf-8"))
    gate = json.loads((P1_RWF_V2_REPORT_DIR / "p1_real_workflow_v2_report.json").read_text(encoding="utf-8"))

    assert matrix["ready_core_cli_action_count"] == 62
    assert matrix["execution_target_count"] == 57
    assert len([action for action in matrix["actions"] if action["execution_target"]]) == 57
    assert len([action for action in matrix["actions"] if action["classification"] == "blocked_provider_required"]) == 4
    assert len([action for action in matrix["actions"] if action["classification"] == "blocked_secret_required"]) == 1
    assert results["passed_count"] == 57
    assert results["failed_count"] == 0
    assert artifacts["status"] == "pass"
    assert reports["status"] == "pass"
    assert errors["status"] == "pass"
    assert errors["external_provider_or_secret_actions_not_executed"] is True
    assert paths["status"] == "pass"
    assert paths["user_path_count"] == 10
    assert paths["passed_count"] == 10
    assert gate["p1_real_workflow_v2_status"] == "passed"
    assert gate["p1_full_operation_gate_status"] == "core_passed_pending_ui_consumption"
