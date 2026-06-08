from heitang_kb_forge.pre_v4_p0 import run_rag_quality_metrics_completion
from tests.p0_helpers import make_p0_package, read_json


def test_query_rewrite_semantic_safety_rejects_drift(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_rag_quality_metrics_completion(package, output)
    report = read_json(output / "query_rewrite_semantic_safety_report.json")

    assert report["status"] == "pass"
    assert report["default_similarity_threshold"] == 0.8
    assert report["safe_rewrite"]["accepted"] is True
    assert report["drift_example"]["accepted"] is False
    assert report["drift_example"]["fallback"] == "pricing policy"
