import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_agent_tools_invoke_retrieve_knowledge(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    tool_input = tmp_path / "tool_input.json"
    output = tmp_path / "tool_run"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Agent tool retrieve knowledge fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package)]).exit_code == 0
    tool_input.write_text(json.dumps({"package": str(package), "query": "retrieve knowledge", "top_k": 3}), encoding="utf-8")

    result = runner.invoke(app, ["tools", "invoke", "--name", "retrieve_knowledge", "--input", str(tool_input), "--output", str(output)])

    assert result.exit_code == 0, result.output
    result_payload = json.loads((output / "tool_result.json").read_text(encoding="utf-8"))
    trace = json.loads((output / "tool_execution_trace.json").read_text(encoding="utf-8"))
    assert result_payload["status"] == "success"
    assert result_payload["records"]
    assert trace["tool"] == "retrieve_knowledge"
