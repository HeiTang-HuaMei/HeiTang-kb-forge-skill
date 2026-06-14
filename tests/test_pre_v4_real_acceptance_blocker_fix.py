from tests.v4_2_baseline_evidence import load_baseline_report



def test_pre_v4_blocker_fix_report_is_honest_and_parseable():
    report = load_baseline_report("pre_v4_real_acceptance_blocker_fix_report.json")

    assert report["ready_for_v4_rc"] is False
    assert report["p0_remaining_count"] == 0
    assert report["raw_inputs_committed"] is False
    assert report["full_extracted_chunks_committed"] is False
    assert report["api_keys_committed"] is False
    assert report["tests_require_real_llm_api_network"] is False
    items = {item["id"]: item for item in report["remaining_items"]}
    assert items["final_pre_v4_gate_still_blocked"]["status"] == "fixed"
    assert items["rag_vector_index_industrial_readiness_unproven"]["status"] == "fixed"


def test_current_failure_report_no_longer_counts_final_gate_validation_as_p0():
    report = load_baseline_report("real_input_failure_report.json")
    blocker_ids = {item["id"] for item in report["blockers"]}

    assert "final_pre_v4_gate_still_blocked" not in blocker_ids
    assert "rag_vector_index_industrial_readiness_unproven" not in blocker_ids
