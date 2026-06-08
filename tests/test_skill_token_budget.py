from tests.structured_skill_helpers import make_structured_skill, read_json


def test_skill_token_budget_keeps_entrypoint_bounded(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    report = read_json(skill / "token_budget_report.json")

    assert report["status"] == "pass"
    assert report["entrypoint_estimated_tokens"] < report["token_budget"]
    assert report["full_book_loaded_by_default"] is False
    assert report["all_history_loaded_by_default"] is False
