from tests.v4_2_baseline_evidence import load_baseline_report



def test_optional_llm_fallback_keeps_core_usable_without_llm():
    report = load_baseline_report("optional_llm_fallback_report.json")

    assert report["status"] == "pass"
    assert report["core_workflow_usable_without_llm"] is True
    assert report["tests_require_real_llm_api_network"] is False
