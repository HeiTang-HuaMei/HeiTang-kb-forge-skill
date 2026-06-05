from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_skill_similarity_check_generates_report(tmp_path):
    master = tmp_path / "master"
    derived = tmp_path / "derived"
    output = tmp_path / "similarity"
    master.mkdir()
    derived.mkdir()
    (master / "SKILL.md").write_text("retrieve evidence answer with citation", encoding="utf-8")
    (derived / "SKILL.md").write_text("retrieve evidence answer in own package scope", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["skill-similarity-check", "--master-skill", str(master), "--derived-skill", str(derived), "--output", str(output)],
    )

    assert result.exit_code == 0, result.output
    assert (output / "skill_similarity_report.md").exists()
