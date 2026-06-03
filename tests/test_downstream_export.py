import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def _read_jsonl(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def test_build_downstream_export_writes_provider_neutral_files(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("# Downstream Fixture\n\nKnowledge for downstream export.", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["build", "--input", str(input_dir), "--output", str(output_dir), "--downstream-export"],
    )

    assert result.exit_code == 0, result.output
    langchain = _read_jsonl(output_dir / "langchain_documents.jsonl")
    llamaindex = _read_jsonl(output_dir / "llamaindex_documents.jsonl")
    generic = json.loads((output_dir / "generic_rag_package.json").read_text(encoding="utf-8"))
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert langchain[0]["page_content"]
    assert llamaindex[0]["text"]
    assert generic["metadata"]["total_records"] >= 1
    assert manifest["downstream_export_enabled"] is True


def test_batch_downstream_export_writes_files_for_successful_items(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("Batch downstream fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["batch", "--input", str(input_dir), "--output", str(output_dir), "--downstream-export"],
    )

    assert result.exit_code == 0, result.output
    assert (output_dir / "001_lesson" / "langchain_documents.jsonl").exists()
