import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workbench_contracts import generate_workbench_contracts
from tests.v39_helpers import read_json


def test_pipeline_reports_v39_stages_only_when_enabled(tmp_path):
    default_output = _run_pipeline(tmp_path, False)
    enabled_output = _run_pipeline(tmp_path, True)

    default = _stages(default_output)
    enabled = _stages(enabled_output)
    assert default["workspace_storage_registry"]["enabled"] is False
    assert enabled["workspace_storage_registry"]["status"] == "success"
    assert enabled["memory_lifecycle"]["status"] == "success"
    assert enabled["local_document_parsing_token_reduction"]["status"] == "success"
    assert enabled["v39_external_absorption_map"]["status"] == "success"


def test_workbench_contracts_expose_v39_storage_memory_and_parser(tmp_path):
    core = tmp_path / "core"
    core.mkdir()
    write_json(core / "manifest.json", {"package_id": "pkg"})
    for name in [
        "workspace_registry.json",
        "storage_usage_report.json",
        "cleanup_plan.json",
        "token_budget_policy.json",
        "parser_backend_benchmark_report.json",
        "pdf_token_reduction_report.json",
        "no_cloud_upload_report.json",
        "v39_external_absorption_map.json",
    ]:
        write_json(core / name, {"status": "pass"})

    generate_workbench_contracts(core)

    status = read_json(core / "workbench_status_contract.json")
    actions = {action["id"] for action in read_json(core / "workbench_action_contract.json")["actions"]}
    assets = {asset["asset_id"] for asset in read_json(core / "workbench_asset_contract.json")["assets"]}
    storage = read_json(core / "workbench_storage_contract.json")
    memory = read_json(core / "workbench_memory_contract.json")
    assert status["workspace_storage_available"] is True
    assert status["pdf_token_reduction_available"] is True
    assert "scan_workspace_storage" in actions
    assert "v39_external_absorption_map_json" in assets
    assert storage["parser_backend_contracts"]["no_cloud_upload_required"] is True
    assert memory["token_budget"]["prevent_all_history_injection"] is True


def _run_pipeline(tmp_path, enabled):
    input_dir = tmp_path / ("input_enabled" if enabled else "input_default")
    output = tmp_path / ("output_enabled" if enabled else "output_default")
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pipeline v39 evidence.", encoding="utf-8")
    config = tmp_path / ("enabled.yaml" if enabled else "default.yaml")
    enabled_block = """
workspace_storage:
  enabled: true
memory_lifecycle:
  enabled: true
document_parsing:
  local_pdf_markdown: true
  parser_backend_benchmark: true
  pdf_token_reduction_report: true
""" if enabled else ""
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
{enabled_block}
""",
        encoding="utf-8",
    )
    result = CliRunner().invoke(app, ["pipeline", "--config", str(config)])
    assert result.exit_code == 0, result.output
    return output


def _stages(output):
    return {stage["name"]: stage for stage in json.loads((output / "pipeline_manifest.json").read_text(encoding="utf-8"))["stages"]}
