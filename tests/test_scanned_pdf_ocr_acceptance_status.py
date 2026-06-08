import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_scanned_pdf_ocr_status_is_limited_not_false_pass():
    report = json.loads((PROOF / "real_input_ocr_report.json").read_text(encoding="utf-8"))
    parser = json.loads((PROOF / "real_input_pdf_parser_report.json").read_text(encoding="utf-8"))
    full = json.loads((PROOF / "full_ocr_acceptance_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "needs_review"
    assert report["full_scanned_pdf_ocr_verified"] is False
    assert report["max_ocr_pages_used_in_build"] == 8
    assert parser["raw_pdf_sent_to_llm"] is False
    assert full["status"] == "pass"
    assert full["total_pages"] == 120
    assert full["completed_pages"] == 120
