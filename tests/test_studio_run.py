from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_studio_run_command_generates_stable_workspace(tmp_path):
    input_dir = tmp_path / "input"
    workspace = tmp_path / "workspace"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("studio run fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "studio-run",
            "--input",
            str(input_dir),
            "--workspace",
            str(workspace),
            "--project-name",
            "demo_project",
        ],
    )

    assert result.exit_code == 0, result.output
    assert (workspace / "studio_run_manifest.json").exists()
    assert (workspace / "stable_check_result.json").exists()
    assert (workspace / "reliability_score.json").exists()
