from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v18_run_config_generates_skill_validation_and_agent_package(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "v18.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("HeiTang v18 skill agent package evidence", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
skill:
  enabled: true
  name: Demo Knowledge Skill
  type: generic
  validate: true
  llm_generation: true
agent_package:
  enabled: true
  name: Demo Knowledge Agent
  type: generic
  llm_generation: true
llm:
  enabled: true
  provider: mock
  model: mock-model
  call_log: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert (output_dir / "skill_package" / "SKILL.md").exists()
    assert (output_dir / "skill_validation" / "skill_validation_result.json").exists()
    assert (output_dir / "agent_package" / "soul.md").exists()
    assert (output_dir / "agent_package" / "llm_agent_generation_report.md").exists()
