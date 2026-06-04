from heitang_kb_forge.ocr.report import make_resume_report


def test_ocr_resume_report_lists_failed_pages():
    report = make_resume_report(
        [
            {
                "source_path": "input/sample.pdf",
                "page_index": 1,
                "error": "timeout",
            }
        ],
        cache_hits=3,
    )

    assert "# OCR Resume Report" in report
    assert "Cache hits: 3" in report
    assert "sample.pdf page 2: timeout" in report
