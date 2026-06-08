from tests.structured_skill_helpers import make_structured_skill, read_json


def test_book_to_skill_absorption_map_is_clean_room_and_auditable(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    report = read_json(skill / "book_to_skill_benchmark_absorption_report.json")

    assert report["status"] == "pass"
    assert report["benchmark"]["decision"] == "absorb"
    assert report["benchmark"]["clean_room_implementation"] is True
    assert report["benchmark"]["external_code_or_prompts_copied"] is False
    assert "structured Skill package layout" in report["benchmark"]["what_to_absorb"]
    assert "external prompts" in report["benchmark"]["what_not_to_copy"]
