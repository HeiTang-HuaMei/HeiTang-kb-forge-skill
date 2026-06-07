import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workbench_contracts import generate_workbench_contracts
from tests.v310_helpers import read_json


def test_pipeline_reports_local_agent_runtime_only_when_enabled(tmp_path):
    default_output = _run_pipeline(tmp_path, False)
    enabled_output = _run_pipeline(tmp_path, True)

    assert _stages(default_output)["local_agent_runtime"]["enabled"] is False
    assert _stages(enabled_output)["local_agent_runtime"]["status"] == "success"


def test_workbench_contracts_expose_local_agent_runtime_contracts(tmp_path):
    core = tmp_path / "core"
    core.mkdir()
    write_json(core / "manifest.json", {"package_id": "pkg"})
    for name in [
        "local_agent_runtime_status.json",
        "mother_child_runtime_trace.json",
        "child_task_route_trace.json",
        "child_kb_access_report.json",
        "child_memory_isolation_report.json",
        "workflow_shared_memory_report.json",
        "parent_memory_writeback_actions.json",
    ]:
        write_json(core / name, {"status": "pass"})

    generate_workbench_contracts(core)

    status = read_json(core / "workbench_status_contract.json")
    actions = {action["id"] for action in read_json(core / "workbench_action_contract.json")["actions"]}
    assets = {asset["asset_id"] for asset in read_json(core / "workbench_asset_contract.json")["assets"]}
    hierarchy = read_json(core / "workbench_hierarchy_contract.json")
    assert status["local_agent_runtime_available"] is True
    assert status["child_kb_access_report_available"] is True
    assert "run_local_agent" in actions
    assert "local_agent_runtime_status_json" in assets
    assert "local_agent_runtime_status.json" in hierarchy["runtime_files"]


def _run_pipeline(tmp_path, enabled):
    input_dir = tmp_path / ("input_enabled" if enabled else "input_default")
    output = tmp_path / ("output_enabled" if enabled else "output_default")
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pipeline local runtime evidence.", encoding="utf-8")
    config = tmp_path / ("enabled.yaml" if enabled else "default.yaml")
    enabled_block = """
local_agent_runtime:
  enabled: true
  task: pricing policy
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
