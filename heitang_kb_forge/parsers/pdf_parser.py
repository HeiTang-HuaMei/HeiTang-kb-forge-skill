from pathlib import Path

from heitang_kb_forge.parsers.ocr_table import extract_image_table_text
from heitang_kb_forge.parsers.pdf_table_parser import PDF_TABLE_DEPENDENCY_WARNING, extract_pdf_tables

PDF_OCR_DEPENDENCY_ERROR = 'PDF OCR dependencies are not installed. Install with: pip install -e ".[ocr]"'
TEXT_OCR_THRESHOLD = 20


def parse_pdf(path: Path) -> str:
    text = _extract_text_pdf(path)
    if not _needs_ocr_fallback(text):
        table_text, warnings = extract_pdf_tables(path)
        parts = [text]
        if table_text:
            parts.append(table_text)
        parts.extend(f"[Warning] {warning}" for warning in warnings if warning != PDF_TABLE_DEPENDENCY_WARNING)
        return "\n\n".join(part for part in parts if part)
    return _ocr_pdf_pages(path)


def _extract_text_pdf(path: Path) -> str:
    try:
        from pypdf import PdfReader

        reader = PdfReader(path)
        pages = [page.extract_text() or "" for page in reader.pages]
    except Exception:
        return ""

    return "\n\n".join(page.strip() for page in pages if page.strip())


def _needs_ocr_fallback(text: str) -> bool:
    normalized = " ".join(text.split())
    return len(normalized) < TEXT_OCR_THRESHOLD


def _ocr_pdf_pages(path: Path) -> str:
    try:
        import pypdfium2 as pdfium
        import pytesseract
    except ImportError as exc:
        raise RuntimeError(PDF_OCR_DEPENDENCY_ERROR) from exc

    try:
        document = pdfium.PdfDocument(path)
        page_texts = []
        for page_index in range(len(document)):
            page = document[page_index]
            pil_image = page.render(scale=2).to_pil()
            table_text, table_warnings = extract_image_table_text(pil_image, page_label=f"Page {page_index + 1}")
            text = pytesseract.image_to_string(pil_image).strip()
            parts = []
            if table_text:
                parts.append(table_text)
            if text:
                parts.append(f"[Page {page_index + 1}]\n{text}")
            if parts:
                page_texts.append("\n\n".join(parts))
        return "\n\n".join(page_texts)
    except Exception as exc:
        raise RuntimeError(f"PDF OCR failed for {path}: {exc}") from exc
