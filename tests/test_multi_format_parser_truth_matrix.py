import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_multi_format_parser_truth_matrix_does_not_overclaim_full_ocr():
    report = json.loads((PROOF / "multi_format_parser_truth_matrix.json").read_text(encoding="utf-8"))

    assert report["status"] == "needs_review"
    assert report["tests_require_real_llm_api_network"] is False
    assert report["formats"]["large_pdf"]["status"] == "proven"
    assert report["formats"]["docx"]["status"] == "proven"
    assert report["formats"]["scanned_pdf_full_ocr"]["status"] == "needs_review"
    assert "full scanned PDF OCR proven" in report["must_not_claim"]
