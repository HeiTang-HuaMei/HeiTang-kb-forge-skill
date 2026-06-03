import json

from docx import Document
from typer.testing import CliRunner

from heitang_kb_forge.cli import app


STANDARD_PACKAGE_FILES = {
    "chunks.jsonl",
    "cards.jsonl",
    "qa_pairs.jsonl",
    "glossary.jsonl",
    "manifest.json",
    "ingest_report.md",
}


def test_batch_build_processes_numbered_files_and_records_failures(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    output_dir.mkdir()
    (input_dir / "001_markdown.md").write_text("KB Forge Markdown Fixture", encoding="utf-8")
    (input_dir / "002_text.txt").write_text("KB Forge TXT Fixture", encoding="utf-8")
    _write_minimal_text_pdf(input_dir / "003_pdf.pdf")
    _write_minimal_text_docx(input_dir / "004_docx.docx")
    (input_dir / "005_unsupported.xyz").write_text("Unsupported fixture", encoding="utf-8")
    (input_dir / "006_exists.md").write_text("Existing output fixture", encoding="utf-8")
    (input_dir / "not_numbered.md").write_text("Ignored fixture", encoding="utf-8")
    (output_dir / "006_exists").mkdir()

    result = CliRunner().invoke(
        app,
        [
            "batch",
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
    assert (output_dir / "batch_manifest.json").exists()
    assert (output_dir / "batch_report.md").exists()

    for item_dir in ["001_markdown", "002_text", "003_pdf", "004_docx"]:
        assert {path.name for path in (output_dir / item_dir).iterdir()} == STANDARD_PACKAGE_FILES

    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["total_files"] == 6
    assert manifest["succeeded"] == 4
    assert manifest["failed"] == 2
    assert {item["status"] for item in manifest["items"]} == {"success", "failed"}
    assert {item["sequence_id"] for item in manifest["items"]} == {"001", "002", "003", "004", "005", "006"}

    failed_items = {item["sequence_id"]: item for item in manifest["items"] if item["status"] == "failed"}
    assert "Unsupported file extension" in failed_items["005"]["error"]
    assert "Output directory already exists" in failed_items["006"]["error"]

    chunk_text = "\n".join(
        json.loads(line)["text"]
        for item_dir in ["001_markdown", "002_text", "003_pdf", "004_docx"]
        for line in (output_dir / item_dir / "chunks.jsonl").read_text(encoding="utf-8").splitlines()
    )
    assert "KB Forge Markdown Fixture" in chunk_text
    assert "KB Forge TXT Fixture" in chunk_text
    assert "KB Forge PDF Fixture" in chunk_text
    assert "KB Forge DOCX Fixture" in chunk_text
    assert "not_numbered" not in json.dumps(manifest)


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
