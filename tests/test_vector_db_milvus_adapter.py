from heitang_kb_forge.pre_v4_p0.vector_db import MilvusAdapter, run_contract


def test_milvus_adapter_supports_contract_query_filter_and_stale_detection():
    report = run_contract("milvus")
    readiness = MilvusAdapter().readiness()

    assert report["status"] == "implemented_offline_contract_tested"
    assert report["query_returned"] >= 1
    assert report["metadata_filter_pass"] is True
    assert report["supports_stale_index_detection"] is True
    assert readiness["provider"] == "milvus"
    assert readiness["status"] == "implemented_needs_live_acceptance"
