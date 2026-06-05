import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_update_impact_generates_skill_and_agent_outputs(tmp_path):
    workspace = tmp_path / "workspace"
    package = tmp_path / "package"
    output = tmp_path / "impact"
    (workspace / "skill_a").mkdir(parents=True)
    (workspace / "skill_a" / "SKILL.md").write_text("# Skill A", encoding="utf-8")
    (workspace / "agent_a").mkdir()
    (workspace / "agent_a" / "agent_profile.yaml").write_text("name: Agent A\n", encoding="utf-8")
    package.mkdir()

    result = CliRunner().invoke(app, ["update-impact", "--workspace", str(workspace), "--package", str(package), "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert json.loads((output / "impacted_skills.json").read_text(encoding="utf-8"))["skills"][0]["skill_id"] == "skill_a"
    assert json.loads((output / "impacted_agents.json").read_text(encoding="utf-8"))["agents"][0]["agent_id"] == "agent_a"
    assert (output / "update_required_report.md").exists()
    assert (output / "dependency_impact_report.md").exists()

