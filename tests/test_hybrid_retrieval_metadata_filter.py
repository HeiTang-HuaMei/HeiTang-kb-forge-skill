from heitang_kb_forge.pre_v4_p0 import run_rag_index_completion

from tests.p0_helpers import make_p0_package, read_json


def test_hybrid_retrieval_report_covers_merge_dedup_filter_and_selection(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    run_rag_index_completion(package, output)
    report = read_json(output / "hybrid_retrieval_report.json")

    assert report["status"] == "pass"
    assert report["keyword_retrieval"] is True
    assert report["vector_retrieval"] is True
    assert report["merge_dedup"] is True
    assert report["metadata_filter"] is True
    assert report["selected_rejected_reasons"] is True
