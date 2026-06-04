import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_batch_progress_jsonl_tracks_batch_and_items(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("Batch progress fixture.", encoding="utf-8")
    (input_dir / "002_more.txt").write_text("Batch progress text fixture.", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "batch",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--progress-jsonl",
            "--profile",
            "fast",
        ],
    )

    assert result.exit_code == 0, result.output
    events = [json.loads(line) for line in (output_dir / "progress_events.jsonl").read_text(encoding="utf-8").splitlines()]
    stages = [event["stage"] for event in events]
    assert "batch_started" in stages
    assert "batch_item_started" in stages
    assert "batch_item_success" in stages
    assert stages[-1] == "batch_done"
    assert (output_dir / "001_lesson" / "progress_events.jsonl").exists()
