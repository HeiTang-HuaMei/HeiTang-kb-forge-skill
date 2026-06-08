import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_full_ocr_page_coverage_records_attempted_and_completed_pages():
    report = json.loads((PROOF / "full_ocr_page_coverage_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "pass"
    assert report["total_pages"] == 120
    assert report["attempted_pages"] == 120
    assert report["completed_pages"] == 120
    assert report["all_candidate_pages_attempted"] is True
