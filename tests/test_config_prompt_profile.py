import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_run_config_supports_llm_prompt_profile(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "profile.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Config prompt profile fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
llm:
  enabled: true
  cache: false
  prompt_profile: examples/prompt_profiles/product_manager.yaml
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    report = (output_dir / "ingest_report.md").read_text(encoding="utf-8")
    assert manifest["llm_prompt_profile"] == "product_manager"
    assert "- Prompt profile: product_manager" in report


def test_pipeline_config_supports_llm_prompt_profile(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "profile_pipeline.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pipeline prompt profile fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
llm:
  enabled: true
  cache: false
  prompt_profile: examples/prompt_profiles/product_manager.yaml
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    pipeline_manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    assert manifest["llm_prompt_profile"] == "product_manager"
    assert pipeline_manifest["final_status"] == "pass"


def test_config_prompt_profile_requires_llm(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "bad_profile.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Bad config prompt profile fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
llm:
  enabled: false
  prompt_profile: examples/prompt_profiles/product_manager.yaml
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code != 0
    assert "--prompt-profile requires --llm" in str(result.exception)
