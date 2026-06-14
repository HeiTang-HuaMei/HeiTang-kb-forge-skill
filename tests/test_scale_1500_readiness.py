from tests.v4_2_baseline_evidence import load_baseline_report



def test_scale_1500_readiness_is_synthetic_not_production_claim():
    report = load_baseline_report("scale_1500_readiness_report.json")

    assert report["status"] == "needs_review"
    assert report["tests_require_real_llm_api_network"] is False
    assert report["readiness"]["simulate_1500_books"] == "synthetic_only"
    assert report["readiness"]["simulate_1500_agents"] == "not_proven"
    assert "real 1500-book production workload proven" in report["must_not_claim"]
