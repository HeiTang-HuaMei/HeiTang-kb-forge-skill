import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.demo_e2e import run_demo_e2e


def test_demo_e2e_outputs_report_evidence_pack_and_limitations(tmp_path):
    output = tmp_path / "demo"

    result = run_demo_e2e(output)

    assert result["offline"] is True
    assert result["network_called"] is False
    assert (output / "demo_e2e_result.json").exists()
    assert (output / "portfolio_demo_report.md").exists()
    assert (output / "demo_evidence_pack").is_dir()
    assert (output / "runtime_limitations.md").exists()
    stages = {item["name"]: item["status"] for item in result["stages"]}
    assert "build_knowledge_package" in stages
    assert "quality_gate" in stages
    assert "provider_security_audit" in stages
    assert "llm_quality_gate_assist_mock" in stages
    assert "export_platform_generic_codex_openclaw" in stages
    assert "release_readiness" in stages


def test_demo_e2e_cli_smoke_and_required_files(tmp_path):
    output = tmp_path / "demo"

    cli_result = CliRunner().invoke(app, ["demo-e2e", "--output", str(output)])

    assert cli_result.exit_code == 0, cli_result.output
    payload = json.loads((output / "demo_e2e_result.json").read_text(encoding="utf-8"))
    assert payload["mock_provider"] is True
    assert payload["real_platform_runtime_executed"] is False
    assert payload["mcp_server_started"] is False
    assert payload["xhs_auto_publish"] is False
    assert (output / "demo_evidence_pack" / "evidence_manifest.json").exists()


def test_demo_e2e_report_and_runtime_limitations_do_not_claim_real_runtime(tmp_path):
    output = tmp_path / "demo"
    run_demo_e2e(output)

    report = (output / "portfolio_demo_report.md").read_text(encoding="utf-8")
    limitations = (output / "runtime_limitations.md").read_text(encoding="utf-8")

    assert "Real platform runtime executed: False" in report
    assert "No MCP server is started" in limitations
    assert "No Xiaohongshu note is published" in limitations
    assert "Runtime compatibility remains reserved" in limitations


def test_v27_demo_config_exists_and_mentions_demo_e2e():
    config = "examples/configs/kb_forge.v27.yaml"

    text = open(config, encoding="utf-8").read()

    assert "demo_e2e" in text
    assert "offline" in text
