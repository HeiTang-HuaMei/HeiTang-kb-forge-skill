from tests.structured_skill_helpers import make_structured_skill, read_json


def test_skill_triple_verification_records_ria_plus_plus_checks(tmp_path):
    _, skill = make_structured_skill(tmp_path)

    report = read_json(skill / "skill_triple_verification_report.json")

    assert report["status"] == "pass"
    assert report["checks"]
    first = report["checks"][0]
    assert first["two_independent_evidence_when_possible"] is True
    assert first["novel_trigger_scenario_answerable"] is True
    assert first["non_commonsense_uniqueness"] is True
