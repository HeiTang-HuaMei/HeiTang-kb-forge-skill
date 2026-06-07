import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from tests.test_v312_product_hardening import _package, _workspace


def test_product_hardening_cli_writes_release_readiness(tmp_path):
    workspace = _workspace(tmp_path)
    package = _package(tmp_path)
    output = tmp_path / "out"

    result = CliRunner().invoke(
        app,
        [
            "product-hardening",
            "--workspace",
            str(workspace),
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
    payload = json.loads((output / "local_release_readiness_result.json").read_text(encoding="utf-8"))
    assert payload["release_ready"] is True
    assert "Product hardening: pass" in result.output


def test_product_hardening_cli_rejects_llm_and_network(tmp_path):
    workspace = _workspace(tmp_path)
    package = _package(tmp_path)

    result = CliRunner().invoke(app, ["product-hardening", "--workspace", str(workspace), "--package", str(package), "--output", str(tmp_path / "out"), "--allow-llm"])

    assert result.exit_code != 0
    assert "--allow-llm is reserved and must remain false in v3.12" in result.output
