import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_pipeline_config_supports_performance_block(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "pipeline.performance.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pipeline performance fixture.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
performance:
  profile: fast
  progress_jsonl: true
  ocr_mode: first-pages
  max_ocr_pages: 10
  ocr_cache: true
  resume: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert (output_dir / "progress_events.jsonl").exists()
    assert (output_dir / "large_file_performance_report.md").exists()
    manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"]: stage for stage in manifest["stages"]}
    assert stages["pdf_preflight"]["status"] == "success"
    assert stages["ocr_cache"]["status"] == "success"
    assert stages["ocr_processing"]["status"] == "success"
    assert stages["performance_report"]["status"] == "success"
    assert stages["progress_events"]["status"] == "success"


def test_pipeline_cli_performance_flags_override_config(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "pipeline.flags.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pipeline flag fixture.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(
        app,
        [
            "pipeline",
            "--config",
            str(config_path),
            "--progress-jsonl",
            "--profile",
            "fast",
            "--ocr-cache",
        ],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"]: stage for stage in manifest["stages"]}
    assert stages["progress_events"]["enabled"] is True
    assert stages["performance_report"]["enabled"] is True
    assert stages["ocr_cache"]["enabled"] is True
