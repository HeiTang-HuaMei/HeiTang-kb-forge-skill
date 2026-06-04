import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_lifecycle_missing_source_policy_marks_stale_chunks(tmp_path):
    input_dir = tmp_path / "input"
    previous_output = tmp_path / "previous"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "keep.md").write_text("Lifecycle keep fixture.", encoding="utf-8")
    (input_dir / "remove.md").write_text("Lifecycle removed fixture.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(previous_output), "--lifecycle"]).exit_code == 0
    (input_dir / "remove.md").unlink()

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
            "--lifecycle",
            "--missing-source-policy",
            "mark_stale",
        ],
    )

    assert result.exit_code == 0, result.output
    missing = [json.loads(line) for line in (output / "missing_sources.jsonl").read_text(encoding="utf-8").splitlines()]
    stale = [json.loads(line) for line in (output / "stale_chunks.jsonl").read_text(encoding="utf-8").splitlines()]
    assert missing[0]["relative_path"] == "remove.md"
    assert stale
