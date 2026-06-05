from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_release_engineering_commands_are_present():
    result = CliRunner().invoke(app, ["--help"])
    assert result.exit_code == 0
    for command in [
        "quality-gate",
        "release-blockers",
        "regression-check",
        "validate-golden-samples",
        "certify-export",
        "compatibility-matrix",
        "llm-quality-gate-assist",
        "release-readiness",
        "export-platform",
        "doctor",
    ]:
        assert command in result.output

