import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_llm_quality_gate_assist_is_mock_and_offline(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "llm_assist"
    workspace.mkdir()

    result = CliRunner().invoke(app, ["llm-quality-gate-assist", "--workspace", str(workspace), "--output", str(output), "--provider", "mock"])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "llm_quality_gate_assist_result.json").read_text(encoding="utf-8"))
    assert payload["mock_provider"] is True
    assert payload["network_called"] is False
    assert payload["suggestion_only"] is True
    assert (output / "llm_quality_gate_suggestions.jsonl").exists()

