from tests.v4_2_baseline_evidence import load_baseline_report



def test_full_ocr_acceptance_report_proves_all_pages_without_upload_or_llm():
    report = load_baseline_report("full_ocr_acceptance_report.json")

    assert report["status"] == "pass"
    assert report["all_ocr_candidate_pages_attempted"] is True
    assert report["total_pages"] == 120
    assert report["completed_pages"] == 120
    assert report["failed_pages"] == 0
    assert report["extracted_character_count"] > 0
    assert report["no_hidden_upload"] is True
    assert report["llm_required"] is False
    assert report["raw_ocr_text_committed"] is False
