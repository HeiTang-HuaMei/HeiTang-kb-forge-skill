from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_import_skill_generates_inventory(tmp_path):
    master = tmp_path / "master"
    output = tmp_path / "imported"
    master.mkdir()
    (master / "SKILL.md").write_text("# Demo Skill\n\nUse when writing with evidence.", encoding="utf-8")

    result = CliRunner().invoke(app, ["import-skill", "--input", str(master), "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert (output / "master_skill_inventory.json").exists()
    assert (output / "master_skill_parse_report.md").exists()
