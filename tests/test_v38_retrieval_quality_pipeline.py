from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workbench_contracts import generate_workbench_contracts
from tests.v38_helpers import read_json


def test_pipeline_visibility_only_when_retrieval_quality_enabled(tmp_path):
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing is 20 dollars. Revenue is growing.", encoding="utf-8")
    default_config = tmp_path / "default.yaml"
    enabled_config = tmp_path / "enabled.yaml"
    default_output = tmp_path / "default"
    enabled_output = tmp_path / "enabled"
    default_config.write_text(f"task: build\ninput: {input_dir.as_posix()}\noutput: {default_output.as_posix()}\n", encoding="utf-8")
    enabled_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {enabled_output.as_posix()}
retrieval_quality:
  enabled: true
""",
        encoding="utf-8",
    )

    assert CliRunner().invoke(app, ["pipeline", "--config", str(default_config)]).exit_code == 0
    assert CliRunner().invoke(app, ["pipeline", "--config", str(enabled_config)]).exit_code == 0
    default_stages = _stages(default_output)
    enabled_stages = _stages(enabled_output)
    assert default_stages["multi_query_recall"]["enabled"] is False
    assert enabled_stages["multi_query_recall"]["enabled"] is True
    assert enabled_stages["knowledge_accuracy"]["status"] == "success"


def test_workbench_contracts_expose_v38_capabilities(tmp_path):
    core = tmp_path / "core"
    core.mkdir()
    write_json(core / "manifest.json", {"package_id": "demo"})
    for name in [
        "retrieval_quality_report.json",
        "rerank_report.json",
        "evidence_selection_trace.json",
        "claim_verification_report.json",
        "knowledge_accuracy_report.json",
        "v38_external_absorption_map.json",
    ]:
        write_json(core / name, {"status": "pass"})

    generate_workbench_contracts(core)

    status = read_json(core / "workbench_status_contract.json")
    actions = read_json(core / "workbench_action_contract.json")["actions"]
    assets = read_json(core / "workbench_asset_contract.json")["assets"]
    assert status["retrieval_quality_available"] is True
    assert status["retrieval_quality_network_required"] is False
    assert {"eval-retrieval", "verify-claims", "check-knowledge-accuracy"}.issubset({action["command"] for action in actions})
    assert "v38_external_absorption_map_json" in {asset["asset_id"] for asset in assets}


def _stages(output):
    return {stage["name"]: stage for stage in read_json(output / "pipeline_manifest.json")["stages"]}
