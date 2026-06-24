from heitang_kb_forge.reliability import run_reliability_eval


def test_reliability_eval_suite_passes_when_prior_gate_contracts_are_covered():
    report = run_reliability_eval(
        {
            "evidence_graph_status": "evidence_graph_basic_completed_needs_owner_review",
            "evidence_graph_entity_count": 3,
            "gap_status": "gap_analysis_completed_needs_owner_review",
            "gap_count": 0,
            "citation_status": "citation_verification_completed_needs_owner_review",
            "citation_coverage": 1.0,
        }
    )

    assert report.status == "pass"
    assert report.available_for_next_gate is True
    assert report.overall_score == 100


def test_reliability_eval_suite_blocks_low_citation_coverage():
    report = run_reliability_eval(
        {
            "evidence_graph_status": "evidence_graph_basic_completed_needs_owner_review",
            "evidence_graph_entity_count": 3,
            "gap_status": "gap_analysis_completed_needs_owner_review",
            "gap_count": 0,
            "citation_status": "citation_verification_completed_needs_owner_review",
            "citation_coverage": 0.25,
        }
    )

    assert report.status == "fail"
    assert report.available_for_next_gate is False
    assert report.blockers == ["citation_verification"]
