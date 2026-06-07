import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_run_config_knowledge_bound_factory_writes_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "v31.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Trusted v3.1 factory config evidence.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
parser_backend:
  use_for_build: true
  default: builtin
  allow_untrusted: true
knowledge_bound_factory:
  enabled: true
  allow_untrusted: true
  skill_name: Config Bound Skill
  agent_name: Config Bound Agent
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert (output_dir / "skill_package" / "SKILL.md").exists()
    assert (output_dir / "agent_package" / "agent_profile.yaml").exists()
    manifest = _json(output_dir / "knowledge_bound_factory_manifest.json")
    assert manifest["skill_name"] == "Config Bound Skill"
    assert manifest["agent_name"] == "Config Bound Agent"


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
