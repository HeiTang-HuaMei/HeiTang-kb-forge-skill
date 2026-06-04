from __future__ import annotations

from pathlib import Path
from typing import Any


LOW_TEXT_THRESHOLD = 20


def preflight_pdf(path: Path, *, skip_empty_pages: bool = True, skip_low_text_pages: bool = False) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    pages: list[dict[str, Any]] = []
    try:
        from pypdf import PdfReader

        reader = PdfReader(path)
        for index, page in enumerate(reader.pages):
            text = page.extract_text() or ""
            text_length = len(" ".join(text.split()))
            is_empty = text_length == 0
            needs_ocr = text_length < LOW_TEXT_THRESHOLD
            if text_length > 0 and skip_low_text_pages:
                reason = "low_text_skipped"
                needs_ocr = False
            else:
                reason = "text_layer_sufficient" if not needs_ocr else "text_layer_empty_or_too_short"
            pages.append(
                {
                    "page_index": index,
                    "has_text_layer": text_length > 0,
                    "text_length": text_length,
                    "is_empty_candidate": is_empty,
                    "needs_ocr": needs_ocr,
                    "reason": reason,
                }
            )
    except Exception:
        pages = []
    report = {
        "pdf_preflight_version": "1.6.2",
        "source_path": str(path).replace("\\", "/"),
        "total_pages": len(pages),
        "ocr_candidate_pages": sum(1 for page in pages if page["needs_ocr"]),
        "skipped_empty_pages": 0 if skip_empty_pages else 0,
    }
    return report, pages
