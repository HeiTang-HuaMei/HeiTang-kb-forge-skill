from heitang_kb_forge.pre_v4_p0 import run_rag_quality_metrics_completion
from tests.p0_helpers import make_p0_package, read_json


def test_hybrid_retrieval_ranking_records_keyword_vector_filter_and_rerank(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_rag_quality_metrics_completion(package, output)
    report = read_json(output / "hybrid_retrieval_ranking_report.json")

    assert report["status"] == "pass"
    assert report["keyword_retrieval"] is True
    assert report["vector_retrieval"] is True
    assert report["weighted_merge"] is True
    assert report["metadata_filter"] is True
    assert report["rerank"] is True
    assert report["lambdamart_status"] == "adapter_future_not_claimed_implemented"
