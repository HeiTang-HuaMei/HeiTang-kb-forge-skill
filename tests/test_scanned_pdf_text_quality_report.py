import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_scanned_pdf_text_quality_report_is_non_empty_and_reviewed():
    report = json.loads((PROOF / "scanned_pdf_text_quality_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "pass"
    assert report["extracted_character_count"] > 0
    assert report["average_chars_per_completed_page"] > 0
    assert report["raw_text_committed"] is False
