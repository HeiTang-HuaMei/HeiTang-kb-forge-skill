from pathlib import Path


def parse_pdf(path: Path) -> str:
    try:
        from pypdf import PdfReader

        reader = PdfReader(path)
        pages = [page.extract_text() or "" for page in reader.pages]
    except Exception:
        return ""

    return "\n\n".join(page.strip() for page in pages if page.strip())
