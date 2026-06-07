import json
from pathlib import Path

from tests.final_audit_helpers import load_json, run_audit


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_rag_vector_index_report_classifies_export_only_vector_status():
    report = json.loads((PROOF / "rag_vector_index_readiness_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "blocked"
    assert report["blocker_id"] == "rag_vector_index_industrial_readiness_unproven"
    assert report["severity"] == "P0"
    assert report["tests_require_real_llm_api_network"] is False
    assert report["readiness"]["keyword_retrieval"]["status"] == "implemented"
    assert report["readiness"]["vector_db_adapter_status"]["classification"] == "export_only_adapter_future"
    assert report["readiness"]["vector_db_adapter_status"]["implemented_vector_dbs"] == []
    assert report["readiness"]["hybrid_keyword_vector_retrieval_status"]["status"] in {"missing", "needs_review"}
    assert "production hybrid keyword/vector retrieval" in report["must_not_claim"]


def test_final_gate_blocks_on_rag_vector_index_industrial_readiness(tmp_path):
    output, result = run_audit(
        tmp_path,
        core_validation={"status": "pass", "focused": "pass", "full": "pass"},
        ui_validation={"status": "pass", "flutter": "pass"},
        ci_status={"status": "pass", "run": "local-test"},
    )

    gate = load_json(output, "final_v4_rc_gate_report.json")
    assert result["ready_for_v4_rc"] is False
    assert gate["ready_for_v4_rc"] is False
    assert any(item["id"] == "rag_vector_index_industrial_readiness_unproven" for item in gate["p0_blockers"])
    assert gate["rag_vector_index_readiness"]["blocker_id"] == "rag_vector_index_industrial_readiness_unproven"
