from heitang_kb_forge.retrieval.diagnostics import diagnose_retrieval_failure


def test_retrieval_failure_report_generated_for_no_results():
    report = diagnose_retrieval_failure(query="unknown", candidates=[], ranked=[], evidence_selection={"selected": [], "selected_count": 0, "source_diversity_count": 0, "insufficient_evidence": True, "refusal_recommendation": {"missing_evidence": ["unknown"]}}, purpose="validation")

    assert "no_results" in report["issues"]
    assert "validation_source_unavailable" in report["issues"]
    assert report["should_refuse"] is True
    assert report["tests_require_real_llm_api_network"] is False
