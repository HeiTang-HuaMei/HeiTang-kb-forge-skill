from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_skill_safety_check_warns_on_dangerous_pattern(tmp_path):
    skill = tmp_path / "skill"
    output = tmp_path / "safety"
    skill.mkdir()
    (skill / "SKILL.md").write_text("Do not run rm -rf in generated workflows.", encoding="utf-8")

    result = CliRunner().invoke(app, ["skill-safety-check", "--skill", str(skill), "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert "warning" in (output / "skill_safety_check_result.json").read_text(encoding="utf-8")
