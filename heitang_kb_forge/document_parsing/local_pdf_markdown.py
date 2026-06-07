from __future__ import annotations

from pathlib import Path


def preprocess_pdf_to_markdown(source: Path, output: Path | None = None) -> dict:
    output = output or source.with_suffix(".md")
    output.parent.mkdir(parents=True, exist_ok=True)
    if source.suffix.lower() != ".pdf":
        status = "unsupported"
        markdown = ""
        confidence = 0.0
        review_required = True
        reason = "source_is_not_pdf"
    else:
        raw = source.read_bytes() if source.exists() else b""
        text = _extract_ascii_pdf_text(raw)
        markdown = text if text else f"# {source.stem}\n\n[PDF text extraction unavailable; review required.]\n"
        status = "partial" if not text else "pass"
        confidence = 0.35 if not text else 0.7
        review_required = not bool(text)
        reason = "lightweight_local_pdf_text_scan" if text else "pdf_text_not_extractable_without_optional_backend"
        output.write_text(markdown, encoding="utf-8")
    return {
        "local_pdf_markdown_report_version": "3.9.0-alpha.1",
        "source_path": source.as_posix(),
        "output_path": output.as_posix(),
        "status": status,
        "parser_backend": "lightweight_local_pdf_text_scan",
        "parser_confidence": confidence,
        "review_required": review_required,
        "reason": reason,
        "no_cloud_upload": True,
        "raw_pdf_sent_to_llm": False,
        "tests_require_real_llm_api_network": False,
    }


def _extract_ascii_pdf_text(raw: bytes) -> str:
    # This intentionally stays dependency-light; robust parsing remains an adapter track.
    decoded = raw.decode("latin-1", errors="ignore")
    chunks = []
    current = []
    for char in decoded:
        if char.isprintable() and char not in "{}[]<>":
            current.append(char)
        elif current:
            value = "".join(current).strip()
            if len(value) > 4 and any(ch.isalpha() for ch in value):
                chunks.append(value)
            current = []
    if current:
        value = "".join(current).strip()
        if len(value) > 4 and any(ch.isalpha() for ch in value):
            chunks.append(value)
    text = "\n".join(chunks[:200]).strip()
    return f"# Extracted PDF Markdown\n\n{text}\n" if text else ""
