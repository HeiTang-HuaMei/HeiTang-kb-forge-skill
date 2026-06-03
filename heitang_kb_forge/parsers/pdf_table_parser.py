from pathlib import Path

from heitang_kb_forge.parsers.table_parser import _format_table_rows

PDF_TABLE_DEPENDENCY_WARNING = 'PDF table extraction dependencies are not installed. Install with: pip install -e ".[pdf-table]"'


def extract_pdf_tables(path: Path) -> tuple[str, list[str]]:
    try:
        import pdfplumber
    except ImportError:
        return "", [PDF_TABLE_DEPENDENCY_WARNING]

    warnings: list[str] = []
    paragraphs: list[str] = []
    try:
        with pdfplumber.open(path) as pdf:
            for page_index, page in enumerate(pdf.pages, start=1):
                try:
                    tables = page.extract_tables() or []
                except Exception as exc:
                    warnings.append(f"PDF table extraction failed on page {page_index}: {exc}")
                    continue
                for table_index, table in enumerate(tables, start=1):
                    rows = _format_table_rows(table)
                    for row in rows:
                        paragraphs.append(f"Page {page_index}. Table {table_index}. {row}")
    except Exception as exc:
        return "", [f"PDF table extraction failed for {path}: {exc}"]

    return "\n\n".join(paragraphs), warnings
