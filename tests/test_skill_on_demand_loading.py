from tests.structured_skill_helpers import make_structured_skill, read_json


def test_on_demand_loading_manifest_maps_intents_without_full_book_injection(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    manifest = read_json(skill / "on_demand_load_manifest.json")
    report = read_json(skill / "on_demand_loading_report.json")

    assert manifest["enabled"] is True
    assert manifest["default_entrypoint"] == "SKILL.md"
    assert manifest["full_book_prompt_injection_default"] is False
    assert manifest["all_history_injection_default"] is False
    assert "agent_binding" in manifest["intent_to_files"]
    assert "skill_agent_kb_compatibility_report.json" in manifest["intent_to_files"]["agent_binding"]
    assert report["status"] == "pass"
