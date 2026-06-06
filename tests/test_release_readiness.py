import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def _write_release_workspace_contract(workspace):
    docs = workspace / "docs"
    docs.mkdir()
    workflows = workspace / ".github" / "workflows"
    workflows.mkdir(parents=True)
    (workspace / "pyproject.toml").write_text('version = "2.9.0-alpha.1"\n', encoding="utf-8")
    (workspace / "skill.json").write_text('{"version":"2.9.0-alpha.1"}', encoding="utf-8")
    (workspace / "README.md").write_text("HeiTang KB Forge Skill\n2.9.0-alpha.1\n", encoding="utf-8")
    (docs / "CAPABILITY_STATUS.md").write_text("2.9.0-alpha.1\nStable\nPreview\nExperimental\n", encoding="utf-8")
    (docs / "VERSION_MATRIX.md").write_text("v2.9.0-alpha.1\n2.9.0-alpha.1\n", encoding="utf-8")
    (docs / "RELEASE_CHECKLIST.md").write_text("2.9.0-alpha.1\nRelease checklist\n", encoding="utf-8")
    (workflows / "ci.yml").write_text("name: CI\n", encoding="utf-8")
    (workflows / "release-check.yml").write_text("name: Release Check\n", encoding="utf-8")


def test_release_readiness_summarizes_v25_outputs(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "release"
    workspace.mkdir()
    _write_release_workspace_contract(workspace)
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

