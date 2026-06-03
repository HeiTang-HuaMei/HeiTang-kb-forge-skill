import json

from docx import Document
from typer.testing import CliRunner

from kb_forge.cli import app


def test_build_processes_markdown_txt_pdf_and_docx(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "sample.md").write_text("# Sample\n\nKB Forge Markdown Fixture", encoding="utf-8")
    (input_dir / "sample.txt").write_text("KB Forge TXT Fixture", encoding="utf-8")
    _write_minimal_text_pdf(input_dir / "sample.pdf")
    _write_minimal_text_docx(input_dir / "sample.docx")

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
    assert {path.name for path in output_dir.iterdir()} == {
        "chunks.jsonl",
        "cards.jsonl",
        "qa_pairs.jsonl",
        "glossary.jsonl",
        "manifest.json",
        "ingest_report.md",
    }

    chunk_lines = (output_dir / "chunks.jsonl").read_text(encoding="utf-8").splitlines()
    chunks = [json.loads(line) for line in chunk_lines]
    chunk_text = "\n".join(chunk["text"] for chunk in chunks)

    assert len(chunks) >= 4
    assert "KB Forge Markdown Fixture" in chunk_text
    assert "KB Forge TXT Fixture" in chunk_text
    assert "KB Forge PDF Fixture" in chunk_text
    assert "KB Forge DOCX Fixture" in chunk_text
    assert json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))


def _write_minimal_text_docx(path):
    document = Document()
    document.add_paragraph("KB Forge DOCX Fixture")
    document.save(path)


def _write_minimal_text_pdf(path):
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Length 76 >>\nstream\nBT\n/F1 18 Tf\n72 720 Td\n(KB Forge PDF Fixture) Tj\nET\nendstream",
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
