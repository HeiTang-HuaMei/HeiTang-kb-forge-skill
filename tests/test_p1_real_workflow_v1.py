import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.workbench.golden_workflows import P1_RWF_V1_WORKFLOWS, run_p1_golden_workflows
from heitang_kb_forge.workbench.golden_workflows import _reset_generated_directory


def test_p1_golden_workflows_write_v1_evidence_without_unlocking_full_gate(tmp_path):
    report = run_p1_golden_workflows(tmp_path / "workspace", tmp_path / "run")

    assert report["p1_real_workflow_v1_status"] == "passed"
    assert report["p1_full_operation_gate_status"] == "blocked"
    assert report["ready_for_v4_rc"] is False
    assert report["command_surface_drift_count"] == 0
    assert report["workflow_ids"] == P1_RWF_V1_WORKFLOWS
    assert any(item["evidence_level"] == "real_local_workflow" for item in report["workflow_results"])
    assert any(item["evidence_level"] == "deterministic_smoke" for item in report["workflow_results"])
    assert _json(tmp_path / "run" / "remaining_blockers.json")["blockers"][0]["blocker_id"] == "full_57_ready_action_business_input_execution_not_complete"

    for workflow_id in P1_RWF_V1_WORKFLOWS:
        run_dir = tmp_path / "run" / workflow_id
        for filename in [
            "workflow_result.json",
            "workflow_report.md",
            "task_events.jsonl",
            "artifact_index.json",
            "error_repair_map.json",
            "report_index.json",
            "user_path_summary.md",
        ]:
            assert (run_dir / filename).exists(), f"{workflow_id}/{filename}"
    for filename in ["generated.md", "generated.docx", "generated.pdf", "generated.pptx"]:
        assert (tmp_path / "run" / "document_generation_smoke" / "artifacts" / "generated_documents" / filename).exists()


def test_reset_generated_directory_recreates_existing_document_output(tmp_path):
    output = tmp_path / "generated_documents"
    output.mkdir()
    (output / "generated.docx").write_bytes(b"docx")

    _reset_generated_directory(output)

    assert output.exists()
    assert list(output.iterdir()) == []


def test_p1_golden_workflow_cli_and_status_commands(tmp_path):
    runner = CliRunner()
    workspace = tmp_path / "workspace"
    output = tmp_path / "run"

    result = runner.invoke(app, ["workbench-golden-workflow", "--all", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert "P1 golden workflow: passed" in result.output
    assert _json(output / "p1_real_workflow_v1_report.json")["p1_full_operation_gate_status"] == "blocked"

    status = runner.invoke(app, ["workbench-golden-workflow-status", "--run-dir", str(output / "workspace_lifecycle")])
    assert status.exit_code == 0, status.output
    assert json.loads(status.output)["workflow_id"] == "workspace_lifecycle"

    replay = runner.invoke(app, ["workbench-task-replay", "--task-id", "task_workspace_lifecycle", "--run-dir", str(output / "workspace_lifecycle")])
    assert replay.exit_code == 0, replay.output
    assert json.loads(replay.output)["events"]


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
