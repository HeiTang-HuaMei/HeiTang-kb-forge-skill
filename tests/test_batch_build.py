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
    "quality_report.json",
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

    report = (output_dir / "batch_report.md").read_text(encoding="utf-8")
    _assert_single_report_sections(report)
    assert "| Sequence | Name | Output Path | Chunks |" in report
    assert "| Sequence | Name | Source Path | Error |" in report
    assert "- Not using same-sequence merge mode." in report


def test_batch_build_merges_same_sequence_when_enabled(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_author.txt").write_text("KB Forge Author Fixture", encoding="utf-8")
    (input_dir / "001_outline.md").write_text("KB Forge Outline Fixture", encoding="utf-8")
    _write_minimal_text_docx(input_dir / "001_catalog.docx")
    (input_dir / "002_success.md").write_text("KB Forge Success Fixture", encoding="utf-8")
    (input_dir / "003_unsupported.xyz").write_text("Unsupported fixture", encoding="utf-8")
    (input_dir / "not_numbered.md").write_text("Ignored fixture", encoding="utf-8")

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
            "--merge-same-sequence",
        ],
    )

    assert result.exit_code == 0, result.output
    assert {path.name for path in (output_dir / "001").iterdir()} == STANDARD_PACKAGE_FILES
    assert {path.name for path in (output_dir / "002").iterdir()} == STANDARD_PACKAGE_FILES
    assert not (output_dir / "001_author").exists()

    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["merge_same_sequence"] is True
    assert manifest["total_files"] == 5
    assert manifest["total_groups"] == 3
    assert manifest["succeeded"] == 2
    assert manifest["failed"] == 1

    items = {item["sequence_id"]: item for item in manifest["items"]}
    assert items["001"]["status"] == "success"
    assert items["001"]["group_name"] == "author"
    assert items["001"]["source_count"] == 3
    assert len(items["001"]["source_paths"]) == 3
    assert items["001"]["output_path"].endswith("/001")
    assert items["001"]["error"] is None
    assert items["001"]["chunk_count"] >= 3
    assert items["001"]["files"] == [
        "chunks.jsonl",
        "cards.jsonl",
        "qa_pairs.jsonl",
        "glossary.jsonl",
        "manifest.json",
        "ingest_report.md",
        "quality_report.json",
    ]
    assert items["003"]["status"] == "failed"
    assert "Unsupported file extension in group" in items["003"]["error"]
    assert "not_numbered" not in json.dumps(manifest)

    item_manifest = json.loads((output_dir / "001" / "manifest.json").read_text(encoding="utf-8"))
    assert item_manifest["source_count"] == 3

    chunks = [
        json.loads(line)
        for line in (output_dir / "001" / "chunks.jsonl").read_text(encoding="utf-8").splitlines()
    ]
    source_paths = {chunk["source_path"] for chunk in chunks}
    chunk_text = "\n".join(chunk["text"] for chunk in chunks)
    assert len(source_paths) == 3
    assert "KB Forge Author Fixture" in chunk_text
    assert "KB Forge Outline Fixture" in chunk_text
    assert "KB Forge DOCX Fixture" in chunk_text

    report = (output_dir / "batch_report.md").read_text(encoding="utf-8")
    _assert_single_report_sections(report)
    assert "Merge same sequence: True" in report
    assert "| Sequence | Group Name | Output Path | Sources | Chunks |" in report
    assert "| Sequence | Group Name | Source Paths | Error |" in report
    assert "Group Source Files" in report
    assert "001_author.txt" in report


def test_batch_build_merge_mode_fails_existing_group_directory(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    output_dir.mkdir()
    (input_dir / "001_exists.md").write_text("Existing group fixture", encoding="utf-8")
    (output_dir / "001").mkdir()

    result = CliRunner().invoke(
        app,
        [
            "batch",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--merge-same-sequence",
        ],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["total_files"] == 1
    assert manifest["total_groups"] == 1
    assert manifest["succeeded"] == 0
    assert manifest["failed"] == 1
    assert manifest["items"][0]["status"] == "failed"
    assert "Output directory already exists" in manifest["items"][0]["error"]


def test_batch_image_ocr_failure_does_not_block_text_file(monkeypatch, tmp_path):
    import heitang_kb_forge.cli_runtime as cli_runtime

    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_text.md").write_text("Text fixture", encoding="utf-8")
    (input_dir / "002_image.png").write_bytes(b"mock image")
    monkeypatch.setitem(cli_runtime.PARSERS, ".png", lambda path: (_ for _ in ()).throw(RuntimeError("OCR failed")))

    result = CliRunner().invoke(app, ["batch", "--input", str(input_dir), "--output", str(output_dir)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["succeeded"] == 1
    assert manifest["failed"] == 1
    items = {item["sequence_id"]: item for item in manifest["items"]}
    assert items["001"]["status"] == "success"
    assert items["002"]["status"] == "failed"
    assert "OCR failed" in items["002"]["error"]


def test_batch_merge_image_ocr_failure_fails_group_only(monkeypatch, tmp_path):
    import heitang_kb_forge.cli_runtime as cli_runtime

    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_text.md").write_text("Text fixture", encoding="utf-8")
    (input_dir / "001_image.png").write_bytes(b"mock image")
    (input_dir / "002_success.md").write_text("Success fixture", encoding="utf-8")
    monkeypatch.setitem(cli_runtime.PARSERS, ".png", lambda path: (_ for _ in ()).throw(RuntimeError("OCR failed")))

    result = CliRunner().invoke(
        app,
        ["batch", "--input", str(input_dir), "--output", str(output_dir), "--merge-same-sequence"],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["succeeded"] == 1
    assert manifest["failed"] == 1
    items = {item["sequence_id"]: item for item in manifest["items"]}
    assert items["001"]["status"] == "failed"
    assert items["002"]["status"] == "success"
    assert "OCR failed" in items["001"]["error"]


def test_batch_scanned_pdf_ocr_failure_does_not_block_text_file(monkeypatch, tmp_path):
    import heitang_kb_forge.cli_runtime as cli_runtime

    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_text.md").write_text("Text fixture", encoding="utf-8")
    (input_dir / "002_scanned.pdf").write_bytes(b"%PDF-1.4")
    monkeypatch.setitem(cli_runtime.PARSERS, ".pdf", lambda path: (_ for _ in ()).throw(RuntimeError("PDF OCR failed")))

    result = CliRunner().invoke(app, ["batch", "--input", str(input_dir), "--output", str(output_dir)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["succeeded"] == 1
    assert manifest["failed"] == 1
    items = {item["sequence_id"]: item for item in manifest["items"]}
    assert items["001"]["status"] == "success"
    assert items["002"]["status"] == "failed"
    assert "OCR" in items["002"]["error"]


def test_batch_merge_scanned_pdf_ocr_failure_fails_group_only(monkeypatch, tmp_path):
    import heitang_kb_forge.cli_runtime as cli_runtime

    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_text.md").write_text("Text fixture", encoding="utf-8")
    (input_dir / "001_scanned.pdf").write_bytes(b"%PDF-1.4")
    (input_dir / "002_success.md").write_text("Success fixture", encoding="utf-8")
    monkeypatch.setitem(cli_runtime.PARSERS, ".pdf", lambda path: (_ for _ in ()).throw(RuntimeError("PDF OCR failed")))

    result = CliRunner().invoke(
        app,
        ["batch", "--input", str(input_dir), "--output", str(output_dir), "--merge-same-sequence"],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["succeeded"] == 1
    assert manifest["failed"] == 1
    items = {item["sequence_id"]: item for item in manifest["items"]}
    assert items["001"]["status"] == "failed"
    assert items["002"]["status"] == "success"
    assert "OCR" in items["001"]["error"]


def _write_minimal_text_docx(path):
    document = Document()
    document.add_paragraph("KB Forge DOCX Fixture")
    document.save(path)


def _assert_single_report_sections(report):
    assert report.count("## Batch Summary") == 1
    assert report.count("## Successful Items") == 1
    assert report.count("## Group Source Files") == 1
    assert report.count("## Failed Items") == 1
    assert report.count("## Standard Package Output") == 1


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
