import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workbench_contracts import generate_workbench_contracts


def test_workbench_contracts_describe_core_assets_and_actions(tmp_path):
    core = tmp_path / "core"
    core.mkdir()
    write_json(core / "manifest.json", {"package_id": "demo"})
    write_json(core / "generated_file_report.json", {"status": "pass"})
    (core / "skill_package").mkdir()
    (core / "skill_package" / "SKILL.md").write_text("# Demo Skill\n", encoding="utf-8")

    result = generate_workbench_contracts(core, project_name="Demo Workbench")

    assert result["status"] == "ready"
    assert _json(core / "workbench_status_contract.json")["asset_count"] == 3
    actions = _json(core / "workbench_action_contract.json")["actions"]
    assert {action["command"] for action in actions} >= {"build", "generate-documents", "generate-bound-agent"}
    assert (core / "workbench_contract_report.md").exists()


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
