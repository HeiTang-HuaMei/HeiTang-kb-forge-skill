from tests.v4_2_baseline_evidence import load_baseline_report

from tests.final_audit_helpers import load_json, run_audit




def test_rag_vector_index_report_proves_local_vector_hybrid_readiness():
    report = load_baseline_report("rag_vector_index_readiness_report.json")

    assert report["status"] == "pass"
    assert report["severity"] == "resolved"
    assert report["tests_require_real_llm_api_network"] is False
    assert report["readiness"]["keyword_retrieval"]["status"] == "implemented"
    assert report["readiness"]["local_vector_retrieval_status"]["status"] == "implemented"
    assert report["readiness"]["hybrid_keyword_vector_retrieval_status"]["status"] == "implemented"
    assert report["readiness"]["metadata_filtering"]["status"] == "implemented_local"
    assert report["readiness"]["stale_index_detection"]["status"] == "implemented_local"
    assert report["readiness"]["vector_db_adapter_status"]["classification"] == "offline_adapter_contracts_implemented"
    assert set(report["readiness"]["vector_db_adapter_status"]["implemented_vector_dbs"]) == {"Milvus", "Pinecone", "Qdrant", "Chroma"}
    assert "external vector database live service readiness" in report["must_not_claim"]


def test_final_gate_no_longer_blocks_on_local_rag_vector_index_readiness(tmp_path):
    output, result = run_audit(
        tmp_path,
        core_validation={"status": "pass", "focused": "pass", "full": "pass"},
        ui_validation={"status": "pass", "flutter": "pass"},
        ci_status={"status": "pass", "run": "local-test"},
    )

    gate = load_json(output, "final_v4_rc_gate_report.json")
    assert result["ready_for_v4_rc"] is True
    assert gate["ready_for_v4_rc"] is True
    assert not any(item["id"] == "rag_vector_index_industrial_readiness_unproven" for item in gate["p0_blockers"])
    assert gate["rag_vector_index_readiness"]["status"] == "pass"
    assert not any(item["id"] == "ui_validation_needs_review" for item in gate["p1_blockers"])
