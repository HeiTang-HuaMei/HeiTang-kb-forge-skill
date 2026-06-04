import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_agent_rag_retrieve_command_writes_result_and_trace(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    output = tmp_path / "retrieval"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Agent RAG retrieve fixture for shopping guide.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package)]).exit_code == 0

    result = runner.invoke(app, ["retrieve", "--package", str(package), "--query", "shopping guide", "--output", str(output)])

    assert result.exit_code == 0, result.output
    retrieval = json.loads((output / "retrieval_result.json").read_text(encoding="utf-8"))
    assert retrieval["records"]
    assert retrieval["records"][0]["citation"]
    assert (output / "retrieval_trace.json").exists()
