from pathlib import Path


OCR_DEPENDENCY_ERROR = 'OCR dependencies are not installed. Install with: pip install -e ".[ocr]"'


def parse_image(path: Path) -> str:
    try:
        from PIL import Image
        import pytesseract
    except ImportError as exc:
        raise RuntimeError(OCR_DEPENDENCY_ERROR) from exc

    try:
        with Image.open(path) as image:
            return (pytesseract.image_to_string(image) or "").strip()
    except Exception as exc:
        raise RuntimeError(f"OCR failed for {path}: {exc}") from exc
