import json

import pytest
from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.embedding.fake_provider import FakeEmbeddingProvider
from heitang_kb_forge.embedding.openai_compatible_provider import OpenAICompatibleEmbeddingProvider


def test_embedding_requires_rag_export(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Embedding requires RAG fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir), "--embedding"])

    assert result.exit_code != 0
    assert "--embedding requires --rag-export" in str(result.exception)


def test_rag_export_embedding_writes_files_and_fields(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Embedding provider fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["build", "--input", str(input_dir), "--output", str(output_dir), "--rag-export", "--embedding"],
    )

    assert result.exit_code == 0, result.output
    records = _read_jsonl(output_dir / "embeddings.jsonl")
    manifest = json.loads((output_dir / "embedding_manifest.json").read_text(encoding="utf-8"))
    assert records
    first = records[0]
    for field in [
        "embedding_id",
        "text_hash",
        "vector",
        "dimensions",
        "provider",
        "model",
        "source_asset_type",
        "source_path",
        "chunk_id",
        "citation",
        "created_at",
    ]:
        assert field in first
    assert manifest["provider"] == "fake"
    assert manifest["model"] == "fake-embedding-model"
    assert manifest["total_records"] == len(records)


def test_fake_embedding_is_deterministic():
    provider = FakeEmbeddingProvider()

    assert provider.embed("same text").vector == provider.embed("same text").vector


def test_unsupported_embedding_provider_errors(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Unsupported embedding fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--rag-export",
            "--embedding",
            "--embedding-provider",
            "bad",
        ],
    )

    assert result.exit_code != 0
    assert "Unsupported embedding provider: bad" in str(result.exception)


def test_openai_compatible_embedding_provider_skeleton_errors_without_network():
    provider = OpenAICompatibleEmbeddingProvider("embedding-model")

    with pytest.raises(RuntimeError, match="OpenAI-compatible embedding provider is not configured"):
        provider.embed("text")


def _read_jsonl(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]
