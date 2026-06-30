import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_ask_command_outputs_answer_with_citation(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    answer_output = tmp_path / "answer"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("The package is suitable for a product manager agent.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package)]).exit_code == 0

    result = runner.invoke(app, ["ask", "--package", str(package), "--query", "What agent is this suitable for?", "--output", str(answer_output)])

    assert result.exit_code == 0, result.output
    answer = (answer_output / "answer.md").read_text(encoding="utf-8")
    trace = json.loads((answer_output / "retrieval_trace.json").read_text(encoding="utf-8"))
    assert "## Citations" in answer
    assert trace["records"][0]["citation"]


def test_ask_command_handles_unconfigured_model_service_without_traceback(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    answer_output = tmp_path / "answer"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("The package is suitable for a product manager agent.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package)]).exit_code == 0

    result = runner.invoke(
        app,
        ["ask", "--package", str(package), "--query", "What agent is this suitable for?", "--provider", "openai-compatible", "--output", str(answer_output)],
    )

    assert result.exit_code == 0, result.output
    answer = (answer_output / "answer.md").read_text(encoding="utf-8")
    report = json.loads((answer_output / "answer_report.json").read_text(encoding="utf-8"))
    assert "Model service is not configured" in answer
    assert report["insufficient_context"] is True
    assert "Traceback" not in result.output
