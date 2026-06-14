from tests.v4_2_baseline_evidence import load_baseline_report



def test_scanned_pdf_text_quality_report_is_non_empty_and_reviewed():
    report = load_baseline_report("scanned_pdf_text_quality_report.json")

    assert report["status"] == "pass"
    assert report["extracted_character_count"] > 0
    assert report["average_chars_per_completed_page"] > 0
    assert report["raw_text_committed"] is False
