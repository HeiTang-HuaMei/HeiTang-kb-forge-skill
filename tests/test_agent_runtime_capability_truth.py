from tests.v4_2_baseline_evidence import load_baseline_report



def test_agent_runtime_truth_separates_local_runtime_from_full_tool_loop():
    report = load_baseline_report("agent_runtime_capability_truth_report.json")

    assert report["status"] == "needs_review"
    assert report["tests_require_real_llm_api_network"] is False
    assert report["capabilities"]["kb_bound_agent"] == "fixed_and_tested"
    assert report["capabilities"]["kb_boundary"] == "fixed_and_tested"
    assert report["capabilities"]["full_tool_calling_agent_loop"] == "not_implemented"
    assert "full autonomous Agent Runtime" in report["must_not_claim"]
