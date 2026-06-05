import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_analyze_skill_generates_decomposition_profiles(tmp_path):
    master = tmp_path / "master"
    output = tmp_path / "analysis"
    master.mkdir()
    (master / "SKILL.md").write_text(
        "# Demo Skill\n\nUse when answering product questions.\n\nSteps:\n- retrieve evidence\n- answer with citation\n\nDo not answer outside evidence.\nStyle: concise.",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["analyze-skill", "--skill", str(master), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "skill_decomposition.json").read_text(encoding="utf-8"))
    assert payload["skill_name"] == "master"
    assert (output / "skill_capability_map.json").exists()
    assert (output / "skill_workflow_graph.json").exists()
    assert (output / "style_profile.yaml").exists()
    assert (output / "boundary_profile.yaml").exists()
