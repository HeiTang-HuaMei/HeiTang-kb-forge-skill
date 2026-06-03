import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_run_config_supports_llm_quality_report(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "quality.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Config LLM quality fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
llm:
  enabled: true
  cache: false
  quality_report: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["llm_quality_report_enabled"] is True
    assert (output_dir / "llm_quality_report.json").exists()


def test_pipeline_config_supports_llm_quality_report_without_new_stage(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "pipeline_quality.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pipeline LLM quality fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
llm:
  enabled: true
  cache: false
  quality_report: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    pipeline_manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"]: stage for stage in pipeline_manifest["stages"]}
    assert "llm_quality" not in stages
    assert "llm_quality_report.json" in stages["llm_extraction"]["output_files"]
    assert stages["llm_extraction"]["status"] == "success"


def test_config_llm_quality_report_requires_llm(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "bad_quality.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Bad LLM quality config fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
llm:
  enabled: false
  quality_report: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code != 0
    assert "--llm-quality-report requires --llm" in str(result.exception)
