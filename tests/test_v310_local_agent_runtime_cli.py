from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from tests.v310_helpers import make_agent, make_package, read_json


def test_run_local_agent_cli_writes_runtime_reports(tmp_path):
    package = make_package(tmp_path, "alpha")
    child = make_agent(tmp_path, "alpha-child", "kb_bound", "alpha")
    output = tmp_path / "runtime"

    result = CliRunner().invoke(app, ["run-local-agent", "--package", str(package), "--agent", str(child), "--task", "pricing policy", "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert read_json(output / "local_agent_runtime_status.json")["status"] == "pass"
    assert (output / "local_agent_runtime_report.md").exists()


def test_run_local_agent_cli_stable_errors_for_missing_package_and_reserved_modes(tmp_path):
    output = tmp_path / "runtime"
    result = CliRunner().invoke(app, ["run-local-agent", "--task", "x", "--output", str(output)])
    assert result.exit_code != 0
    assert "--package is required" in result.output

    package = make_package(tmp_path, "alpha")
    result = CliRunner().invoke(app, ["run-local-agent", "--package", str(package), "--task", "x", "--output", str(output), "--allow-llm"])
    assert result.exit_code != 0
    assert "--allow-llm is reserved" in result.output
