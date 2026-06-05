import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_compatibility_matrix_marks_platform_boundaries(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "compatibility"
    (workspace / "platform_distribution").mkdir(parents=True)

    result = CliRunner().invoke(app, ["compatibility-matrix", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "compatibility_matrix.json").read_text(encoding="utf-8"))
    rows = {row["object"]: row for row in payload["objects"]}
    assert rows["xhs"]["official_api"] is False
    assert rows["mcp"]["stub_only"] is True
    assert rows["codex"]["runtime_not_executed"] is True
    assert (output / "compatibility_matrix.md").exists()

