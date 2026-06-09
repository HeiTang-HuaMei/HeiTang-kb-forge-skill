import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_release_readiness_blocks_on_version_mismatch(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "release"
    workspace.mkdir()
    (workspace / "pyproject.toml").write_text('version = "0.0.0"\n', encoding="utf-8")
    (workspace / "skill.json").write_text('{"version":"0.0.0"}', encoding="utf-8")

    result = CliRunner().invoke(app, ["release-readiness", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "release_readiness_result.json").read_text(encoding="utf-8"))
    assert payload["release_ready"] is False
    assert "version_mismatch" in payload["critical_blockers"]


def test_release_readiness_blocks_on_missing_capability_docs(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "release"
    workspace.mkdir()
    (workspace / "pyproject.toml").write_text('version = "4.0.0"\n', encoding="utf-8")
    (workspace / "skill.json").write_text('{"version":"4.0.0"}', encoding="utf-8")

    result = CliRunner().invoke(app, ["release-readiness", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "release_readiness_result.json").read_text(encoding="utf-8"))
    assert payload["release_ready"] is False
    assert "capability_status_missing" in payload["critical_blockers"]


def test_release_readiness_blocks_on_incomplete_quickstart_output(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "release"
    workspace.mkdir()
    docs = workspace / "docs"
    docs.mkdir()
    (workspace / "pyproject.toml").write_text('version = "4.0.0"\n', encoding="utf-8")
    (workspace / "skill.json").write_text('{"version":"4.0.0"}', encoding="utf-8")
    (workspace / "README.md").write_text("HeiTang KB Forge Skill\n", encoding="utf-8")
    (docs / "CAPABILITY_STATUS.md").write_text("Stable\n", encoding="utf-8")
    (docs / "VERSION_MATRIX.md").write_text("v4.0.0\n", encoding="utf-8")
    (docs / "RELEASE_CHECKLIST.md").write_text("Release checklist\n", encoding="utf-8")
    (workspace / "tmp_quickstart_output").mkdir()

    result = CliRunner().invoke(app, ["release-readiness", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "release_readiness_result.json").read_text(encoding="utf-8"))
    assert payload["release_ready"] is False
    assert "quickstart_output_missing" in payload["critical_blockers"]


def test_release_readiness_blocks_on_doctor_failure(tmp_path):
    workspace = _minimal_release_workspace(tmp_path)
    output = tmp_path / "release"
    doctor = workspace / "tmp_doctor"
    doctor.mkdir()
    (doctor / "doctor_result.json").write_text('{"status":"fail"}', encoding="utf-8")

    result = CliRunner().invoke(app, ["release-readiness", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "release_readiness_result.json").read_text(encoding="utf-8"))
    assert payload["release_ready"] is False
    assert "doctor_failed" in payload["critical_blockers"]


def test_release_readiness_blocks_on_missing_workflows(tmp_path):
    workspace = _minimal_release_workspace(tmp_path)
    output = tmp_path / "release"

    result = CliRunner().invoke(app, ["release-readiness", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "release_readiness_result.json").read_text(encoding="utf-8"))
    assert payload["release_ready"] is False
    assert "ci_workflow_missing" in payload["critical_blockers"]
    assert "release_check_workflow_missing" in payload["critical_blockers"]


def test_release_readiness_blocks_on_oversized_legacy_cli(tmp_path):
    workspace = _minimal_release_workspace(tmp_path)
    output = tmp_path / "release"
    workflows = workspace / ".github" / "workflows"
    workflows.mkdir(parents=True)
    (workflows / "ci.yml").write_text("name: CI\n", encoding="utf-8")
    (workflows / "release-check.yml").write_text("name: Release Check\n", encoding="utf-8")
    legacy = workspace / "heitang_kb_forge" / "cli_commands"
    legacy.mkdir(parents=True)
    (legacy / "legacy.py").write_text("x" * 10_000, encoding="utf-8")

    result = CliRunner().invoke(app, ["release-readiness", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "release_readiness_result.json").read_text(encoding="utf-8"))
    assert payload["release_ready"] is False
    assert "legacy_cli_oversized" in payload["critical_blockers"]


def _minimal_release_workspace(tmp_path):
    workspace = tmp_path / "workspace"
    workspace.mkdir()
    docs = workspace / "docs"
    docs.mkdir()
    (workspace / "pyproject.toml").write_text('version = "4.0.0"\n', encoding="utf-8")
    (workspace / "skill.json").write_text('{"version":"4.0.0"}', encoding="utf-8")
    (workspace / "README.md").write_text("HeiTang KB Forge Skill\n4.0.0\n", encoding="utf-8")
    (docs / "CAPABILITY_STATUS.md").write_text("4.0.0\nStable\n", encoding="utf-8")
    (docs / "VERSION_MATRIX.md").write_text("4.0.0\n", encoding="utf-8")
    (docs / "RELEASE_CHECKLIST.md").write_text("4.0.0\n", encoding="utf-8")
    return workspace

