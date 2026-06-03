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
    ]
