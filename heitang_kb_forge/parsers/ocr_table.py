from __future__ import annotations

from collections import defaultdict
from typing import Any


OCR_TABLE_WARNING = "[Warning] OCR table extraction fell back to plain OCR."


def extract_image_table_text(image: Any, page_label: str | None = None) -> tuple[str, list[str]]:
    try:
        import pytesseract
        from pytesseract import Output
    except ImportError:
        return "", [OCR_TABLE_WARNING]

    try:
        data = pytesseract.image_to_data(image, output_type=Output.DICT)
    except Exception:
        return "", [OCR_TABLE_WARNING]

    words = _words_from_data(data)
    if len(words) < 2:
        return "", [OCR_TABLE_WARNING]

    rows = _group_words_into_rows(words)
    formatted = _format_ocr_rows(rows, page_label)
    if not formatted:
        return "", [OCR_TABLE_WARNING]
    return "\n".join(formatted), []


def _words_from_data(data: dict) -> list[dict]:
    words: list[dict] = []
    for index, text in enumerate(data.get("text", [])):
        value = str(text).strip()
        if not value:
            continue
        try:
            confidence = float(data.get("conf", ["0"])[index])
        except (TypeError, ValueError):
            confidence = 0
        if confidence < 0:
            continue
        words.append(
            {
                "text": value,
                "left": int(data.get("left", [0])[index]),
                "top": int(data.get("top", [0])[index]),
                "width": int(data.get("width", [0])[index]),
            }
        )
    return words


def _group_words_into_rows(words: list[dict]) -> list[list[dict]]:
    buckets: dict[int, list[dict]] = defaultdict(list)
    for word in words:
        bucket = round(word["top"] / 12)
        buckets[bucket].append(word)
    return [sorted(row, key=lambda item: item["left"]) for _, row in sorted(buckets.items()) if row]


def _format_ocr_rows(rows: list[list[dict]], page_label: str | None) -> list[str]:
    lines: list[str] = []
    prefix = f"{page_label}. OCR Table 1." if page_label else "Image Table 1."
    for row_index, row in enumerate(rows, start=1):
        cells = _split_row_cells(row)
        if not cells:
            continue
        fields = [f"Column {chr(65 + index)}: {cell}" for index, cell in enumerate(cells)]
        lines.append(f"{prefix} Row {row_index}. {'. '.join(fields)}.")
    return lines


def _split_row_cells(row: list[dict]) -> list[str]:
    if not row:
        return []
    cells: list[list[str]] = [[row[0]["text"]]]
    previous = row[0]
    for word in row[1:]:
        gap = word["left"] - (previous["left"] + previous["width"])
        if gap > 24:
            cells.append([word["text"]])
        else:
            cells[-1].append(word["text"])
        previous = word
    return [" ".join(cell).strip() for cell in cells if " ".join(cell).strip()]
