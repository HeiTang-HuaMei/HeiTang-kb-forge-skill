from tests.v4_2_baseline_evidence import load_baseline_report



def _load(name: str) -> dict:
    return load_baseline_report(name)


def test_real_input_large_file_and_parser_reports_are_meaningful():
    perf = _load("real_input_large_file_performance_report.json")
    pdf = _load("real_input_pdf_parser_report.json")
    ocr = _load("real_input_ocr_report.json")

    assert perf["input_total_size_bytes"] > 0
    assert perf["package_chunk_count"] > 0
    assert perf["command_timing_summary"]["command_count"] >= 1
    assert pdf["pdf_input_count"] >= 1
    assert pdf["raw_pdf_sent_to_llm"] is False
    assert ocr["full_scanned_pdf_ocr_verified"] is False
    assert ocr["tests_require_real_llm_api_network"] is False
