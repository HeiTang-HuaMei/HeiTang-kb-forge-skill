import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_workspace_init_register_and_status(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    workspace = tmp_path / "workspace"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Workspace registry fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package), "--validate-package"]).exit_code == 0

    assert runner.invoke(app, ["workspace", "init", "--workspace", str(workspace)]).exit_code == 0
    result = runner.invoke(app, ["workspace", "register", "--workspace", str(workspace), "--package", str(package)])
    status = runner.invoke(app, ["workspace", "status", "--workspace", str(workspace)])

    assert result.exit_code == 0, result.output
    assert status.exit_code == 0, status.output
    registry = json.loads((workspace / "package_registry.json").read_text(encoding="utf-8"))
    assert len(registry["packages"]) == 1
    assert registry["packages"][0]["package_hash"]
    assert (workspace / "package_status_report.md").exists()
