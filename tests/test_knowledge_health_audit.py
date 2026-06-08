from heitang_kb_forge.pre_v4_p0 import run_knowledge_governance_completion
from tests.p0_helpers import make_p0_package, read_json


def test_knowledge_health_audit_warns_about_blind_ingestion_and_review(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_knowledge_governance_completion(package, output)
    report = read_json(output / "knowledge_health_audit_report.json")

    assert report["status"] == "pass"
    assert report["blind_ingestion_warning"] is True
    assert report["update_frequency"] == "quarterly_review_recommended"
    assert "who_maintains" in report
