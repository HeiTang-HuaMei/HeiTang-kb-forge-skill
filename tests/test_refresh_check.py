import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_refresh_check_writes_plan(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    workspace = tmp_path / "workspace"
    refresh_output = tmp_path / "refresh"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Refresh fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package), "--validate-package"]).exit_code == 0
    assert runner.invoke(app, ["workspace", "init", "--workspace", str(workspace)]).exit_code == 0
    assert runner.invoke(app, ["workspace", "register", "--workspace", str(workspace), "--package", str(package)]).exit_code == 0

    result = runner.invoke(app, ["refresh-check", "--workspace", str(workspace), "--output", str(refresh_output)])

    assert result.exit_code == 0, result.output
    plan = json.loads((refresh_output / "refresh_plan.json").read_text(encoding="utf-8"))
    assert plan["workspace"]
    assert (refresh_output / "source_freshness_report.md").exists()
    assert (refresh_output / "stale_sources.jsonl").exists()


def test_refresh_check_detects_changed_source_file(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    workspace = tmp_path / "workspace"
    refresh_output = tmp_path / "refresh"
    input_dir.mkdir()
    source = input_dir / "lesson.md"
    source.write_text("Original source.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package)]).exit_code == 0
    assert runner.invoke(app, ["workspace", "init", "--workspace", str(workspace)]).exit_code == 0
    assert runner.invoke(app, ["workspace", "register", "--workspace", str(workspace), "--package", str(package)]).exit_code == 0
    source.write_text("Changed source.", encoding="utf-8")

    result = runner.invoke(app, ["refresh-check", "--workspace", str(workspace), "--output", str(refresh_output)])

    assert result.exit_code == 0, result.output
    stale = (refresh_output / "stale_sources.jsonl").read_text(encoding="utf-8")
    assert "source_hash_changed" in stale
