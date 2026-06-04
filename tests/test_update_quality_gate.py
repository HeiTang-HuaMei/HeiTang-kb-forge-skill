import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_lifecycle_update_quality_gate_report_is_generated(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Lifecycle quality gate fixture.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output), "--lifecycle"])

    assert result.exit_code == 0, result.output
    report = json.loads((output / "update_quality_gate_report.json").read_text(encoding="utf-8"))
    assert report["status"] in {"pass", "warning", "fail"}
    assert "current_quality_score" in report
    assert (output / "quality_regression_report.md").exists()
