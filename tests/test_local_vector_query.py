import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.vector.query import detect_vector_index_staleness, query_local_vector_index


def test_local_vector_query_supports_hybrid_mode_and_metadata_filters(tmp_path):
    package = _build_vector_package(tmp_path)

    records, trace = query_local_vector_index(
        package,
        "pricing policy",
        mode="hybrid",
        filters={"source_path": "pricing.md"},
    )

    assert trace["mode"] == "hybrid"
    assert trace["tests_require_real_llm_api_network"] is False
    assert trace["staleness"]["status"] == "fresh"
    assert records
    assert all(record["source_path"] == "pricing.md" for record in records)
    assert records[0]["retrieval_mode"] == "hybrid"
    assert "vector_score" in records[0]
    assert "keyword_score" in records[0]


def test_local_vector_query_detects_stale_vector_index(tmp_path):
    package = _build_vector_package(tmp_path)
    vectors = _read_jsonl(package / "vector_store_records.jsonl")
    (package / "vector_store_records.jsonl").write_text(json.dumps(vectors[0], ensure_ascii=False) + "\n", encoding="utf-8")

    staleness = detect_vector_index_staleness(package)

    assert staleness["status"] == "stale"
    assert staleness["missing_vector_count"] == 1
    assert staleness["count_mismatch"] is True


def test_query_vector_index_cli_writes_trace_and_report(tmp_path):
    package = _build_vector_package(tmp_path)
    output = tmp_path / "query_output"

    result = CliRunner().invoke(
        app,
        [
            "query-vector-index",
            "--package",
            str(package),
            "--query",
            "renewal policy",
            "--mode",
            "hybrid",
            "--source-path",
            "renewal.md",
            "--output",
            str(output),
        ],
    )

    assert result.exit_code == 0, result.output
    report = json.loads((output / "vector_query_report.json").read_text(encoding="utf-8"))
    trace = json.loads((output / "vector_query_trace.json").read_text(encoding="utf-8"))
    assert report["status"] == "pass"
    assert report["metadata_filtering_proven"] is True
    assert trace["records_returned"] >= 1
    assert (output / "vector_query_report.md").exists()


def test_build_manifest_exposes_local_vector_query_truth(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Local vector query truth fixture", encoding="utf-8")

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
            "--vector-export",
        ],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["local_vector_query_enabled"] is True
    assert manifest["local_hybrid_retrieval_enabled"] is True
    assert manifest["metadata_filtered_vector_query_enabled"] is True
    assert manifest["stale_vector_index_detection_enabled"] is True
    assert manifest["external_vector_db_adapter_status"] == "future_disabled"


def _build_vector_package(tmp_path):
    package = tmp_path / "package"
    package.mkdir()
    embedding_input = [
        {
            "embedding_id": "chunk_0",
            "text": "Pricing policy explains renewal fees.",
            "asset_type": "chunk",
            "source_path": "pricing.md",
            "chunk_id": "c0",
            "citation": "pricing.md#chunk=c0",
        },
        {
            "embedding_id": "chunk_1",
            "text": "Renewal policy explains cancellation windows.",
            "asset_type": "chunk",
            "source_path": "renewal.md",
            "chunk_id": "c1",
            "citation": "renewal.md#chunk=c1",
        },
    ]
    embeddings = [
        {
            "embedding_id": "chunk_0",
            "text_hash": "h0",
            "vector": [0.2, 0.1, 0.0, 0.4, 0.5, 0.1, 0.2, 0.3],
            "dimensions": 8,
            "provider": "fake",
            "model": "fake-embedding-model",
            "source_asset_type": "chunk",
            "source_path": "pricing.md",
            "chunk_id": "c0",
            "citation": "pricing.md#chunk=c0",
        },
        {
            "embedding_id": "chunk_1",
            "text_hash": "h1",
            "vector": [0.1, 0.3, 0.1, 0.2, 0.1, 0.4, 0.2, 0.2],
            "dimensions": 8,
            "provider": "fake",
            "model": "fake-embedding-model",
            "source_asset_type": "chunk",
            "source_path": "renewal.md",
            "chunk_id": "c1",
            "citation": "renewal.md#chunk=c1",
        },
    ]
    vectors = [
        {
            "vector_record_id": "local_json_0",
            "embedding_id": item["embedding_id"],
            "vector": item["vector"],
            "metadata": {
                "source_asset_type": item["source_asset_type"],
                "source_path": item["source_path"],
                "chunk_id": item["chunk_id"],
                "citation": item["citation"],
                "provider": item["provider"],
                "model": item["model"],
                "dimensions": item["dimensions"],
            },
            "store": "local_json",
        }
        for item in embeddings
    ]
    _write_jsonl(package / "embedding_input.jsonl", embedding_input)
    _write_jsonl(package / "embeddings.jsonl", embeddings)
    _write_jsonl(package / "vector_store_records.jsonl", vectors)
    (package / "vector_store_manifest.json").write_text(
        json.dumps({"store": "local_json", "total_records": len(vectors)}, ensure_ascii=False),
        encoding="utf-8",
    )
    return package


def _write_jsonl(path, rows):
    path.write_text("\n".join(json.dumps(row, ensure_ascii=False) for row in rows) + "\n", encoding="utf-8")


def _read_jsonl(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
