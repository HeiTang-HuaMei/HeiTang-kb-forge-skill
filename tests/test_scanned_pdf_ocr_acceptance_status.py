from tests.v4_2_baseline_evidence import load_baseline_report



def test_scanned_pdf_ocr_status_is_limited_not_false_pass():
    report = load_baseline_report("real_input_ocr_report.json")
    parser = load_baseline_report("real_input_pdf_parser_report.json")
    full = load_baseline_report("full_ocr_acceptance_report.json")

    assert report["status"] == "needs_review"
    assert report["full_scanned_pdf_ocr_verified"] is False
    assert report["max_ocr_pages_used_in_build"] == 8
    assert parser["raw_pdf_sent_to_llm"] is False
    assert full["status"] == "pass"
    assert full["total_pages"] == 120
    assert full["completed_pages"] == 120
