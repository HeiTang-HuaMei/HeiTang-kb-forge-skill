import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_reverse_fuse_skills_command_writes_outputs(tmp_path):
    first = _skill(tmp_path, "first")
    second = _skill(tmp_path, "second")
    output = tmp_path / "fusion"

    result = CliRunner().invoke(
        app,
        [
            "reverse-fuse-skills",
            "--skills",
            f"{first},{second}",
            "--output",
            str(output),
            "--fused-name",
            "CLI Fused Skill",
        ],
    )

    assert result.exit_code == 0, result.output
    assert _json(output / "skill_fusion_plan.json")["fused_name"] == "CLI Fused Skill"
    assert (output / "fused_skill" / "skill_manifest.yaml").exists()


def _skill(tmp_path, name):
    skill = tmp_path / name
    skill.mkdir()
    (skill / "SKILL.md").write_text(f"# {name}\n\nUse this skill to answer with evidence.\n", encoding="utf-8")
    return skill


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
