from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from tests.structured_skill_helpers import make_structured_skill


def test_validate_skill_package_cli_checks_structured_package(tmp_path):
    _, skill = make_structured_skill(tmp_path)
    output = tmp_path / "validation"

    result = CliRunner().invoke(app, ["validate-skill-package", "--skill", str(skill), "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert (output / "structured_skill_validation_result.json").exists()
    assert "Status: pass" in result.output
