from typer.testing import CliRunner

from heitang_kb_forge.cli import V21Options, _build_package, app


def test_cli_entrypoint_still_reexports_runtime_symbols():
    result = CliRunner().invoke(app, ["--help"])
    assert result.exit_code == 0
    assert callable(_build_package)
    assert V21Options is not None
