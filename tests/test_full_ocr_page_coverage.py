from tests.v4_2_baseline_evidence import load_baseline_report



def test_full_ocr_page_coverage_records_attempted_and_completed_pages():
    report = load_baseline_report("full_ocr_page_coverage_report.json")

    assert report["status"] == "pass"
    assert report["total_pages"] == 120
    assert report["attempted_pages"] == 120
    assert report["completed_pages"] == 120
    assert report["all_candidate_pages_attempted"] is True
