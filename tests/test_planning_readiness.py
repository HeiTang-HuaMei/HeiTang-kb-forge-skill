import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_planning_readiness_writes_pack(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    planning = tmp_path / "planning"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Planning readiness fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package), "--agent-template"]).exit_code == 0

    result = runner.invoke(app, ["planning-readiness", "--package", str(package), "--output", str(planning)])

    assert result.exit_code == 0, result.output
    assert (planning / "agent_planning_blueprint.yaml").exists()
    tool_map = json.loads((planning / "tool_requirement_map.json").read_text(encoding="utf-8"))
    assert tool_map["tasks"][0]["runtime_required"] is True
    assert (planning / "planning_eval_cases.jsonl").exists()
    assert (planning / "planning_risk_report.md").exists()
