from __future__ import annotations

from pathlib import Path


def estimate_pdf_token_reduction(source: Path, markdown_path: Path | None = None, parser_confidence: float = 0.5) -> dict:
    raw_size = source.stat().st_size if source.exists() else 0
    markdown_chars = markdown_path.read_text(encoding="utf-8").__len__() if markdown_path and markdown_path.exists() else 0
    extracted_text_chars = markdown_chars
    estimated_raw_tokens = max(1, raw_size // 3)
    estimated_markdown_tokens = max(1, markdown_chars // 4) if markdown_chars else 0
    savings = 0.0
    if estimated_raw_tokens:
        savings = max(0.0, min(1.0, 1 - (estimated_markdown_tokens / estimated_raw_tokens)))
    return {
        "pdf_token_reduction_report_version": "3.9.0-alpha.1",
        "source_path": source.as_posix(),
        "raw_pdf_size_bytes": raw_size,
        "extracted_text_chars": extracted_text_chars,
        "markdown_chars": markdown_chars,
        "estimated_raw_llm_tokens": estimated_raw_tokens,
        "estimated_markdown_tokens": estimated_markdown_tokens,
        "estimated_token_savings_ratio": round(savings, 4),
        "parser_confidence": parser_confidence,
        "review_required": parser_confidence < 0.6,
        "raw_pdf_sent_to_llm": False,
        "tests_require_real_llm_api_network": False,
    }
