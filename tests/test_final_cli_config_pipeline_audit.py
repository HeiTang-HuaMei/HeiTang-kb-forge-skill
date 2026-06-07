from tests.final_audit_helpers import load_json, run_audit, run_audit_cli


def test_final_audit_cli_generates_blocked_gate(tmp_path):
    output, result = run_audit_cli(tmp_path)

    assert result.exit_code == 0, result.output
    assert "Final pre-v4 audit: blocked" in result.output
    gate = load_json(output, "final_v4_rc_gate_report.json")
    assert gate["ready_for_v4_rc"] is False


def test_cli_config_pipeline_audit_covers_commands_and_config(tmp_path):
    output, _ = run_audit(tmp_path)

    cli = load_json(output, "cli_contract_audit_report.json")
    config = load_json(output, "config_pipeline_audit_report.json")
    assert "final-pre-v4-audit" in cli["required_commands"]
    assert cli["status"] == "pass"
    assert "QueryRewriteConfig" in config["required_config_markers"]
    assert config["tests_require_real_llm_api_network"] is False
