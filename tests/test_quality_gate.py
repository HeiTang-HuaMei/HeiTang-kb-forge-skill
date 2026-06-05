import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_quality_gate_generates_result(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "quality_gate"
    workspace.mkdir()
    (workspace / "manifest.json").write_text("{}", encoding="utf-8")
    (workspace / "chunks.jsonl").write_text('{"text":"demo"}\n', encoding="utf-8")
    (workspace / "quality_report.json").write_text('{"quality_score":90}', encoding="utf-8")

    result = CliRunner().invoke(app, ["quality-gate", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "quality_gate_result.json").read_text(encoding="utf-8"))
    assert "release_ready" in payload
    assert (output / "quality_gate_scorecard.json").exists()
    assert (output / "quality_gate_findings.jsonl").exists()

