import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_regression_check_covers_v16_to_v26(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "regression"
    workspace.mkdir()

    result = CliRunner().invoke(app, ["regression-check", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "regression_result.json").read_text(encoding="utf-8"))
    assert payload["status"] == "pass"
    assert payload["covered_versions"][0] == "v1.6"
    assert payload["covered_versions"][-1] == "v2.6.0-alpha.1"
    assert (output / "regression_cases.jsonl").exists()
