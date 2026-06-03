import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_vector_export_requires_embedding(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Vector requires embedding fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir), "--vector-export"])

    assert result.exit_code != 0
    assert "--vector-export requires --embedding" in str(result.exception)


def test_vector_export_writes_local_json_files(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Vector export fixture", encoding="utf-8")

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
    records = _read_jsonl(output_dir / "vector_store_records.jsonl")
    manifest = json.loads((output_dir / "vector_store_manifest.json").read_text(encoding="utf-8"))
    assert records
    assert records[0]["embedding_id"]
    assert records[0]["vector"]
    assert records[0]["metadata"]["citation"]
    assert records[0]["store"] == "local_json"
    assert manifest["store"] == "local_json"
    assert manifest["total_records"] == len(records)
    assert "faiss" in manifest["compatible_targets"]


def test_vector_export_fake_store_is_available(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Fake vector store fixture", encoding="utf-8")

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
            "--vector-store",
            "fake",
        ],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "vector_store_manifest.json").read_text(encoding="utf-8"))
    assert manifest["store"] == "fake"


def test_unsupported_vector_store_errors(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Bad vector store fixture", encoding="utf-8")

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
            "--vector-store",
            "bad",
        ],
    )

    assert result.exit_code != 0
    assert "Unsupported vector store: bad" in str(result.exception)


def test_planned_vector_stores_do_not_write_real_databases(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Planned vector store fixture", encoding="utf-8")

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
            "--vector-store",
            "qdrant",
        ],
    )

    assert result.exit_code != 0
    assert "Vector store 'qdrant' is configured but real write is not implemented in v0.9.0" in str(result.exception)


def _read_jsonl(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]
