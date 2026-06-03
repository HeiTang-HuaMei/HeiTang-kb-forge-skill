import json
import builtins
import sys
import types

import pytest
from typer.testing import CliRunner

from heitang_kb_forge.cli import app
import heitang_kb_forge.parsers.pdf_parser as pdf_parser
from heitang_kb_forge.parsers.pdf_parser import PDF_OCR_DEPENDENCY_ERROR, parse_pdf


def test_pdf_parser_extracts_text_from_text_based_pdf(tmp_path):
    sample_pdf = tmp_path / "sample_text.pdf"
    _write_minimal_text_pdf(sample_pdf)

    text = parse_pdf(sample_pdf)

    assert isinstance(text, str)
    assert "KB Forge PDF Fixture" in text
    assert "text-based PDF parsing" in text


def test_build_processes_text_based_pdf(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    _write_minimal_text_pdf(input_dir / "sample_text.pdf")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--domain",
            "education",
            "--mode",
            "teaching",
        ],
    )

    assert result.exit_code == 0, result.output
    assert (output_dir / "chunks.jsonl").exists()
    assert (output_dir / "manifest.json").exists()
    assert (output_dir / "ingest_report.md").exists()

    chunk_lines = (output_dir / "chunks.jsonl").read_text(encoding="utf-8").splitlines()
    assert len(chunk_lines) >= 1
    first_chunk = json.loads(chunk_lines[0])
    assert "KB Forge PDF Fixture" in first_chunk["text"]
    assert "text-based PDF parsing" in first_chunk["text"]


def test_pdf_parser_does_not_use_ocr_when_text_is_sufficient(monkeypatch, tmp_path):
    sample_pdf = tmp_path / "sample_text.pdf"
    sample_pdf.write_bytes(b"%PDF-1.4")
    monkeypatch.setattr(pdf_parser, "_extract_text_pdf", lambda path: "Text-based PDF content long enough")

    def fail_ocr(path):
        raise AssertionError("OCR fallback should not run")

    monkeypatch.setattr(pdf_parser, "_ocr_pdf_pages", fail_ocr)

    assert parse_pdf(sample_pdf) == "Text-based PDF content long enough"


def test_pdf_parser_uses_ocr_fallback_when_text_is_empty(monkeypatch, tmp_path):
    sample_pdf = tmp_path / "sample_scanned.pdf"
    sample_pdf.write_bytes(b"%PDF-1.4")
    monkeypatch.setattr(pdf_parser, "_extract_text_pdf", lambda path: "")
    monkeypatch.setattr(pdf_parser, "_ocr_pdf_pages", lambda path: "[Page 1]\nScanned PDF OCR Fixture")

    assert parse_pdf(sample_pdf) == "[Page 1]\nScanned PDF OCR Fixture"


def test_pdf_ocr_fallback_returns_page_marked_text(monkeypatch, tmp_path):
    sample_pdf = tmp_path / "sample_scanned.pdf"
    sample_pdf.write_bytes(b"%PDF-1.4")

    class FakeBitmap:
        def to_pil(self):
            return object()

    class FakePage:
        def render(self, scale):
            assert scale == 2
            return FakeBitmap()

    class FakeDocument:
        def __init__(self, path):
            self.path = path

        def __len__(self):
            return 1

        def __getitem__(self, index):
            assert index == 0
            return FakePage()

    fake_pdfium = types.SimpleNamespace(PdfDocument=FakeDocument)
    fake_tesseract = types.SimpleNamespace(image_to_string=lambda image: " Scanned PDF OCR Fixture ")
    monkeypatch.setitem(sys.modules, "pypdfium2", fake_pdfium)
    monkeypatch.setitem(sys.modules, "pytesseract", fake_tesseract)

    assert pdf_parser._ocr_pdf_pages(sample_pdf) == "[Page 1]\nScanned PDF OCR Fixture"


def test_pdf_ocr_fallback_reports_missing_dependencies(monkeypatch, tmp_path):
    sample_pdf = tmp_path / "sample_scanned.pdf"
    sample_pdf.write_bytes(b"%PDF-1.4")
    original_import = builtins.__import__

    def fake_import(name, *args, **kwargs):
        if name in {"pypdfium2", "pytesseract"}:
            raise ImportError(name)
        return original_import(name, *args, **kwargs)

    monkeypatch.setattr(builtins, "__import__", fake_import)

    with pytest.raises(RuntimeError) as exc_info:
        pdf_parser._ocr_pdf_pages(sample_pdf)
    assert str(exc_info.value) == PDF_OCR_DEPENDENCY_ERROR


def test_pdf_ocr_fallback_reports_ocr_failure(monkeypatch, tmp_path):
    sample_pdf = tmp_path / "sample_scanned.pdf"
    sample_pdf.write_bytes(b"%PDF-1.4")

    class FailingDocument:
        def __init__(self, path):
            raise ValueError("render failed")

    monkeypatch.setitem(sys.modules, "pypdfium2", types.SimpleNamespace(PdfDocument=FailingDocument))
    monkeypatch.setitem(sys.modules, "pytesseract", types.SimpleNamespace(image_to_string=lambda image: ""))

    with pytest.raises(RuntimeError, match="PDF OCR failed for"):
        pdf_parser._ocr_pdf_pages(sample_pdf)


def test_build_processes_mocked_scanned_pdf_ocr(monkeypatch, tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "scanned.pdf").write_bytes(b"%PDF-1.4")
    monkeypatch.setattr(pdf_parser, "_extract_text_pdf", lambda path: "")
    monkeypatch.setattr(pdf_parser, "_ocr_pdf_pages", lambda path: "[Page 1]\nScanned PDF OCR Fixture")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--domain",
            "education",
            "--mode",
            "teaching",
        ],
    )

    assert result.exit_code == 0, result.output
    assert (output_dir / "quality_report.json").exists()
    chunk_text = "\n".join(
        json.loads(line)["text"] for line in (output_dir / "chunks.jsonl").read_text(encoding="utf-8").splitlines()
    )
    assert "Scanned PDF OCR Fixture" in chunk_text


def _write_minimal_text_pdf(path):
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Length 103 >>\nstream\nBT\n/F1 18 Tf\n72 720 Td\n(KB Forge PDF Fixture) Tj\n0 -28 Td\n(text-based PDF parsing) Tj\nET\nendstream",
    ]
    content = b"%PDF-1.4\n"
    offsets = [0]
    for index, obj in enumerate(objects, start=1):
        offsets.append(len(content))
        content += f"{index} 0 obj\n".encode("ascii") + obj + b"\nendobj\n"
    xref_offset = len(content)
    content += f"xref\n0 {len(objects) + 1}\n".encode("ascii")
    content += b"0000000000 65535 f \n"
    for offset in offsets[1:]:
        content += f"{offset:010d} 00000 n \n".encode("ascii")
    content += (
        b"trailer\n"
        + f"<< /Size {len(objects) + 1} /Root 1 0 R >>\n".encode("ascii")
        + b"startxref\n"
        + str(xref_offset).encode("ascii")
        + b"\n%%EOF\n"
    )
    path.write_bytes(content)
