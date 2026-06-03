import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.parsers.pdf_parser import parse_pdf


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
