import sys
import types
from pathlib import Path

from heitang_kb_forge.parsers.pdf_table_parser import extract_pdf_tables
from heitang_kb_forge.parsers.pdf_parser import parse_pdf


def test_pdf_table_parser_formats_tables(monkeypatch, tmp_path):
    pdf_path = tmp_path / "table.pdf"
    pdf_path.write_bytes(b"%PDF-1.4\n")

    class FakePage:
        def extract_tables(self):
            return [[["Name", "Price"], ["Book", "59"]]]

    class FakePDF:
        pages = [FakePage()]

        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc, tb):
            return False

    fake_pdfplumber = types.SimpleNamespace(open=lambda path: FakePDF())
    monkeypatch.setitem(sys.modules, "pdfplumber", fake_pdfplumber)

    text, warnings = extract_pdf_tables(pdf_path)

    assert warnings == []
    assert "Page 1. Table 1. Row 2. Name: Book. Price: 59." in text


def test_pdf_table_dependency_missing_does_not_fail(monkeypatch, tmp_path):
    pdf_path = tmp_path / "table.pdf"
    pdf_path.write_bytes(b"%PDF-1.4\n")
    monkeypatch.setitem(sys.modules, "pdfplumber", None)

    text, warnings = extract_pdf_tables(pdf_path)

    assert text == ""
    assert warnings


def test_pdf_parser_keeps_text_when_table_extraction_fails(monkeypatch, tmp_path):
    pdf_path = tmp_path / "lesson.pdf"
    pdf_path.write_bytes(b"%PDF-1.4\n")
    monkeypatch.setattr("heitang_kb_forge.parsers.pdf_parser._extract_text_pdf", lambda path: "This is enough text to avoid OCR fallback.")
    monkeypatch.setattr("heitang_kb_forge.parsers.pdf_parser.extract_pdf_tables", lambda path: ("", ["table failed"]))

    text = parse_pdf(pdf_path)

    assert "This is enough text" in text
    assert "[Warning] table failed" in text
