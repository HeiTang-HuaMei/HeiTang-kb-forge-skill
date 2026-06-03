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
LLM_FILES = {
    "llm_cards.jsonl",
    "llm_qa_pairs.jsonl",
    "llm_glossary.jsonl",
    "frameworks.jsonl",
    "case_cards.jsonl",
    "metrics.jsonl",
}


def test_batch_llm_writes_enhancement_files(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("KB Forge LLM Batch Fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["batch", "--input", str(input_dir), "--output", str(output_dir), "--llm", "--no-llm-cache"],
    )

    assert result.exit_code == 0, result.output
    assert {path.name for path in (output_dir / "001_lesson").iterdir()} == STANDARD_PACKAGE_FILES | LLM_FILES


def test_batch_llm_failure_fallback_keeps_item_success(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_text.md").write_text("Text fixture", encoding="utf-8")
    (input_dir / "002_fail.md").write_text("Failure fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["batch", "--input", str(input_dir), "--output", str(output_dir), "--llm", "--llm-provider", "fake-fail"],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["succeeded"] == 2
    assert manifest["failed"] == 0


def test_batch_llm_strict_failure_isolated_to_items(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_text.md").write_text("Text fixture", encoding="utf-8")
    (input_dir / "002_fail.md").write_text("Failure fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "batch",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--llm",
            "--llm-provider",
            "fake-fail",
            "--llm-strict",
        ],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["succeeded"] == 0
    assert manifest["failed"] == 2
    assert all("LLM cards extraction failed" in item["error"] for item in manifest["items"])


def test_merge_llm_failure_fallback_keeps_groups_success(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_text.md").write_text("Text fixture", encoding="utf-8")
    (input_dir / "001_more.md").write_text("More fixture", encoding="utf-8")
    (input_dir / "002_success.md").write_text("Success fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "batch",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--merge-same-sequence",
            "--llm",
            "--llm-provider",
            "fake-fail",
        ],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["succeeded"] == 2
    assert manifest["failed"] == 0


def test_merge_llm_strict_failure_isolated_to_groups(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_text.md").write_text("Text fixture", encoding="utf-8")
    (input_dir / "001_more.md").write_text("More fixture", encoding="utf-8")
    (input_dir / "002_success.md").write_text("Success fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "batch",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--merge-same-sequence",
            "--llm",
            "--llm-provider",
            "fake-fail",
            "--llm-strict",
        ],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["succeeded"] == 0
    assert manifest["failed"] == 2
    assert all("LLM cards extraction failed" in item["error"] for item in manifest["items"])
