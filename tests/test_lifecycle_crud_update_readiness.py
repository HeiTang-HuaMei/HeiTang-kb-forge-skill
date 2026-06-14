from tests.v4_2_baseline_evidence import load_baseline_report



def test_lifecycle_crud_update_readiness_keeps_destructive_actions_off_by_default():
    report = load_baseline_report("lifecycle_crud_update_readiness_report.json")

    assert report["status"] == "needs_review"
    assert report["tests_require_real_llm_api_network"] is False
    assert report["destructive_cleanup_default"] is False
    assert report["readiness"]["create_kb"] == "proven"
    assert report["readiness"]["update_kb"] == "partial"
    assert report["readiness"]["cleanup_retention"] == "implemented_recommendation_only"
