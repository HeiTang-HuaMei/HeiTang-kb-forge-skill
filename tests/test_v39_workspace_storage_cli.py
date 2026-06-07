from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from tests.v39_helpers import make_workspace, read_json


def test_workspace_storage_cli_commands_write_reports(tmp_path):
    workspace = make_workspace(tmp_path)
    output = tmp_path / "out"
    result = CliRunner().invoke(app, ["scan-workspace", "--workspace", str(workspace), "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert read_json(output / "workspace_registry.json")["storage_backend"] == "local_workspace"
    assert (output / "v39_external_absorption_map.json").exists()


def test_memory_and_parser_cli_commands_write_reports(tmp_path):
    memory_out = tmp_path / "memory"
    result = CliRunner().invoke(app, ["plan-memory-lifecycle", "--output", str(memory_out)])
    assert result.exit_code == 0, result.output
    assert read_json(memory_out / "token_budget_policy.json")["prevent_all_history_injection"] is True

    pdf = tmp_path / "sample.pdf"
    pdf.write_bytes(b"%PDF-1.4\n(Hello local PDF evidence)\n%%EOF")
    parser_out = tmp_path / "parser"
    result = CliRunner().invoke(app, ["report-pdf-token-reduction", "--source", str(pdf), "--output", str(parser_out)])
    assert result.exit_code == 0, result.output
    assert read_json(parser_out / "no_cloud_upload_report.json")["no_external_api_calls"] is True


def test_parser_cli_has_stable_missing_source_error(tmp_path):
    result = CliRunner().invoke(app, ["preprocess-pdf-markdown", "--source", str(tmp_path / "missing.pdf"), "--output", str(tmp_path / "out")])
    assert result.exit_code != 0
    assert "--source must exist" in result.output
