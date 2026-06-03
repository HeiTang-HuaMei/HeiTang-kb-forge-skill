import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_build_writes_standard_knowledge_package(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text(
        "# Lesson\n\nA local knowledge package should include chunks and metadata.",
        encoding="utf-8",
    )

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

    expected_files = {
        "chunks.jsonl",
        "cards.jsonl",
        "qa_pairs.jsonl",
        "glossary.jsonl",
        "manifest.json",
        "ingest_report.md",
        "quality_report.json",
    }
    assert {path.name for path in output_dir.iterdir()} == expected_files

    chunk_lines = (output_dir / "chunks.jsonl").read_text(encoding="utf-8").splitlines()
    assert len(chunk_lines) >= 1
    first_chunk = json.loads(chunk_lines[0])
    assert first_chunk["chunk_id"]
    assert first_chunk["text"]

    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    for field in [
        "package_version",
        "generated_at",
        "domain",
        "mode",
        "source_count",
        "chunk_count",
        "files",
    ]:
        assert field in manifest
    assert manifest["files"] == [
        "chunks.jsonl",
        "cards.jsonl",
        "qa_pairs.jsonl",
        "glossary.jsonl",
        "manifest.json",
        "ingest_report.md",
        "quality_report.json",
    ]
    assert manifest["quality_report_file"] == "quality_report.json"


def test_build_processes_mocked_png_ocr(monkeypatch, tmp_path):
    import heitang_kb_forge.cli as cli

    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "image.png").write_bytes(b"mock image")
    monkeypatch.setitem(cli.PARSERS, ".png", lambda path: "KB Forge OCR Fixture")

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
    assert {path.name for path in output_dir.iterdir()} == expected_package_files()
    chunk_text = "\n".join(
        json.loads(line)["text"] for line in (output_dir / "chunks.jsonl").read_text(encoding="utf-8").splitlines()
    )
    assert "KB Forge OCR Fixture" in chunk_text


def expected_package_files():
    return {
        "chunks.jsonl",
        "cards.jsonl",
        "qa_pairs.jsonl",
        "glossary.jsonl",
        "manifest.json",
        "ingest_report.md",
        "quality_report.json",
    }
