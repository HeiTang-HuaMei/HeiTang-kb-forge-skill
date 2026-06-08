from heitang_kb_forge.pre_v4_p0 import run_rag_index_completion

from tests.p0_helpers import make_p0_package


def test_rag_index_completion_report_passes_full_local_loop(tmp_path):
    package = make_p0_package(tmp_path)
    report = run_rag_index_completion(package, tmp_path / "out")

    assert report["status"] == "pass"
    assert report["chunk_strategy_status"] == "pass"
    assert report["metadata_schema_status"] == "pass"
    assert report["local_vector_index_status"] == "pass"
    assert report["hybrid_retrieval_status"] == "pass"
    assert report["incremental_update_status"] == "pass"
    assert report["stale_index_detection_status"] == "pass"
