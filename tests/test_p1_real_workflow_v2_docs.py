import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "docs" / "audits" / "p1_real_workflow_v2"


def test_committed_p1_real_workflow_v2_audit_records_core_passed_pending_ui_consumption():
    report = _json(AUDIT / "p1_real_workflow_v2_report.json")
    matrix = _json(AUDIT / "full_ready_action_execution_matrix.json")
    index = _json(AUDIT / "action_execution_result_index.json")
    blockers = _json(AUDIT / "remaining_blockers.json")

    assert report["p1_real_workflow_v2_status"] == "passed"
    assert report["p1_full_operation_gate_status"] == "core_passed_pending_ui_consumption"
    assert report["ui_full_operation_pending"] is True
    assert report["ready_for_v4_rc_candidate"] is False
    assert report["not_v4_0_workbench_rc"] is True
    assert report["v4_0_started"] is False
    assert report["tag_created"] is False
    assert report["v4_release_written"] is False
    assert report["full_57_ready_action_execution_complete"] is True
    assert report["fixture_only_counted_as_real"] is False
    assert report["command_surface_drift_count"] == 0

    assert matrix["ready_core_cli_action_count"] == 62
    assert matrix["execution_target_count"] == 57
    assert matrix["excluded_explicit_config_count"] == 5
    assert index["status"] == "pass"
    assert index["passed_count"] == 57
    assert index["failed_count"] == 0
    assert blockers["blockers"][0]["blocker_id"] == "ui_v2_consumption_pending"


def test_committed_p1_real_workflow_v2_audit_contains_action_and_user_path_outputs_without_binaries():
    matrix = _json(AUDIT / "full_ready_action_execution_matrix.json")
    closure = _json(AUDIT / "full_local_user_path_closure_report.json")

    for action in matrix["actions"]:
        action_dir = AUDIT / "actions" / action["action_id"]
        for filename in [
            "action_result.json",
            "action_report.md",
            "task_events.jsonl",
            "artifact_index.json",
            "report_index.json",
            "error_observation.json",
            "assertion_result.json",
        ]:
            assert (action_dir / filename).exists(), f"{action['action_id']}/{filename}"

    assert closure["status"] == "pass"
    assert closure["user_path_count"] == 10
    for user_path in closure["user_paths"]:
        path_dir = AUDIT / "user_paths" / user_path["user_path_id"]
        for filename in [
            "user_path_result.json",
            "user_path_report.md",
            "task_events.jsonl",
            "artifact_index.json",
            "report_index.json",
            "error_repair_map.json",
        ]:
            assert (path_dir / filename).exists(), f"{user_path['user_path_id']}/{filename}"

    assert not list(AUDIT.rglob("*.docx"))
    assert not list(AUDIT.rglob("*.pdf"))
    assert not list(AUDIT.rglob("*.pptx"))
    assert not list(AUDIT.rglob("*.zip"))
    assert not list(AUDIT.rglob("*.exe"))
    assert not list(AUDIT.rglob("*.dll"))


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))
