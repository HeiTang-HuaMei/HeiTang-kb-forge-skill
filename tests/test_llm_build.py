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


def test_default_build_does_not_emit_llm_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge default fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir)])

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert "llm_enabled" not in manifest
    report = (output_dir / "ingest_report.md").read_text(encoding="utf-8")
    assert "## LLM Summary" not in report


def test_llm_build_writes_enhancement_files_and_metadata(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge LLM Fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--llm",
            "--llm-provider",
            "fake",
            "--llm-model",
            "fake-model",
            "--no-llm-cache",
        ],
    )

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES | LLM_FILES
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["llm_enabled"] is True
    assert manifest["llm_provider"] == "fake"
    assert manifest["llm_model"] == "fake-model"
    assert set(manifest["llm_output_files"]) == LLM_FILES
    report = (output_dir / "ingest_report.md").read_text(encoding="utf-8")
    assert "## LLM Summary" in report
    assert "- Enabled: True" in report

    for file_name in LLM_FILES:
        lines = (output_dir / file_name).read_text(encoding="utf-8").splitlines()
        assert len(lines) >= 1
    record = json.loads((output_dir / "llm_cards.jsonl").read_text(encoding="utf-8").splitlines()[0])
    for field in [
        "source_path",
        "chunk_id",
        "citation",
        "llm_provider",
        "llm_model",
        "confidence",
        "token_usage",
        "cache_key",
        "generated_at",
    ]:
        assert field in record


def test_llm_failure_falls_back_and_writes_empty_files(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge LLM failure fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["build", "--input", str(input_dir), "--output", str(output_dir), "--llm", "--llm-provider", "fake-fail"],
    )

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES | LLM_FILES
    assert (output_dir / "llm_cards.jsonl").read_text(encoding="utf-8") == ""
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert any("LLM cards extraction failed" in warning for warning in manifest["warnings"])


def test_llm_strict_failure_fails_build(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge LLM strict fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
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

    assert result.exit_code != 0


def test_llm_outputs_do_not_include_api_key(monkeypatch, tmp_path):
    monkeypatch.setenv("HEITANG_LLM_API_KEY", "secret-api-key")
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge LLM Fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["build", "--input", str(input_dir), "--output", str(output_dir), "--llm", "--no-llm-cache"],
    )

    assert result.exit_code == 0, result.output
    output_text = "\n".join(path.read_text(encoding="utf-8") for path in output_dir.iterdir() if path.is_file())
    assert "secret-api-key" not in output_text
