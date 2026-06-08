from heitang_kb_forge.pre_v4_p0 import run_rag_quality_metrics_completion
from tests.p0_helpers import make_p0_package, read_json


def test_rag_golden_evalset_supports_100_question_format(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_rag_quality_metrics_completion(package, output)
    report = read_json(output / "rag_golden_evalset_report.json")

    assert report["status"] == "pass"
    assert report["supports_100_question_golden_set_format"] is True
    assert report["regression_after_retrieval_change"] is True
    assert "case_id" in report["golden_set_schema"]
