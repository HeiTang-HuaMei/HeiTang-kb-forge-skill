from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from tests.structured_skill_helpers import read_json


def test_run_config_generates_structured_skill_and_pipeline_stage(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config = tmp_path / "config.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Local Skill framework should connect KB, RAG, Agent, and multi-KB workflows.", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
contract:
  version: v2
  check: true
skill:
  name: Structured Demo Skill
  type: structured_book_skill
skill_generation:
  enabled: true
  target: codex
  language: bilingual
  on_demand_loading: true
  token_budget: 4000
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])
    pipeline_result = CliRunner().invoke(app, ["pipeline", "--config", str(config)])

    assert result.exit_code == 0, result.output
    assert pipeline_result.exit_code == 0, pipeline_result.output
    assert (output_dir / "structured_skill_package" / "SKILL.md").exists()
    assert (output_dir / "structured_skill_validation" / "structured_skill_validation_result.json").exists()
    pipeline = read_json(output_dir / "pipeline_manifest.json")
    stages = {stage["name"]: stage for stage in pipeline["stages"]}
    assert stages["structured_book_to_skill_generation"]["enabled"] is True
    assert stages["structured_book_to_skill_generation"]["status"] == "success"
    assert stages["structured_skill_validation"]["status"] == "success"
