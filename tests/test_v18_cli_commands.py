from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v18_cli_commands_generate_skill_validate_and_agent(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    skill = tmp_path / "skill"
    validation = tmp_path / "validation"
    agent = tmp_path / "agent"
    runner = CliRunner()
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("HeiTang v18 CLI fixture", encoding="utf-8")

    build = runner.invoke(app, ["build", "--input", str(input_dir), "--output", str(package), "--contract-version", "v2", "--check-contract", "--governance", "--retrieval-index"])
    assert build.exit_code == 0, build.output

    gen_skill = runner.invoke(app, ["generate-skill", "--package", str(package), "--output", str(skill), "--skill-name", "Demo Knowledge Skill"])
    assert gen_skill.exit_code == 0, gen_skill.output
    assert (skill / "SKILL.md").exists()

    validate = runner.invoke(app, ["validate-skill", "--skill", str(skill), "--package", str(package), "--output", str(validation)])
    assert validate.exit_code == 0, validate.output
    assert (validation / "skill_validation_result.json").exists()

    gen_agent = runner.invoke(app, ["generate-agent", "--package", str(package), "--skill", str(skill), "--output", str(agent), "--agent-name", "Demo Knowledge Agent"])
    assert gen_agent.exit_code == 0, gen_agent.output
    assert (agent / "soul.md").exists()
    assert (agent / "system_prompt.md").exists()
