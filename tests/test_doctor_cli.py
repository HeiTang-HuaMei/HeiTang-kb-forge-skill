import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_doctor_cli_writes_v251_result_contract(tmp_path):
    output = tmp_path / "doctor"

    result = CliRunner().invoke(app, ["doctor", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "doctor_result.json").read_text(encoding="utf-8"))
    names = {check["name"] for check in payload["checks"]}
    assert "python_version" in names
    assert "package_import" in names
    assert "cli_availability" in names
    assert "examples_quickstart_input_exists" in names
    assert "mock_provider_available" in names
    assert "network_not_required" in names

