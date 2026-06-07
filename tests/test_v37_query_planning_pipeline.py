import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workbench_contracts import generate_workbench_contracts


def test_pipeline_reports_query_rewrite_only_when_enabled(tmp_path):
    input_dir = tmp_path / "input"
    default_output = tmp_path / "default"
    enabled_output = tmp_path / "enabled"
    default_config = tmp_path / "default.yaml"
    enabled_config = tmp_path / "enabled.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing and revenue evidence.", encoding="utf-8")
    default_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {default_output.as_posix()}
""",
        encoding="utf-8",
    )
    enabled_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {enabled_output.as_posix()}
retrieval:
  enabled: true
  query: pricing revenue
query_rewrite:
  enabled: true
  retrieval_purpose: validation
""",
        encoding="utf-8",
    )

    default_result = CliRunner().invoke(app, ["pipeline", "--config", str(default_config)])
    enabled_result = CliRunner().invoke(app, ["pipeline", "--config", str(enabled_config)])

    assert default_result.exit_code == 0, default_result.output
    assert enabled_result.exit_code == 0, enabled_result.output
    default_stages = _stages(default_output)
    enabled_stages = _stages(enabled_output)
    assert default_stages["query_rewrite"]["enabled"] is False
    assert default_stages["retrieval_planning"]["status"] == "skipped"
    assert enabled_stages["query_rewrite"]["enabled"] is True
    assert enabled_stages["query_rewrite"]["status"] == "success"
    assert enabled_stages["retrieval_planning"]["enabled"] is True
    assert enabled_stages["retrieval_planning"]["status"] == "success"
    assert _json(enabled_output / "retrieval_plan.json")["retrieval_purpose"] == "validation"


def test_workbench_contracts_expose_query_rewrite_and_retrieval_planning(tmp_path):
    core = tmp_path / "core"
    core.mkdir()
    write_json(core / "manifest.json", {"package_id": "demo"})
    write_json(core / "query_rewrite_trace.json", {"status": "pass"})
    write_json(core / "query_rewrite_report.json", {"status": "pass"})
    write_json(core / "retrieval_plan.json", {"retrieval_purpose": "answering"})
    (core / "retrieval_plan_report.md").write_text("# Retrieval Plan\n", encoding="utf-8")

    generate_workbench_contracts(core)

    status = _json(core / "workbench_status_contract.json")
    actions = _json(core / "workbench_action_contract.json")["actions"]
    navigation = _json(core / "workbench_navigation_contract.json")["views"]
    assets = _json(core / "workbench_asset_contract.json")["assets"]
    assert status["query_rewrite_available"] is True
    assert status["retrieval_plan_available"] is True
    assert status["retrieval_purposes"] == ["answering", "validation"]
    assert {"rewrite-query", "plan-retrieval"}.issubset({action["command"] for action in actions})
    assert {"query_rewrite", "retrieval_planning"}.issubset({view["id"] for view in navigation})
    assert {"query_rewrite_trace_json", "retrieval_plan_json"}.issubset({asset["asset_id"] for asset in assets})


def _stages(output):
    return {stage["name"]: stage for stage in _json(output / "pipeline_manifest.json")["stages"]}


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
