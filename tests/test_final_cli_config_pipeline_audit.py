from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from tests.final_audit_helpers import load_json, run_audit, run_audit_cli


def test_final_audit_cli_generates_blocked_gate(tmp_path):
    output, result = run_audit_cli(tmp_path)

    assert result.exit_code == 0, result.output
    assert "Final pre-v4 audit: blocked" in result.output
    gate = load_json(output, "final_v4_rc_gate_report.json")
    assert gate["ready_for_v4_rc"] is False


def test_final_audit_cli_accepts_explicit_validation_evidence(tmp_path):
    output, result = run_audit_cli(
        tmp_path,
        core_validation={"status": "pass", "focused": "pass", "full": "pass", "command": "python -m pytest"},
        ui_validation={"status": "pass", "flutter_analyze": "pass", "flutter_test": "pass"},
        ci_status={"status": "pass", "run": "27131427574", "conclusion": "success"},
    )

    assert result.exit_code == 0, result.output
    assert "Final pre-v4 audit: ready_for_v4_rc" in result.output
    gate = load_json(output, "final_v4_rc_gate_report.json")
    assert gate["ready_for_v4_rc"] is True
    assert gate["core_validation"]["full"] == "pass"
    assert gate["ci_status"]["run"] == "27131427574"


def test_final_audit_cli_rejects_invalid_evidence_json(tmp_path):
    evidence = tmp_path / "bad.json"
    evidence.write_text("not-json", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "final-pre-v4-audit",
            "--core-repo",
            ".",
            "--output",
            str(tmp_path / "out"),
            "--core-validation",
            str(evidence),
        ],
    )

    assert result.exit_code != 0
    assert "core validation evidence must be valid JSON" in result.output


def test_final_audit_cli_accepts_utf8_bom_evidence_json(tmp_path):
    evidence = tmp_path / "core.json"
    evidence.write_text('{"status":"pass","focused":"pass","full":"pass"}', encoding="utf-8-sig")
    output = tmp_path / "out"

    result = CliRunner().invoke(
        app,
        [
            "final-pre-v4-audit",
            "--core-repo",
            ".",
            "--output",
            str(output),
            "--core-validation",
            str(evidence),
            "--ui-validation",
            str(evidence),
            "--ci-status",
            str(evidence),
        ],
    )

    assert result.exit_code == 0, result.output
    assert load_json(output, "final_v4_rc_gate_report.json")["ready_for_v4_rc"] is True


def test_cli_config_pipeline_audit_covers_commands_and_config(tmp_path):
    output, _ = run_audit(tmp_path)

    cli = load_json(output, "cli_contract_audit_report.json")
    config = load_json(output, "config_pipeline_audit_report.json")
    assert "final-pre-v4-audit" in cli["required_commands"]
    assert cli["status"] == "pass"
    assert "QueryRewriteConfig" in config["required_config_markers"]
    assert config["tests_require_real_llm_api_network"] is False
