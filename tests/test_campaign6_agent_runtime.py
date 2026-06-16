import json

from typer.testing import CliRunner

from heitang_kb_forge.campaign6_agent_runtime import (
    CAMPAIGN6_6A_AGENT_TYPES,
    CAMPAIGN6_TOOL_API_CONFIG_SCHEMA,
    run_campaign6_6a_acceptance,
    run_campaign6_6b_acceptance,
    run_campaign6_tool_adapter_gate,
)
from heitang_kb_forge.cli import app


def _read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def test_campaign6a_single_agent_runtime_runs_all_required_agents(tmp_path):
    output = tmp_path / "campaign6a"

    report = run_campaign6_6a_acceptance(output)

    assert report["status"] == "pass"
    assert report["required_agent_types"] == CAMPAIGN6_6A_AGENT_TYPES
    assert set(report["accepted_agent_types"]) == set(CAMPAIGN6_6A_AGENT_TYPES)
    assert report["failure_or_degraded_path_per_agent"] is True
    assert report["mock_offline_fixture_only_accepted"] is False
    assert report["display_only_accepted"] is False
    assert report["arbitrary_shell_opened"] is False
    assert report["secret_values_written"] is False
    assert report["campaign_7_8_9_entered"] is False

    security = _read_json(output / "campaign6a_security_boundary_report.json")
    assert security["status"] == "pass"
    assert security["checks"]["no_secret_values_written"] is True
    assert security["checks"]["no_arbitrary_shell"] is True
    assert security["checks"]["no_self_authorized_tools"] is True

    runs = [
        _read_json(output / agent_type / "agent_run.json")
        for agent_type in CAMPAIGN6_6A_AGENT_TYPES
    ]
    for run in runs:
        assert run["status"] in {"succeeded", "partial_success", "degraded"}
        assert run["real_runtime_paths"], run["agent_type"]
        assert run["degraded_paths"], run["agent_type"]
        assert run["permission_policy"]["agent_can_self_authorize"] is False
        assert run["permission_policy"]["arbitrary_shell_allowed"] is False

    document_run = _read_json(output / "document_processing_agent" / "agent_run.json")
    assert document_run["status"] == "partial_success"
    workbench_run = _read_json(output / "workbench_operator_agent" / "agent_run.json")
    assert workbench_run["result"]["unknown_action"] == "blocked"


def test_campaign6b_advanced_runtime_expansion_covers_memory_multi_agent_and_security(tmp_path):
    output = tmp_path / "campaign6b"

    report = run_campaign6_6b_acceptance(output)

    assert report["status"] == "pass"
    assert report["memory_lifecycle_status"] == "pass"
    assert report["multi_agent_workflow_status"] == "pass"
    assert report["a2a_status"] == "pass"
    assert report["agent_teams_status"] == "pass"
    assert report["security_regression_status"] == "pass"
    assert report["computer_use_runtime_enabled"] is False
    assert report["campaign_7_8_9_entered"] is False

    areas = {item["area"]: item for item in report["areas"]}
    assert areas["long_term_memory"]["write"] is True
    assert areas["long_term_memory"]["deletion"] is True
    assert areas["multi_agent_workflow"]["conflict_handling"] is True
    assert areas["a2a"]["denied_message_audit"] is True
    assert areas["agent_teams"]["per_agent_isolation"] is True
    assert areas["computer_use_boundary"]["runtime_enabled"] is False


def test_campaign6_tool_adapter_configuration_gate_preserves_env_only_boundaries(tmp_path):
    output = tmp_path / "tool_adapter"

    report = run_campaign6_tool_adapter_gate(output)

    assert report["status"] == "pass"
    assert report["agent_tool_api_config_schema"] == CAMPAIGN6_TOOL_API_CONFIG_SCHEMA
    assert report["provider_runtime_reimplemented"] is False
    assert report["unregistered_third_party_api_integrated"] is False
    assert report["official_channel_tool_adapter_gate_required"] is True
    assert report["secret_plaintext_written"] is False

    adapters = {item["adapter_id"]: item for item in report["adapters"]}
    assert adapters["provider_runtime"]["status"] == "enabled_real"
    assert adapters["provider_runtime"]["api_config"]["base_url_env"] == "HEITANG_LLM_BASE_URL"
    assert adapters["provider_runtime"]["api_config"]["token_env"] == "HEITANG_LLM_API_KEY"
    assert adapters["official_channel_future"]["status"] == "disabled_boundary"
    assert adapters["official_channel_future"]["requires_official_channel_tool_adapter_gate"] is True
    assert all(item["secret_value_present"] is False for item in adapters.values())


def test_campaign6_cli_commands_write_acceptance_outputs(tmp_path):
    runner = CliRunner()
    commands = [
        ("campaign6a-single-agent-runtime-acceptance", "campaign6a_acceptance_report.json"),
        ("campaign6b-advanced-agent-runtime-acceptance", "campaign6b_acceptance_report.json"),
        ("campaign6-tool-adapter-configuration-gate", "campaign6_tool_adapter_configuration_report.json"),
    ]

    for command, filename in commands:
        output = tmp_path / command
        result = runner.invoke(app, [command, "--output", str(output)])

        assert result.exit_code == 0, result.output
        assert _read_json(output / filename)["status"] == "pass"
