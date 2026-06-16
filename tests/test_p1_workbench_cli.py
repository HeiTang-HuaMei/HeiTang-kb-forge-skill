import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.exporters.jsonl_exporter import write_json


def test_p1_workbench_contracts_cli_writes_contract_pack(tmp_path):
    output = tmp_path / "p1_contracts"

    result = CliRunner().invoke(app, ["workbench-contracts", "--profile", "p1", "--output", str(output)])

    assert result.exit_code == 0, result.output
    manifest = _json(output / "workbench_manifest.json")
    assert manifest["profile"] == "p1"
    assert manifest["core_contract_ready"] is True
    assert manifest["p1_full_operation_gate_status"] == "blocked"
    assert _json(output / "workbench_p1_gate_report.json")["ui_full_operation_pending"] is True


def test_p1_workbench_action_inspect_and_dry_run_cli(tmp_path):
    runner = CliRunner()

    inspect_result = runner.invoke(app, ["workbench-action-inspect", "--action-id", "inspect_dashboard_status"])
    assert inspect_result.exit_code == 0, inspect_result.output
    assert json.loads(inspect_result.output)["action_id"] == "inspect_dashboard_status"

    output = tmp_path / "dry_run"
    dry_run_result = runner.invoke(app, ["workbench-action-dry-run", "--action-id", "inspect_dashboard_status", "--output", str(output)])
    assert dry_run_result.exit_code == 0, dry_run_result.output
    dry_run = _json(output / "workbench_action_dry_run.json")
    assert dry_run["executes_real_operation"] is False
    assert dry_run["trace_id"] == "dry_run_inspect_dashboard_status"
    assert dry_run["product_status"] == "queued"
    assert dry_run["contract_command"] == dry_run["would_run_command"]
    assert dry_run["output_reports"] == ["report_p1_gate_summary", "report_system_health"]


def test_p1_workbench_smoke_cli_writes_gate_status(tmp_path):
    output = tmp_path / "smoke"

    result = CliRunner().invoke(app, ["workbench-smoke", "--output", str(output)])

    assert result.exit_code == 0, result.output
    smoke = _json(output / "workbench_smoke_result.json")
    assert smoke["status"] == "pass"
    assert smoke["p1_full_operation_gate_status"] == "blocked"


def test_workbench_contracts_legacy_default_behavior_is_unchanged(tmp_path):
    core = tmp_path / "core"
    output = tmp_path / "legacy"
    core.mkdir()
    write_json(core / "manifest.json", {"package_id": "demo"})

    result = CliRunner().invoke(app, ["workbench-contracts", "--core-output", str(core), "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert _json(output / "workbench_contract_manifest.json")["status"] == "ready"
    assert (output / "workbench_action_contract.json").exists()
    assert not (output / "workbench_manifest.json").exists()


def test_p1_workbench_config_profile_writes_pipeline_contract_files(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "p1.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("P1 Workbench contract evidence.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
workbench_contracts:
  enabled: true
  profile: p1
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])
    assert result.exit_code == 0, result.output
    assert _json(output_dir / "workbench_manifest.json")["profile"] == "p1"

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])
    assert result.exit_code == 0, result.output
    stages = {stage["name"]: stage for stage in _json(output_dir / "pipeline_manifest.json")["stages"]}
    assert "workbench_manifest.json" in stages["workbench_contracts"]["output_files"]


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
