from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workbench_contracts import generate_workbench_contracts
from tests.structured_skill_helpers import read_json


def test_workbench_contracts_expose_structured_book_to_skill_status_and_actions(tmp_path):
    core = tmp_path / "core"
    structured = core / "structured_skill_package"
    structured.mkdir(parents=True)
    (structured / "SKILL.md").write_text("# Skill\n", encoding="utf-8")
    write_json(structured / "skill_manifest.json", {"skill_id": "demo"})
    write_json(structured / "on_demand_load_manifest.json", {"enabled": True})
    write_json(core / "structured_skill_package_completion_report.json", {"status": "pass"})
    write_json(core / "book_to_skill_benchmark_absorption_report.json", {"status": "pass"})
    write_json(core / "skill_agent_kb_compatibility_report.json", {"status": "pass"})
    write_json(core / "skill_governance_report.json", {"status": "pass"})
    write_json(core / "evidence_windows.json", {"window_count": 1})
    write_json(core / "methodology_map.json", {"module_count": 1})

    generate_workbench_contracts(core)

    status = read_json(core / "workbench_status_contract.json")
    actions = read_json(core / "workbench_action_contract.json")["actions"]
    assets = read_json(core / "workbench_asset_contract.json")["assets"]
    assert status["structured_skill_package_available"] is True
    assert status["book_to_skill_absorption_available"] is True
    assert status["skill_on_demand_loading_available"] is True
    assert status["skill_governance_report_available"] is True
    assert status["methodology_map_available"] is True
    assert status["evidence_windows_available"] is True
    assert {"book-to-skill", "extract-methodology", "validate-skill-package", "diff-skill-package", "skill-governance-report"}.issubset({action["command"] for action in actions})
    assert {"structured_skill_package_SKILL_md", "structured_skill_package_skill_manifest_json", "skill_governance_report_json", "evidence_windows_json", "methodology_map_json"}.issubset({asset["asset_id"] for asset in assets})
