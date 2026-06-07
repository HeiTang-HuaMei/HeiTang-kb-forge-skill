import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from tests.test_v311_golden_demo_acceptance import _package


def test_run_golden_demo_acceptance_cli_writes_reports(tmp_path):
    package = _package(tmp_path)
    output = tmp_path / "out"

    result = CliRunner().invoke(
        app,
        [
            "run-golden-demo-acceptance",
            "--package",
            str(package),
            "--output",
            str(output),
            "--no-require-v37",
            "--no-require-v38",
            "--no-require-v39",
            "--no-require-v310",
        ],
    )

    assert result.exit_code == 0, result.output
    payload = json.loads((output / "real_acceptance_smoke_result.json").read_text(encoding="utf-8"))
    assert payload["status"] == "pass"
    assert "Golden demo acceptance: pass" in result.output


def test_run_golden_demo_acceptance_cli_rejects_llm_and_network(tmp_path):
    package = _package(tmp_path)

    result = CliRunner().invoke(app, ["run-golden-demo-acceptance", "--package", str(package), "--output", str(tmp_path / "out"), "--allow-network"])

    assert result.exit_code != 0
    assert "--allow-network is reserved and must remain false in v3.11" in result.output
