from tests.v4_2_baseline_evidence import load_baseline_report



def test_optional_llm_process_environment_isolation_is_not_user_blame():
    report = load_baseline_report("optional_llm_provider_acceptance_report.json")

    assert report["status"] == "needs_review"
    assert "process environment isolation" in report["skip_reason"]
    assert "user did not configure" not in report["skip_reason"].lower()
    assert report["api_key_value_written"] is False
    assert report["tests_require_real_llm_api_network"] is False
