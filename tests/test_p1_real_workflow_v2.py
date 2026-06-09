import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.workbench import (
    P1_RWF_V2_READY_ACTION_TARGET_COUNT,
    P1_RWF_V2_USER_PATHS,
    action_result_status,
    run_full_local_user_path,
)


def test_p1_real_workflow_v2_runs_57_ready_actions_and_keeps_ui_gate_pending(tmp_path):
    report = run_full_local_user_path(tmp_path / "workspace", tmp_path / "run")
    run = tmp_path / "run"

    matrix = _json(run / "full_ready_action_execution_matrix.json")
    index = _json(run / "action_execution_result_index.json")
    blockers = _json(run / "remaining_blockers.json")

    assert report["p1_real_workflow_v2_status"] == "passed"
    assert report["p1_full_operation_gate_status"] == "core_passed_pending_ui_consumption"
    assert report["ui_full_operation_pending"] is True
    assert report["ready_for_v4_rc_candidate"] is False
    assert report["not_v4_0_workbench_rc"] is True
    assert report["v4_0_started"] is False
    assert report["tag_created"] is False
    assert report["v4_release_written"] is False
    assert report["fixture_only_counted_as_real"] is False
    assert report["full_57_ready_action_execution_complete"] is True
    assert report["command_surface_drift_count"] == 0

    assert matrix["ready_core_cli_action_count"] == 62
    assert matrix["execution_target_count"] == P1_RWF_V2_READY_ACTION_TARGET_COUNT
    assert matrix["excluded_explicit_config_count"] == 5
    assert all(item["classification"] for item in matrix["actions"])

    assert index["status"] == "pass"
    assert index["execution_target_count"] == P1_RWF_V2_READY_ACTION_TARGET_COUNT
    assert index["passed_count"] == P1_RWF_V2_READY_ACTION_TARGET_COUNT
    assert index["failed_count"] == 0
    assert index["blocked_count"] == 0

    target_ids = {item["action_id"] for item in matrix["actions"] if item["execution_target"]}
    excluded_ids = {item["action_id"] for item in matrix["actions"] if not item["execution_target"]}
    assert excluded_ids == {
        "llm_provider_validate",
        "vector_db_validate",
        "vector_upsert_query_smoke",
        "provider_redaction_check",
        "offline_fallback_status",
    }

    for action_id in target_ids:
        action = _json(run / "actions" / action_id / "action_result.json")
        assert action["status"] == "passed", action_id
        assert action["evidence_level"] == "real_local_workflow", action_id
        assert action["command_exit_code"] == 0, action_id
        assert action["assertion_status"] == "passed", action_id

    for action_id in excluded_ids:
        action = _json(run / "actions" / action_id / "action_result.json")
        assert action["status"] == "blocked", action_id
        assert action["blocked_reason"], action_id
        assert action["evidence_level"] != "real_local_workflow"

    assert blockers["status"] == "blocked"
    assert blockers["blockers"][0]["blocker_id"] == "ui_v2_consumption_pending"
    assert len(_json(run / "full_local_user_path_closure_report.json")["user_paths"]) == len(P1_RWF_V2_USER_PATHS)
    for path_spec in P1_RWF_V2_USER_PATHS:
        path_dir = run / "user_paths" / path_spec["user_path_id"]
        assert (path_dir / "user_path_result.json").exists()
        assert (path_dir / "task_events.jsonl").exists()
        assert _json(path_dir / "user_path_result.json")["status"] == "passed"


def test_p1_real_workflow_v2_cli_plan_single_action_and_status(tmp_path):
    runner = CliRunner()
    workspace = tmp_path / "workspace"
    plan_output = tmp_path / "plan"
    action_output = tmp_path / "action"

    plan = runner.invoke(app, ["workbench-action-execution-plan", "--workspace", str(workspace), "--output", str(plan_output)])
    assert plan.exit_code == 0, plan.output
    assert _json(plan_output / "action_input_plan.json")["execution_target_count"] == P1_RWF_V2_READY_ACTION_TARGET_COUNT

    result = runner.invoke(
        app,
        [
            "workbench-run-ready-action",
            "--action-id",
            "query_rewrite",
            "--workspace",
            str(workspace),
            "--output",
            str(action_output),
        ],
    )
    assert result.exit_code == 0, result.output
    status = action_result_status(action_output / "query_rewrite")
    assert status["action_id"] == "query_rewrite"
    assert status["status"] == "passed"
    assert status["assertion_status"] == "passed"

    cli_status = runner.invoke(app, ["workbench-action-result-status", "--run-dir", str(action_output / "query_rewrite")])
    assert cli_status.exit_code == 0, cli_status.output
    assert json.loads(cli_status.output)["action_id"] == "query_rewrite"


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
