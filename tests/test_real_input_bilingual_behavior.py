from tests.v4_2_baseline_evidence import load_baseline_report



def test_real_input_bilingual_behavior_report_tracks_language_limits():
    report = load_baseline_report("real_input_bilingual_behavior_report.json")

    assert report["package_preserves_chinese_and_english_sources"] is True
    assert report["language_probes"]["zh"]["status"] == "answered"
    assert report["language_probes"]["en"]["status"] == "answered"
    assert report["language_probes"]["zh"]["answer_content_redacted"] is True
    assert report["ui_language_setting_priority"] == "not_exposed_in_core_cli_needs_review"
    assert report["tests_require_real_llm_api_network"] is False
