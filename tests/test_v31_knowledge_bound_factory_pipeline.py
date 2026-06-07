import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_pipeline_reports_knowledge_bound_factory_only_when_enabled(tmp_path):
    default_output = _run_pipeline(tmp_path, False)
    enabled_output = _run_pipeline(tmp_path, True)

    default_stage = _stages(default_output)["knowledge_bound_factory"]
    enabled_stage = _stages(enabled_output)["knowledge_bound_factory"]
    assert default_stage["status"] == "skipped"
    assert enabled_stage["status"] == "success"
    assert "knowledge_bound_factory_manifest.json" in enabled_stage["output_files"]


def _run_pipeline(tmp_path, enabled):
    input_dir = tmp_path / ("input_enabled" if enabled else "input_default")
    output_dir = tmp_path / ("output_enabled" if enabled else "output_default")
    config_path = tmp_path / ("enabled.yaml" if enabled else "default.yaml")
    input_dir.mkdir()
    config = f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
parser_backend:
  use_for_build: true
  default: builtin
  allow_untrusted: true
knowledge_bound_factory:
  enabled: {str(enabled).lower()}
  allow_untrusted: true
"""
    (input_dir / "lesson.md").write_text("Trusted v3.1 pipeline evidence.", encoding="utf-8")
    config_path.write_text(config, encoding="utf-8")
    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])
    assert result.exit_code == 0, result.output
    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])
    assert result.exit_code == 0, result.output
    return output_dir


def _stages(output):
    manifest = json.loads((output / "pipeline_manifest.json").read_text(encoding="utf-8"))
    return {stage["name"]: stage for stage in manifest["stages"]}
