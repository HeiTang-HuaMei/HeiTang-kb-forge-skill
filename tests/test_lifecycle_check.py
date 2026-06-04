import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_lifecycle_check_reports_changed_new_and_missing_sources(tmp_path):
    input_dir = tmp_path / "input"
    previous_output = tmp_path / "previous"
    check_output = tmp_path / "check"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Original lifecycle lesson.", encoding="utf-8")
    (input_dir / "remove.txt").write_text("This source will be removed.", encoding="utf-8")

    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(previous_output), "--lifecycle"]).exit_code == 0
    (input_dir / "lesson.md").write_text("Changed lifecycle lesson.", encoding="utf-8")
    (input_dir / "remove.txt").unlink()
    (input_dir / "new.md").write_text("New lifecycle source.", encoding="utf-8")

    result = runner.invoke(
        app,
        ["lifecycle-check", "--input", str(input_dir), "--package", str(previous_output), "--output", str(check_output)],
    )

    assert result.exit_code == 0, result.output
    assert (check_output / "source_registry.json").exists()
    assert (check_output / "source_change_report.md").exists()
    changed = [json.loads(line) for line in (check_output / "changed_sources.jsonl").read_text(encoding="utf-8").splitlines()]
    missing = [json.loads(line) for line in (check_output / "missing_sources.jsonl").read_text(encoding="utf-8").splitlines()]
    new = [json.loads(line) for line in (check_output / "new_sources.jsonl").read_text(encoding="utf-8").splitlines()]
    assert changed[0]["relative_path"] == "lesson.md"
    assert missing[0]["relative_path"] == "remove.txt"
    assert new[0]["relative_path"] == "new.md"
