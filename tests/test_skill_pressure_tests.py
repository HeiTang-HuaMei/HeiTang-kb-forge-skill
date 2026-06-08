from tests.structured_skill_helpers import make_structured_skill, read_json


def test_each_nested_skill_has_positive_and_bait_negative_tests(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    report = read_json(skill / "skill_pressure_test_report.json")

    assert report["status"] == "pass"
    assert report["case_count"] >= 1
    for case in report["cases"]:
        assert case["positive_trigger_pass"] is True
        assert case["bait_negative_trigger_pass"] is True
        assert (skill / case["test_prompts_file"]).exists()
