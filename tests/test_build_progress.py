import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_build_progress_jsonl_and_performance_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Progress fixture for large file observability.", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
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
    assert (output_dir / "progress_events.jsonl").exists()
    assert (output_dir / "pdf_preflight_report.json").exists()
    assert (output_dir / "pdf_page_classification.jsonl").exists()
    assert (output_dir / "ocr_cache_manifest.json").exists()
    assert (output_dir / "ocr_failed_pages.jsonl").exists()
    assert (output_dir / "ocr_resume_report.md").exists()
    assert (output_dir / "large_file_performance_report.md").exists()

    events = [json.loads(line) for line in (output_dir / "progress_events.jsonl").read_text(encoding="utf-8").splitlines()]
    stages = [event["stage"] for event in events]
    assert "scan_sources" in stages
    assert "parse_source" in stages
    assert "chunk_text" in stages
    assert stages[-1] == "done"

    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert "progress_events.jsonl" in manifest["files"]
    assert "large_file_performance_report.md" in manifest["files"]
