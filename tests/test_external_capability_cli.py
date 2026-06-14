import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_external_capability_registry_cli_writes_reports(tmp_path):
    output = tmp_path / "s_a_contract"

    result = CliRunner().invoke(app, ["external-capability-registry", "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert _json(output / "external_capability_registry.json")["external_project_count"] == 26
    assert _json(output / "s_a_contract_inclusion_matrix.json")["external_project_count"] == 26
    assert _json(output / "provider_boundary_report.json")["provider_network_api_ready"] is False
    assert (output / "external_capability_registry.md").exists()


def test_external_capability_inspect_cli_reads_one_project_without_runtime(tmp_path):
    output = tmp_path / "inspect"

    result = CliRunner().invoke(
        app,
        ["external-capability-inspect", "--project-id", "anysearchskill", "--output", str(output)],
    )

    assert result.exit_code == 0, result.output
    payload = json.loads(result.output)
    assert payload["project_id"] == "anysearchskill"
    assert payload["requires_api_key"] is False
    assert payload["requires_network"] is True
    assert payload["contract_status"] == [
        "provider_adapter",
        "real_smoke_passed",
        "needs_strengthening",
    ]
    assert payload["can_execute_locally_before_v4"] is False
    assert _json(output / "external_capability_inspect.json")["project_id"] == "anysearchskill"


def test_external_capability_matrix_cli_writes_visibility_matrix(tmp_path):
    output = tmp_path / "matrix"

    result = CliRunner().invoke(app, ["external-capability-matrix", "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert _json(output / "s_a_contract_inclusion_matrix.json")["external_project_count"] == 26
    assert _json(output / "workbench_capability_matrix.json")["page_count"] >= 8
    assert (output / "s_a_contract_inclusion_matrix.md").exists()


def test_planned_adapter_status_cli_writes_boundary_reports(tmp_path):
    output = tmp_path / "adapter_status"

    result = CliRunner().invoke(app, ["planned-adapter-status", "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert _json(output / "planned_adapter_status_report.json")["ready_count"] == 0
    assert _json(output / "provider_boundary_report.json")["n8n_bundled_runtime"] is False
    assert (output / "provider_boundary_report.md").exists()


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
