import json

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
RAG_FILES = {
    "embedding_input.jsonl",
    "retrieval_metadata.jsonl",
    "citation_map.json",
    "rag_manifest.json",
}


def test_batch_rag_export_writes_files_for_successful_items(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("KB Forge RAG batch fixture", encoding="utf-8")
    (input_dir / "002_lesson.txt").write_text("KB Forge RAG batch text fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["batch", "--input", str(input_dir), "--output", str(output_dir), "--rag-export"])

    assert result.exit_code == 0, result.output
    assert {path.name for path in (output_dir / "001_lesson").iterdir()} == STANDARD_PACKAGE_FILES | RAG_FILES
    assert {path.name for path in (output_dir / "002_lesson").iterdir()} == STANDARD_PACKAGE_FILES | RAG_FILES
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["succeeded"] == 2
    assert manifest["failed"] == 0


def test_merge_rag_export_writes_files_for_successful_groups(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("KB Forge RAG merge fixture", encoding="utf-8")
    (input_dir / "001_more.txt").write_text("KB Forge RAG merge text fixture", encoding="utf-8")
    (input_dir / "002_success.md").write_text("KB Forge RAG merge success fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["batch", "--input", str(input_dir), "--output", str(output_dir), "--merge-same-sequence", "--rag-export"],
    )

    assert result.exit_code == 0, result.output
    assert {path.name for path in (output_dir / "001").iterdir()} == STANDARD_PACKAGE_FILES | RAG_FILES
    assert {path.name for path in (output_dir / "002").iterdir()} == STANDARD_PACKAGE_FILES | RAG_FILES
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["succeeded"] == 2
    assert manifest["failed"] == 0
