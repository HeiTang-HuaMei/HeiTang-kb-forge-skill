import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.config.loader import load_config


QUERY_PLANNING_FILES = {
    "query_rewrite_report.json",
    "query_rewrite_trace.json",
    "retrieval_plan.json",
    "retrieval_plan_report.md",
}


def test_query_rewrite_config_schema_defaults(tmp_path):
    config = tmp_path / "run.yaml"
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing and revenue evidence.", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
""",
        encoding="utf-8",
    )

    loaded = load_config(config)

    assert loaded.query_rewrite.enabled is False
    assert loaded.query_rewrite.strategy == "hybrid"
    assert loaded.query_rewrite.allow_llm_rewrite is False
    assert loaded.query_rewrite.max_rewrites == 5


def test_run_config_query_rewrite_writes_outputs_and_manifest(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    config = tmp_path / "run.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing and revenue evidence.", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
domain: finance
retrieval:
  enabled: true
  query: pricing revenue
query_rewrite:
  enabled: true
  strategy: hybrid
  use_conversation_context: true
  conversation_context: pricing policy context
  generate_multi_queries: true
  max_rewrites: 4
  allow_llm_rewrite: true
  retrieval_purpose: answering
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    assert all((output / name).exists() for name in QUERY_PLANNING_FILES)
    manifest = _json(output / "manifest.json")
    plan = _json(output / "retrieval_plan.json")
    assert manifest["query_rewrite_enabled"] is True
    assert manifest["retrieval_planning_enabled"] is True
    assert manifest["query_rewrite_llm_assist"] == "reserved_only"
    assert plan["retrieval_purpose"] == "answering"
    assert len(plan["query_variants"]) <= 4
    assert plan["tests_require_real_llm_api_network"] is False


def test_default_build_does_not_emit_query_planning_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Default query planning stays off.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert not any((output / name).exists() for name in QUERY_PLANNING_FILES)
    assert "query_rewrite_enabled" not in _json(output / "manifest.json")


def test_run_config_invalid_query_rewrite_purpose_has_stable_error(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    config = tmp_path / "run.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing and revenue evidence.", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
query_rewrite:
  enabled: true
  retrieval_purpose: external
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code != 0
    assert "query_rewrite.retrieval_purpose must be one of" in result.output


def test_existing_kb_query_behavior_unchanged_without_query_rewrite(tmp_path):
    package = _build_package(tmp_path)
    output = tmp_path / "query"

    result = CliRunner().invoke(app, ["kb-query", "--package", str(package), "--query", "pricing revenue", "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert (output / "kb_query_result.json").exists()
    assert not (output / "retrieval_plan.json").exists()
    trace = _json(output / "kb_query_trace.json")
    assert "rewritten_query" not in trace


def _build_package(tmp_path):
    input_dir = tmp_path / "source"
    output = tmp_path / "package"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing and revenue evidence.", encoding="utf-8")
    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output)])
    assert result.exit_code == 0, result.output
    return output


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
