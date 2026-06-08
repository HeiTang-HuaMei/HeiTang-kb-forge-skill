from tests.structured_skill_helpers import make_structured_skill, read_json


def test_cangjie_skill_absorption_creates_clean_room_structured_repository(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    report = read_json(skill / "cangjie_skill_absorption_report.json")
    completion = read_json(skill / "structured_skill_package_completion_report.json")

    assert report["status"] == "pass"
    assert report["benchmark"] == "cangjie-skill"
    assert report["external_code_or_prompts_copied"] is False
    assert completion["nested_skills_exist"] is True
    assert completion["skill_graph_exists"] is True
    assert completion["pressure_tests_passed"] is True
