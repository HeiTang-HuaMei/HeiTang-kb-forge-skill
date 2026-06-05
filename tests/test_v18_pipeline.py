import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v18_pipeline_reports_skill_and_agent_stages(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "v18.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("HeiTang v18 pipeline fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
skill:
  enabled: true
  name: Demo Knowledge Skill
  validate: true
agent_package:
  enabled: true
  name: Demo Knowledge Agent
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"] for stage in manifest["stages"]}
    assert {"skill_package_generation", "skill_validation", "agent_package_generation"}.issubset(stages)
