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


def test_default_build_does_not_emit_agent_template(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge Agent default fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir)])

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert "agent_template_enabled" not in manifest
    report = (output_dir / "ingest_report.md").read_text(encoding="utf-8")
    assert "## Agent Template Summary" not in report


def test_build_agent_template_writes_files_and_metadata(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge Agent fixture question answer glossary", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--agent-template",
            "--agent-type",
            "customer_service_agent",
            "--agent-name",
            "SupportAgent",
        ],
    )

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES | AGENT_FILES
    profile = (output_dir / "agent_profile.yaml").read_text(encoding="utf-8")
    prompt = (output_dir / "system_prompt.md").read_text(encoding="utf-8")
    retrieval = (output_dir / "retrieval_config.yaml").read_text(encoding="utf-8")
    tools = (output_dir / "tools.yaml").read_text(encoding="utf-8")
    eval_cases = _read_jsonl(output_dir / "eval_cases.jsonl")
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    report = (output_dir / "ingest_report.md").read_text(encoding="utf-8")

    assert "agent_name: SupportAgent" in profile
    assert "agent_type: customer_service_agent" in profile
    assert "customer_service_agent" in prompt
    assert "FAQ" in prompt
    assert "chunks.jsonl" in retrieval
    assert "Use --rag-export" in retrieval
    assert "knowledge_retrieval" in tools
    assert "citation_lookup" in tools
    assert eval_cases
    assert eval_cases[0]["required_citation"]
    assert eval_cases[0]["source_path"]
    assert eval_cases[0]["chunk_id"]
    assert manifest["agent_template_enabled"] is True
    assert manifest["agent_type"] == "customer_service_agent"
    assert set(manifest["agent_template_files"]) == AGENT_FILES
    assert "## Agent Template Summary" in report


def test_build_agent_template_uses_rag_files_when_rag_export_enabled(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge Agent RAG fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["build", "--input", str(input_dir), "--output", str(output_dir), "--rag-export", "--agent-template"],
    )

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES | RAG_FILES | AGENT_FILES
    retrieval = (output_dir / "retrieval_config.yaml").read_text(encoding="utf-8")
    assert "embedding_input_file: embedding_input.jsonl" in retrieval
    assert "retrieval_metadata_file: retrieval_metadata.jsonl" in retrieval
    assert "citation_map_file: citation_map.json" in retrieval


def test_build_agent_template_rejects_unsupported_agent_type(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("KB Forge Agent unsupported fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        ["build", "--input", str(input_dir), "--output", str(output_dir), "--agent-template", "--agent-type", "bad"],
    )

    assert result.exit_code != 0
    assert "Unsupported agent type: bad" in str(result.exception)


def _read_jsonl(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]
