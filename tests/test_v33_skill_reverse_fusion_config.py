import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_run_config_skill_reverse_fusion_uses_generated_skill_by_default(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "v33.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Skill reverse fusion config evidence.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
skill:
  enabled: true
  name: Config Source Skill
skill_reverse_fusion:
  enabled: true
  fused_name: Config Fused Skill
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert _json(output_dir / "skill_fusion_plan.json")["fused_name"] == "Config Fused Skill"
    assert (output_dir / "fused_skill" / "SKILL.md").exists()


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
