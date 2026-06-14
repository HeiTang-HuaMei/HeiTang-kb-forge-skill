from tests.v4_2_baseline_evidence import load_baseline_report



def test_optional_llm_config_redaction_never_records_values():
    report = load_baseline_report("optional_llm_config_redaction_report.json")

    assert report["status"] == "pass"
    assert "HEITANG_LLM_API_KEY" in report["env_names_recorded"]
    assert report["env_values_recorded"] is False
    assert report["api_key_value_recorded"] is False
    assert report["tests_require_real_llm_api_network"] is False
