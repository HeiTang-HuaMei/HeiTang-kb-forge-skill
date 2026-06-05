from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_workspace_refresh_outputs_static_reports(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "refresh"
    workspace.mkdir()
    (workspace / "source.md").write_text("workspace source", encoding="utf-8")

    result = CliRunner().invoke(app, ["workspace-refresh", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert (output / "source_change_report.json").exists()
    assert (output / "refresh_plan.json").exists()
    assert (output / "refresh_impact_report.md").exists()

