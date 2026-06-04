import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_lifecycle_incremental_build_writes_update_outputs(tmp_path):
    input_dir = tmp_path / "input"
    previous_output = tmp_path / "previous"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Original incremental lifecycle fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(previous_output), "--lifecycle"]).exit_code == 0

    (input_dir / "lesson.md").write_text("Changed incremental lifecycle fixture.", encoding="utf-8")
    result = runner.invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output),
            "--previous-package",
            str(previous_output),
            "--update-mode",
            "incremental",
        ],
    )

    assert result.exit_code == 0, result.output
    assert (output / "incremental_update_report.md").exists()
    assert (output / "rebuilt_chunks.jsonl").exists()
    assert (output / "reused_chunks.jsonl").exists()
    manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["lifecycle_enabled"] is True
    assert "source_registry.json" in manifest["files"]
