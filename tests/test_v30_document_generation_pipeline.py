import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_pipeline_reports_document_generation_only_when_enabled(tmp_path):
    input_dir = tmp_path / "input"
    default_output = tmp_path / "default"
    enabled_output = tmp_path / "enabled"
    default_config = tmp_path / "default.yaml"
    enabled_config = tmp_path / "enabled.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pipeline document generation evidence.", encoding="utf-8")
    default_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {default_output.as_posix()}
""",
        encoding="utf-8",
    )
    enabled_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {enabled_output.as_posix()}
parser_backend:
  use_for_build: true
  default: builtin
  allow_untrusted: true
document_generation:
  enabled: true
  formats:
    - md
    - pdf
  template: default_report
  grounding_policy: creative_grounded
""",
        encoding="utf-8",
    )

    default_result = CliRunner().invoke(app, ["pipeline", "--config", str(default_config)])
    enabled_result = CliRunner().invoke(app, ["pipeline", "--config", str(enabled_config)])

    assert default_result.exit_code == 0, default_result.output
    assert enabled_result.exit_code == 0, enabled_result.output
    default_stage = _stages(default_output)["document_generation"]
    enabled_stage = _stages(enabled_output)["document_generation"]
    assert default_stage["enabled"] is False
    assert default_stage["status"] == "skipped"
    assert enabled_stage["enabled"] is True
    assert enabled_stage["status"] == "success"
    assert _json(enabled_output / "pipeline_manifest.json")["final_status"] == "pass"


def _stages(output):
    return {stage["name"]: stage for stage in _json(output / "pipeline_manifest.json")["stages"]}


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
