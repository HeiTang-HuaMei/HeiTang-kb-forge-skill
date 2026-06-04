from heitang_kb_forge.ocr.report import make_performance_report


def test_large_file_performance_report_summarizes_ocr_records():
    report = make_performance_report(
        [
            {
                "source_type": "pdf",
                "source_path": "input/large.pdf",
                "total_pages": 10,
                "ocr_pages_requested": 3,
                "ocr_pages_completed": 2,
                "ocr_pages_skipped": 7,
                "ocr_cache_hits": 1,
                "ocr_cache_writes": 2,
                "ocr_failed_pages": 1,
                "page_durations": [{"source_path": "input/large.pdf", "page_index": 0, "duration_ms": 50}],
            }
        ]
    )

    assert "# Large File Performance Report" in report
    assert "Total pages: 10" in report
    assert "OCR cache hits: 1" in report
    assert "large.pdf page 1: 50 ms" in report
