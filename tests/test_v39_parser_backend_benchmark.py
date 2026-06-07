from pathlib import Path

from heitang_kb_forge.document_parsing.parser_benchmark import build_parser_backend_benchmark, select_parser_backend


def test_parser_backend_selection_policy_for_document_types(tmp_path):
    assert select_parser_backend(Path("plain.pdf"))["selected_backend"] == "lightweight_local_pdf_text_scan"
    assert select_parser_backend(Path("scan.pdf"))["selected_backend"] == "ocr_required"
    assert select_parser_backend(Path("complex_table.pdf"))["selected_backend"] == "complex_parser_required"
    assert select_parser_backend(Path("unknown.bin"))["review_required"] is True

    report = build_parser_backend_benchmark([tmp_path / "plain.pdf", tmp_path / "scan.pdf"])
    assert len(report["benchmarks"]) == 2
    assert report["tests_require_real_llm_api_network"] is False
