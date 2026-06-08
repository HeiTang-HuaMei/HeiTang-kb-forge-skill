from tests.structured_skill_helpers import make_structured_skill, read_json


def test_rejected_skill_candidates_have_reasons(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    report = read_json(skill / "skill_rejected_candidates_report.json")

    assert report["status"] == "pass"
    assert report["rejected_count"] >= 1
    assert all(item["reason"] for item in report["rejected_candidates"])
    assert any((skill / "rejected").glob("*.json"))
