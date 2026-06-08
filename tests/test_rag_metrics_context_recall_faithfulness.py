from heitang_kb_forge.pre_v4_p0 import run_rag_quality_metrics_completion
from tests.p0_helpers import make_p0_package, read_json


def test_rag_metrics_include_context_recall_and_faithfulness(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    report = run_rag_quality_metrics_completion(package, output)
    metrics = read_json(output / "rag_metrics_report.json")

    assert report["status"] == "pass"
    assert metrics["status"] == "pass"
    assert metrics["metrics"]["context_recall"] > 0
    assert metrics["metrics"]["faithfulness"] > 0
    assert metrics["metrics"]["context_precision"] > 0
    assert metrics["tests_require_real_llm_api_network"] is False
