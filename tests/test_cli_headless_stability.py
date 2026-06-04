import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_headless_cli_build_batch_run_pipeline_and_ask_smoke(tmp_path):
    runner = CliRunner()
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("Headless skill-first fixture with citation-ready content.", encoding="utf-8")
    build_output = tmp_path / "build"
    batch_output = tmp_path / "batch"
    run_output = tmp_path / "run"
    pipeline_output = tmp_path / "pipeline"
    ask_output = tmp_path / "ask"

    assert runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(build_output)]).exit_code == 0
    assert runner.invoke(app, ["batch", "--input", str(input_dir), "--output", str(batch_output)]).exit_code == 0

    config = tmp_path / "config.yaml"
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {run_output.as_posix()}
domain: general
mode: reference
""",
        encoding="utf-8",
    )
    assert runner.invoke(app, ["run", "--config", str(config)]).exit_code == 0

    pipeline_config = tmp_path / "pipeline.yaml"
    pipeline_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {pipeline_output.as_posix()}
domain: general
mode: reference
""",
        encoding="utf-8",
    )
    assert runner.invoke(app, ["pipeline", "--config", str(pipeline_config)]).exit_code == 0
    assert runner.invoke(app, ["ask", "--package", str(build_output), "--query", "What is this?", "--output", str(ask_output)]).exit_code == 0

    manifest = json.loads((build_output / "manifest.json").read_text(encoding="utf-8"))
    for name in ["chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl", "glossary.jsonl", "manifest.json", "ingest_report.md", "quality_report.json"]:
        assert name in manifest["files"]
