import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_agent_rag_retrieves_from_store_index(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    db_path = tmp_path / "kb_forge_workspace.db"
    output = tmp_path / "retrieval"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Agent RAG store integration fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package)]).exit_code == 0
    assert runner.invoke(app, ["store", "import-package", "--db", str(db_path), "--package", str(package)]).exit_code == 0

    result = runner.invoke(app, ["retrieve", "--store", str(db_path), "--query", "integration", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "retrieval_result.json").read_text(encoding="utf-8"))
    assert payload["records"]
    assert "store integration" in payload["records"][0]["text"]
