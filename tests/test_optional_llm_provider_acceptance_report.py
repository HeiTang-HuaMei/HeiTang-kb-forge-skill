from tests.v4_2_baseline_evidence import load_baseline_report



def test_optional_llm_provider_report_redacts_and_explains_visibility():
    report = load_baseline_report("optional_llm_provider_acceptance_report.json")

    assert "HEITANG_LLM_API_KEY" in report["required_env_visibility"]
    assert report["api_key_value_written"] is False
    assert report["api_key_value_committed"] is False
    assert report["core_workflow_requires_llm"] is False
    assert report["tests_require_real_llm_api_network"] is False
    if report["status"] == "needs_review":
        assert "process environment isolation" in report["skip_reason"]
