from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_build_accepts_ocr_performance_options_without_real_ocr(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("OCR option smoke fixture.", encoding="utf-8")

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
            "--ocr-mode",
            "first-pages",
            "--max-ocr-pages",
            "2",
            "--ocr-workers",
            "2",
            "--ocr-cache",
            "--resume",
        ],
    )

    assert result.exit_code == 0, result.output
    assert (output_dir / "progress_events.jsonl").exists()
    assert (output_dir / "ocr_cache_manifest.json").exists()
    assert (output_dir / "large_file_performance_report.md").exists()
