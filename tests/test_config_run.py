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


def test_run_config_build_generates_package_with_rag_agent_demo(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "kb_forge.build.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Config build RAG Agent demo fixture question glossary", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
domain: product
mode: agent_demo
rag:
  enabled: true
  profile: basic
  include_llm: false
agent:
  enabled: true
  type: product_manager_agent
  name: Product Manager Knowledge Agent
  language: zh-CN
demo:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert {path.name for path in output_dir.iterdir()} == STANDARD_PACKAGE_FILES | RAG_FILES | AGENT_FILES | DEMO_FILES
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["domain"] == "product"
    assert manifest["mode"] == "agent_demo"
    assert manifest["rag_export_enabled"] is True
    assert manifest["agent_template_enabled"] is True
    assert manifest["demo_report_enabled"] is True


def test_run_config_batch_reads_merge_same_sequence(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "kb_forge.batch.yml"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("Config batch merge fixture", encoding="utf-8")
    (input_dir / "001_more.txt").write_text("Config batch merge text fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: batch
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
domain: product
mode: batch_agent_demo
batch:
  merge_same_sequence: true
demo:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert (output_dir / "001").exists()
    assert {path.name for path in (output_dir / "001").iterdir()} == STANDARD_PACKAGE_FILES | DEMO_FILES
    manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    assert manifest["merge_same_sequence"] is True
    assert manifest["total_groups"] == 1
    assert manifest["succeeded"] == 1


def test_run_config_rejects_unsupported_task(tmp_path):
    config_path = tmp_path / "bad.yaml"
    config_path.write_text(
        """
task: export
input: ./input
output: ./output
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code != 0
    assert "Unsupported config task: export" in str(result.exception)


def test_run_config_requires_input_and_output(tmp_path):
    config_path = tmp_path / "missing.yaml"
    config_path.write_text("task: build\n", encoding="utf-8")

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code != 0
    assert "Missing required config field: input, output" in str(result.exception)


def test_run_config_rejects_invalid_yaml(tmp_path):
    config_path = tmp_path / "invalid.yaml"
    config_path.write_text("task: [", encoding="utf-8")

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code != 0
    assert "YAML parse failed" in str(result.exception)


def test_run_config_rejects_non_mapping_yaml(tmp_path):
    config_path = tmp_path / "list.yaml"
    config_path.write_text("- task\n- build\n", encoding="utf-8")

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code != 0
    assert "Config top level must be a mapping/object" in str(result.exception)


def test_run_config_rejects_unsupported_rag_profile(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "bad_rag.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Bad RAG profile fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
rag:
  enabled: true
  profile: advanced
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code != 0
    assert "Unsupported RAG profile: advanced" in str(result.exception)


def test_run_config_rejects_unsupported_agent_type(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "bad_agent.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Bad agent type fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
agent:
  enabled: true
  type: bad
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code != 0
    assert "Unsupported agent type: bad" in str(result.exception)


def test_example_config_templates_exist():
    assert __import__("pathlib").Path("examples/configs/kb_forge.build.yaml").exists()
    assert __import__("pathlib").Path("examples/configs/kb_forge.batch.yaml").exists()
