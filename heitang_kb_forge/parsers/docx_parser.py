from pathlib import Path


def parse_docx(path: Path) -> str:
    try:
        from docx import Document

        document = Document(path)
    except Exception:
        return ""

    paragraphs = [paragraph.text.strip() for paragraph in document.paragraphs if paragraph.text.strip()]
    return "\n\n".join(paragraphs)
