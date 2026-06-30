import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_agent_rag_ask_with_citation_required_writes_answer_report(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    output = tmp_path / "answer"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Agent RAG ask fixture with cited context.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package)]).exit_code == 0

    result = runner.invoke(
        app,
        ["ask", "--package", str(package), "--query", "What context is available?", "--citation-required", "--output", str(output)],
    )

    assert result.exit_code == 0, result.output
    answer = (output / "answer.md").read_text(encoding="utf-8")
    report = json.loads((output / "answer_report.json").read_text(encoding="utf-8"))
    assert "## Citations" in answer
    assert report["citation_required"] is True
    assert report["citation_count"] >= 1


def test_agent_rag_ask_with_citation_required_refuses_missing_context(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    output = tmp_path / "answer"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("The controlled fact is HT-L1-FACT-002 Obsidian Bench.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package)]).exit_code == 0

    result = runner.invoke(
        app,
        ["ask", "--package", str(package), "--query", "Which source says the moon is made of basalt cheese?", "--citation-required", "--output", str(output)],
    )

    assert result.exit_code == 0, result.output
    answer = (output / "answer.md").read_text(encoding="utf-8")
    report = json.loads((output / "answer_report.json").read_text(encoding="utf-8"))
    assert "Insufficient cited context" in answer
    assert report["citation_required"] is True
    assert report["insufficient_context"] is True
    assert report["citation_count"] == 0
