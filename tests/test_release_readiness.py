import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_release_readiness_summarizes_v25_outputs(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "release"
    workspace.mkdir()
    for name in [
        "quality_gate_result.json",
        "release_blockers.json",
        "regression_result.json",
        "golden_sample_validation.json",
        "platform_export_certification.json",
        "compatibility_matrix.json",
    ]:
        (output / name).parent.mkdir(parents=True, exist_ok=True)
        (output / name).write_text('{"status":"pass"}', encoding="utf-8")

    result = CliRunner().invoke(app, ["release-readiness", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "release_readiness_result.json").read_text(encoding="utf-8"))
    assert payload["release_ready"] is True
    assert (output / "release_readiness_checklist.md").exists()

