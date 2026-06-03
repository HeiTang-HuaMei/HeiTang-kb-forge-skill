import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_incremental_build_writes_manifest_and_report(tmp_path):
    input_dir = tmp_path / "input"
    previous = tmp_path / "previous"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Incremental fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(previous)]).exit_code == 0

    result = runner.invoke(
        app,
        ["build", "--input", str(input_dir), "--output", str(output), "--incremental", "--previous-package", str(previous)],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output / "incremental_manifest.json").read_text(encoding="utf-8"))
    assert manifest["current_package_hash"]
    assert (output / "incremental_report.md").exists()
    assert (output / "package_version.json").exists()
