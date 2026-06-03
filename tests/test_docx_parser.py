import json

from docx import Document
from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.parsers.docx_parser import parse_docx


def test_docx_parser_extracts_text_from_text_based_docx(tmp_path):
    sample_docx = tmp_path / "sample_text.docx"
    _write_minimal_text_docx(sample_docx)

    text = parse_docx(sample_docx)

    assert isinstance(text, str)
    assert "KB Forge DOCX Fixture" in text
    assert "text-based DOCX parsing" in text


def test_build_processes_text_based_docx(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    _write_minimal_text_docx(input_dir / "sample_text.docx")

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
    assert "KB Forge DOCX Fixture" in first_chunk["text"]
    assert "text-based DOCX parsing" in first_chunk["text"]


def _write_minimal_text_docx(path):
    document = Document()
    document.add_paragraph("KB Forge DOCX Fixture")
    document.add_paragraph("text-based DOCX parsing")
    document.save(path)
