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
LLM_QUALITY_FILES = {
    "llm_quality_report.json",
    "llm_quality_summary.md",
}


def test_llm_quality_report_not_enabled_keeps_llm_output_unchanged(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("LLM quality default fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir), "--llm", "--no-llm-cache"])

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES | LLM_FILES
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert "llm_quality_report_enabled" not in manifest


def test_build_llm_quality_report_writes_files_and_metadata(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("LLM quality report fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--llm",
            "--no-llm-cache",
            "--llm-quality-report",
        ],
    )

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES | LLM_FILES | LLM_QUALITY_FILES
    report = json.loads((output_dir / "llm_quality_report.json").read_text(encoding="utf-8"))
    summary = (output_dir / "llm_quality_summary.md").read_text(encoding="utf-8")
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    ingest_report = (output_dir / "ingest_report.md").read_text(encoding="utf-8")
    assert report["total_llm_records"] >= 1
    assert report["asset_type_counts"]["cards"] >= 1
    assert "citation_coverage" in report
    assert "source_path_coverage" in report
    assert "chunk_id_coverage" in report
    assert "llm_quality_score" in report
    assert "llm_quality_level" in report
    assert "LLM Quality Summary" in summary
    assert "rule-based proxy evaluation" in summary
    assert manifest["llm_quality_report_enabled"] is True
    assert manifest["llm_quality_report_file"] == "llm_quality_report.json"
    assert manifest["llm_quality_summary_file"] == "llm_quality_summary.md"
    assert "## LLM Quality Summary" in ingest_report


def test_llm_quality_report_requires_llm(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("LLM quality requires LLM fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir), "--llm-quality-report"])

    assert result.exit_code != 0
    assert "--llm-quality-report requires --llm" in str(result.exception)


def test_llm_quality_report_includes_prompt_profile(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("LLM quality prompt profile fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--llm",
            "--no-llm-cache",
            "--prompt-profile",
            "examples/prompt_profiles/product_manager.yaml",
            "--llm-quality-report",
        ],
    )

    assert result.exit_code == 0, result.output
    report = json.loads((output_dir / "llm_quality_report.json").read_text(encoding="utf-8"))
    assert report["prompt_profile"] == "product_manager"
    assert report["prompt_profile_hash"]


def test_batch_llm_quality_report_writes_files_for_successful_items(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("Batch LLM quality fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["batch", "--input", str(input_dir), "--output", str(output_dir), "--llm", "--no-llm-cache", "--llm-quality-report"],
    )

    assert result.exit_code == 0, result.output
    assert LLM_QUALITY_FILES.issubset({path.name for path in (output_dir / "001_lesson").iterdir()})
