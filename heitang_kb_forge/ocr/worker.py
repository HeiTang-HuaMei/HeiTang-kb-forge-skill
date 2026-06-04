from __future__ import annotations

import time
from dataclasses import dataclass
from typing import Any

from heitang_kb_forge.parsers.ocr_table import extract_image_table_text


@dataclass
class OCRPageResult:
    page_index: int
    text: str
    duration_ms: int
    warning: str | None = None
    error: str | None = None


def ocr_pil_image(pil_image: Any, *, page_index: int, ocr_lang: str, timeout_per_page: int) -> OCRPageResult:
    started = time.monotonic()
    try:
        import pytesseract

        table_text, _table_warnings = extract_image_table_text(pil_image, page_label=f"Page {page_index + 1}")
        try:
            text = pytesseract.image_to_string(pil_image, lang=ocr_lang, timeout=timeout_per_page).strip()
        except TypeError:
            text = pytesseract.image_to_string(pil_image).strip()
        parts = []
        if table_text:
            parts.append(table_text)
        if text:
            parts.append(f"[Page {page_index + 1}]\n{text}")
        return OCRPageResult(page_index=page_index, text="\n\n".join(parts), duration_ms=_duration(started))
    except Exception as exc:
        message = str(exc)
        if "chi_sim" in ocr_lang and "chi_sim" in message:
            message = "Tesseract language chi_sim is not available. Install chi_sim.traineddata into Tesseract tessdata directory, or run with --ocr-lang eng."
        elif "tesseract" in message.lower():
            message = f"Tesseract OCR failed or is not in PATH: {message}"
        return OCRPageResult(page_index=page_index, text="", duration_ms=_duration(started), error=message)


def safe_worker_count(value: int) -> int:
    if value <= 0:
        return 1
    return max(1, value)


def _duration(started: float) -> int:
    return max(0, int((time.monotonic() - started) * 1000))
