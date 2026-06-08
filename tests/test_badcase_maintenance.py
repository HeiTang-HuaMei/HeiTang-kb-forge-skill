from heitang_kb_forge.pre_v4_p0 import run_knowledge_governance_completion
from tests.p0_helpers import make_p0_package, read_json


def test_badcase_maintenance_has_review_schedule_and_regression_trigger(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    report = run_knowledge_governance_completion(package, output)
    badcase = read_json(output / "badcase_maintenance_report.json")

    assert report["status"] == "pass"
    assert badcase["status"] == "pass"
    assert badcase["quarterly_review_recommendation"] is True
    assert badcase["regression_test_trigger_after_document_update"] is True
