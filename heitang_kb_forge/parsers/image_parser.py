from pathlib import Path

from heitang_kb_forge.parsers.ocr_table import extract_image_table_text


OCR_DEPENDENCY_ERROR = 'OCR dependencies are not installed. Install with: pip install -e ".[ocr]"'


def parse_image(path: Path) -> str:
    try:
        from PIL import Image
        import pytesseract
    except ImportError as exc:
        raise RuntimeError(OCR_DEPENDENCY_ERROR) from exc

    try:
        with Image.open(path) as image:
            table_text, table_warnings = extract_image_table_text(image)
            text = (pytesseract.image_to_string(image) or "").strip()
            parts = []
            if table_text:
                parts.append(table_text)
            if text:
                parts.append(text)
            return "\n\n".join(parts)
    except Exception as exc:
        raise RuntimeError(f"OCR failed for {path}: {exc}") from exc
