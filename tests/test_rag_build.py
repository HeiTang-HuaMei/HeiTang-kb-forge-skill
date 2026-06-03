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


def test_default_build_does_not_emit_rag_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge RAG default fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir)])

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert "rag_export_enabled" not in manifest
    report = (output_dir / "ingest_report.md").read_text(encoding="utf-8")
    assert "## RAG Summary" not in report


def test_build_rag_export_writes_rag_files_and_metadata(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("RAG API glossary card question fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir), "--rag-export"])

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES | RAG_FILES
    embedding_records = _read_jsonl(output_dir / "embedding_input.jsonl")
    metadata_records = _read_jsonl(output_dir / "retrieval_metadata.jsonl")
    citation_map = json.loads((output_dir / "citation_map.json").read_text(encoding="utf-8"))
    rag_manifest = json.loads((output_dir / "rag_manifest.json").read_text(encoding="utf-8"))
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))

    asset_types = {record["asset_type"] for record in embedding_records}
    assert {"chunk", "card", "qa_pair", "glossary"}.issubset(asset_types)
    for record in embedding_records:
        assert record["embedding_id"]
        assert record["text"]
        assert record["asset_type"]
        assert record["source_path"]
        assert record["citation"]
        assert "embedding" not in record
    assert {record["embedding_id"] for record in embedding_records} == {
        record["embedding_id"] for record in metadata_records
    }
    first_id = embedding_records[0]["embedding_id"]
    assert citation_map["by_embedding_id"][first_id]["citation"] == embedding_records[0]["citation"]
    assert rag_manifest["total_records"] == len(embedding_records)
    assert rag_manifest["asset_type_counts"]["chunk"] >= 1
    assert rag_manifest["compatible_targets"] == ["faiss", "qdrant", "chroma", "milvus"]
    assert manifest["rag_export_enabled"] is True
    assert manifest["rag_profile"] == "basic"
    assert set(manifest["rag_export_files"]) == RAG_FILES
    report = (output_dir / "ingest_report.md").read_text(encoding="utf-8")
    assert "## RAG Summary" in report


def test_build_rag_include_llm_false_excludes_llm_assets(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge RAG LLM fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["build", "--input", str(input_dir), "--output", str(output_dir), "--llm", "--rag-export", "--no-llm-cache"],
    )

    assert result.exit_code == 0, result.output
    asset_types = {record["asset_type"] for record in _read_jsonl(output_dir / "embedding_input.jsonl")}
    assert not any(asset_type.startswith("llm_") for asset_type in asset_types)
    assert "framework" not in asset_types


def test_build_rag_include_llm_includes_llm_assets(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge RAG LLM fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--llm",
            "--rag-export",
            "--rag-include-llm",
            "--no-llm-cache",
        ],
    )

    assert result.exit_code == 0, result.output
    asset_types = {record["asset_type"] for record in _read_jsonl(output_dir / "embedding_input.jsonl")}
    assert {"llm_card", "llm_qa_pair", "llm_glossary", "framework", "case_card", "metric"}.issubset(asset_types)


def test_rag_include_llm_without_llm_records_warning(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge RAG warning fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["build", "--input", str(input_dir), "--output", str(output_dir), "--rag-export", "--rag-include-llm"],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert "RAG include LLM requested but LLM is not enabled" in manifest["warnings"]


def test_rag_export_rejects_unsupported_profile_in_build(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge RAG profile fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["build", "--input", str(input_dir), "--output", str(output_dir), "--rag-export", "--rag-profile", "advanced"],
    )

    assert result.exit_code != 0
    assert "Unsupported RAG profile: advanced" in str(result.exception)


def _read_jsonl(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]
