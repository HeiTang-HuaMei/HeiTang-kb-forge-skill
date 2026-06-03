import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_eval_record_writes_dashboard_files(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    dashboard = tmp_path / "dashboard"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Evaluation dashboard fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package)]).exit_code == 0
    assert runner.invoke(app, ["ask", "--package", str(package), "--query", "What is this?", "--output", str(package)]).exit_code == 0

    result = runner.invoke(app, ["eval-record", "--package", str(package), "--output", str(dashboard)])

    assert result.exit_code == 0, result.output
    retrieval = json.loads((dashboard / "retrieval_eval_results.json").read_text(encoding="utf-8"))
    assert retrieval["retrieved_count"] >= 1
    assert (dashboard / "citation_hit_report.md").exists()
    assert (dashboard / "quality_trend_report.md").exists()
