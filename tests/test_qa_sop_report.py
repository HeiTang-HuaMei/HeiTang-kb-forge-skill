from heitang_kb_forge.pre_v4_p0 import run_knowledge_governance_completion
from tests.p0_helpers import make_p0_package, read_json


def test_qa_sop_report_specifies_no_answer_citation_and_review_rules(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_knowledge_governance_completion(package, output)
    report = read_json(output / "qa_sop_report.json")

    assert report["status"] == "pass"
    assert report["no_answer_handling"] == "refuse_with_missing_evidence_reason"
    assert report["citation_rule"] == "citation_required_for_factual_answers"
    assert "review_required" in report["review_required_rule"]
