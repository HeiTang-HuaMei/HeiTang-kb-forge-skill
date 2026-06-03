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
AGENT_FILES = {
    "agent_profile.yaml",
    "system_prompt.md",
    "retrieval_config.yaml",
    "tools.yaml",
    "eval_cases.jsonl",
}
DEMO_FILES = {
    "demo_report.md",
    "demo_manifest.json",
    "eval_summary.json",
}


def test_default_build_does_not_emit_demo_report(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge demo default fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir)])

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert "demo_report_enabled" not in manifest
    report = (output_dir / "ingest_report.md").read_text(encoding="utf-8")
    assert "## Demo Summary" not in report


def test_build_demo_report_writes_files_and_metadata(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge demo card question glossary fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir), "--demo-report"])

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES | DEMO_FILES
    demo_report = (output_dir / "demo_report.md").read_text(encoding="utf-8")
    for section in [
        "# HeiTang KB Forge Demo Report",
        "## Package Summary",
        "## Quality Summary",
        "## Asset Coverage",
        "## RAG Export Status",
        "## Agent Template Status",
        "## Eval Case Summary",
        "## Readiness Checklist",
        "## Final Status",
    ]:
        assert section in demo_report
    demo_manifest = json.loads((output_dir / "demo_manifest.json").read_text(encoding="utf-8"))
    eval_summary = json.loads((output_dir / "eval_summary.json").read_text(encoding="utf-8"))
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    report = (output_dir / "ingest_report.md").read_text(encoding="utf-8")

    assert demo_manifest["final_status"] == "warning"
    assert demo_manifest["rag_export_enabled"] is False
    assert demo_manifest["agent_template_enabled"] is False
    assert eval_summary["status"] == "warning"
    assert manifest["demo_report_enabled"] is True
    assert set(manifest["demo_report_files"]) == DEMO_FILES
    assert "## Demo Summary" in report


def test_build_demo_report_with_rag_and_agent_shows_ready_status(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge demo RAG Agent question answer glossary fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--rag-export",
            "--agent-template",
            "--demo-report",
        ],
    )

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES | RAG_FILES | AGENT_FILES | DEMO_FILES
    demo_report = (output_dir / "demo_report.md").read_text(encoding="utf-8")
    demo_manifest = json.loads((output_dir / "demo_manifest.json").read_text(encoding="utf-8"))
    eval_summary = json.loads((output_dir / "eval_summary.json").read_text(encoding="utf-8"))
    assert "- Enabled: True" in demo_report
    assert demo_manifest["rag_export_enabled"] is True
    assert demo_manifest["agent_template_enabled"] is True
    assert eval_summary["eval_cases_count"] >= 1
    assert eval_summary["required_citation_count"] >= 1
