from heitang_kb_forge.document_parsing.token_reduction import estimate_pdf_token_reduction


def test_pdf_token_reduction_estimate_generated(tmp_path):
    pdf = tmp_path / "sample.pdf"
    md = tmp_path / "sample.md"
    pdf.write_bytes(b"x" * 1200)
    md.write_text("# Sample\n\nshort markdown", encoding="utf-8")

    report = estimate_pdf_token_reduction(pdf, md, parser_confidence=0.8)

    assert report["raw_pdf_size_bytes"] == 1200
    assert report["estimated_raw_llm_tokens"] > report["estimated_markdown_tokens"]
    assert report["estimated_token_savings_ratio"] > 0
    assert report["review_required"] is False
