from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.skill import generate_skill_package
from tests.p0_helpers import make_p0_package


def test_diff_skill_package_cli_reports_changed_structured_files(tmp_path):
    package = make_p0_package(tmp_path)
    old_skill = tmp_path / "old_skill"
    new_skill = tmp_path / "new_skill"
    generate_skill_package(package, old_skill, "Structured Demo Skill")
    generate_skill_package(package, new_skill, "Structured Demo Skill")
    (new_skill / "cheatsheet.md").write_text("# Cheatsheet\n\n- edited\n", encoding="utf-8")
    output = tmp_path / "diff"

    result = CliRunner().invoke(
        app,
        [
            "diff-skill-package",
            "--old-skill",
            str(old_skill),
            "--new-skill",
            str(new_skill),
            "--output",
            str(output),
        ],
    )

    assert result.exit_code == 0, result.output
    assert (output / "skill_diff_report.json").exists()
    assert "Changed:" in result.output
