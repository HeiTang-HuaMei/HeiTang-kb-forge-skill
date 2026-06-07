from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from tests.v38_helpers import make_package, read_json


def test_eval_retrieval_cli_writes_v38_reports(tmp_path):
    package = make_package(tmp_path)
    output = tmp_path / "out"

    result = CliRunner().invoke(app, ["eval-retrieval", "--package", str(package), "--output", str(output), "--query", "pricing revenue"])

    assert result.exit_code == 0, result.output
    assert (output / "retrieval_quality_report.json").exists()
    assert (output / "v38_external_absorption_map.json").exists()
    assert read_json(output / "retrieval_quality_report.json")["tests_require_real_llm_api_network"] is False


def test_eval_retrieval_cli_rejects_network_and_llm_judge(tmp_path):
    package = make_package(tmp_path)

    network = CliRunner().invoke(app, ["eval-retrieval", "--package", str(package), "--output", str(tmp_path / "n"), "--allow-external-network"])
    llm = CliRunner().invoke(app, ["eval-retrieval", "--package", str(package), "--output", str(tmp_path / "l"), "--allow-llm-judge"])

    assert network.exit_code != 0
    assert "allow_external_network must remain false" in network.output
    assert llm.exit_code != 0
    assert "allow_llm_judge must remain false" in llm.output


def test_stage_clis_write_stable_reports(tmp_path):
    package = make_package(tmp_path)

    commands = [
        ["rerank-results", "--package", str(package), "--query", "pricing revenue", "--output", str(tmp_path / "rerank")],
        ["select-evidence", "--package", str(package), "--query", "pricing revenue", "--output", str(tmp_path / "evidence")],
        ["diagnose-retrieval-failure", "--package", str(package), "--query", "unknown", "--output", str(tmp_path / "diag")],
        ["verify-claims", "--package", str(package), "--output", str(tmp_path / "verify")],
        ["check-knowledge-accuracy", "--package", str(package), "--output", str(tmp_path / "accuracy")],
    ]
    for command in commands:
        result = CliRunner().invoke(app, command)
        assert result.exit_code == 0, result.output
