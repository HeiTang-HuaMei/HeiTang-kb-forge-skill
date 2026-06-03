import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_diff_command_writes_chunk_diff_outputs(tmp_path):
    old_input = tmp_path / "old_input"
    new_input = tmp_path / "new_input"
    old_output = tmp_path / "old_output"
    new_output = tmp_path / "new_output"
    diff_output = tmp_path / "diff"
    old_input.mkdir()
    new_input.mkdir()
    (old_input / "lesson.md").write_text("Old package fixture.", encoding="utf-8")
    (new_input / "lesson.md").write_text("New package fixture with changed content.", encoding="utf-8")
    runner = CliRunner()
    assert runner.invoke(app, ["build", "--input", str(old_input), "--output", str(old_output)]).exit_code == 0
    assert runner.invoke(app, ["build", "--input", str(new_input), "--output", str(new_output)]).exit_code == 0

    result = runner.invoke(app, ["diff", "--old", str(old_output), "--new", str(new_output), "--output", str(diff_output)])

    assert result.exit_code == 0, result.output
    for name in ["package_version.json", "package_diff_report.md", "changed_chunks.jsonl", "removed_chunks.jsonl", "new_chunks.jsonl"]:
        assert (diff_output / name).exists()
    version = json.loads((diff_output / "package_version.json").read_text(encoding="utf-8"))
    assert version["package_hash"]
