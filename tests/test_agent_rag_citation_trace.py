import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_agent_rag_citation_trace_maps_embedding_to_source(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    output = tmp_path / "retrieval"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Agent RAG citation trace fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package)]).exit_code == 0

    result = runner.invoke(app, ["retrieve", "--package", str(package), "--query", "citation", "--output", str(output)])

    assert result.exit_code == 0, result.output
    trace = json.loads((output / "citation_trace.json").read_text(encoding="utf-8"))
    assert trace["citations"][0]["embedding_id"]
    assert trace["citations"][0]["citation"]
