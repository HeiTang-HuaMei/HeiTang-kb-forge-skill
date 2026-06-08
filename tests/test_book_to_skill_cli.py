from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from tests.p0_helpers import make_p0_package


def test_book_to_skill_cli_generates_structured_package_from_existing_kb(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "book_skill"

    result = CliRunner().invoke(
        app,
        [
            "book-to-skill",
            "--package",
            str(package),
            "--output",
            str(output),
            "--skill-name",
            "Structured Demo Skill",
            "--target",
            "codex",
        ],
    )

    assert result.exit_code == 0, result.output
    assert (output / "SKILL.md").exists()
    assert (output / "on_demand_load_manifest.json").exists()
    assert (output / "skill_agent_kb_compatibility_report.json").exists()
    assert "Validation: pass" in result.output


def test_book_to_skill_cli_requires_input_or_package(tmp_path):
    result = CliRunner().invoke(app, ["book-to-skill", "--output", str(tmp_path / "out")])

    assert result.exit_code != 0
    assert "--input or --package is required" in result.output
