import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_generate_agent_agent_compat_outputs_check(tmp_path):
    package = tmp_path / "package"
    skill = tmp_path / "skill"
    output = tmp_path / "agent"
    package.mkdir()
    skill.mkdir()
    (skill / "skill_manifest.yaml").write_text("skill_name: Demo Skill\n", encoding="utf-8")

    result = CliRunner().invoke(app, ["generate-agent", "--package", str(package), "--skill", str(skill), "--output", str(output), "--agent-compat"])

    assert result.exit_code == 0, result.output
    assert (output / "compat" / "generic_agent_profile.yaml").exists()
    assert json.loads((output / "agent_compat_check_result.json").read_text(encoding="utf-8"))["status"] == "passed"

