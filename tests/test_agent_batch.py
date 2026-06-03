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
AGENT_FILES = {
    "agent_profile.yaml",
    "system_prompt.md",
    "retrieval_config.yaml",
    "tools.yaml",
    "eval_cases.jsonl",
}


def test_batch_agent_template_writes_files_for_successful_items(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("KB Forge Agent batch fixture", encoding="utf-8")
    (input_dir / "002_lesson.txt").write_text("KB Forge Agent batch text fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["batch", "--input", str(input_dir), "--output", str(output_dir), "--agent-template"])

    assert result.exit_code == 0, result.output
    assert {path.name for path in (output_dir / "001_lesson").iterdir()} == STANDARD_PACKAGE_FILES | AGENT_FILES
    assert {path.name for path in (output_dir / "002_lesson").iterdir()} == STANDARD_PACKAGE_FILES | AGENT_FILES
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["succeeded"] == 2
    assert manifest["failed"] == 0


def test_merge_agent_template_writes_files_for_successful_groups(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("KB Forge Agent merge fixture", encoding="utf-8")
    (input_dir / "001_more.txt").write_text("KB Forge Agent merge text fixture", encoding="utf-8")
    (input_dir / "002_success.md").write_text("KB Forge Agent merge success fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["batch", "--input", str(input_dir), "--output", str(output_dir), "--merge-same-sequence", "--agent-template"],
    )

    assert result.exit_code == 0, result.output
    assert {path.name for path in (output_dir / "001").iterdir()} == STANDARD_PACKAGE_FILES | AGENT_FILES
    assert {path.name for path in (output_dir / "002").iterdir()} == STANDARD_PACKAGE_FILES | AGENT_FILES
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["succeeded"] == 2
    assert manifest["failed"] == 0


def test_batch_agent_template_failure_isolated_to_item(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_bad.md").write_text("Bad fixture", encoding="utf-8")
    (input_dir / "002_bad.md").write_text("Bad fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["batch", "--input", str(input_dir), "--output", str(output_dir), "--agent-template", "--agent-type", "bad"],
    )

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["succeeded"] == 0
    assert manifest["failed"] == 2
    assert all("Unsupported agent type: bad" in item["error"] for item in manifest["items"])
