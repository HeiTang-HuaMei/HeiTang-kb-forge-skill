import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


KB_RUNTIME_FILES = {
    "kb_index.jsonl",
    "kb_index_manifest.json",
    "kb_query_result.json",
    "kb_query_trace.json",
    "kb_citation_trace.json",
    "kb_answer.md",
    "kb_answer_report.json",
    "retrieval_quality_report.json",
    "rag_eval_baseline.jsonl",
    "rag_eval_baseline_report.md",
}


def test_kb_index_writes_runtime_index_quality_and_eval_baseline(tmp_path):
    package = _build_package(tmp_path, "Pricing strategy and revenue evidence for product planning.")
    output = tmp_path / "runtime"

    result = CliRunner().invoke(app, ["kb-index", "--package", str(package), "--output", str(output)])

    assert result.exit_code == 0, result.output
    assert (output / "kb_index.jsonl").exists()
    assert (output / "kb_index_manifest.json").exists()
    assert (output / "retrieval_quality_report.json").exists()
    assert (output / "rag_eval_baseline.jsonl").exists()
    assert (output / "rag_eval_baseline_report.md").exists()
    manifest = _read_json(output / "kb_index_manifest.json")
    quality = _read_json(output / "retrieval_quality_report.json")
    assert manifest["kb_index_version"] == "2.9.0-alpha.1"
    assert manifest["total_records"] >= 4
    assert quality["citation_coverage"] > 0


def test_kb_query_writes_result_trace_and_citation_trace(tmp_path):
    package = _build_package(tmp_path, "Pricing strategy and revenue evidence for product planning.")
    output = tmp_path / "query"

    result = CliRunner().invoke(
        app,
        ["kb-query", "--package", str(package), "--query", "pricing revenue", "--output", str(output)],
    )

    assert result.exit_code == 0, result.output
    query_result = _read_json(output / "kb_query_result.json")
    query_trace = _read_json(output / "kb_query_trace.json")
    citation_trace = _read_json(output / "kb_citation_trace.json")
    assert query_result["status"] == "pass"
    assert query_result["selected_count"] > 0
    assert query_trace["selected_ids"]
    assert citation_trace["citations"]
    assert all(record["citation"] for record in query_result["records"])


def test_kb_answer_writes_cited_answer(tmp_path):
    package = _build_package(tmp_path, "Pricing strategy and revenue evidence for product planning.")
    output = tmp_path / "answer"

    result = CliRunner().invoke(
        app,
        ["kb-answer", "--package", str(package), "--query", "pricing revenue", "--output", str(output)],
    )

    assert result.exit_code == 0, result.output
    answer = (output / "kb_answer.md").read_text(encoding="utf-8")
    report = _read_json(output / "kb_answer_report.json")
    assert report["status"] == "answered"
    assert report["citation_count"] > 0
    assert "## Citations" in answer
    assert "#chunk=" in answer


def test_kb_answer_refuses_low_confidence(tmp_path):
    package = _build_package(tmp_path, "Pricing strategy and revenue evidence for product planning.")
    output = tmp_path / "refusal"

    result = CliRunner().invoke(
        app,
        [
            "kb-answer",
            "--package",
            str(package),
            "--query",
            "unrelated astrophysics treaty",
            "--output",
            str(output),
            "--min-score",
            "999",
        ],
    )

    assert result.exit_code == 0, result.output
    answer = (output / "kb_answer.md").read_text(encoding="utf-8")
    report = _read_json(output / "kb_answer_report.json")
    assert report["status"] == "refused"
    assert report["low_confidence_refusal"] is True
    assert "Refusal reason: low_confidence" in answer


def test_default_build_does_not_emit_knowledge_runtime_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Default build should not emit KB runtime files.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir)])

    assert result.exit_code == 0, result.output
    assert not any((output_dir / name).exists() for name in KB_RUNTIME_FILES)
    manifest = _read_json(output_dir / "manifest.json")
    assert "knowledge_runtime_enabled" not in manifest


def test_build_knowledge_runtime_writes_outputs_and_manifest_fields(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing strategy and revenue evidence for product planning.", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--knowledge-runtime",
            "--kb-query",
            "pricing revenue",
        ],
    )

    assert result.exit_code == 0, result.output
    assert all((output_dir / name).exists() for name in KB_RUNTIME_FILES)
    manifest = _read_json(output_dir / "manifest.json")
    assert manifest["knowledge_runtime_enabled"] is True
    assert manifest["knowledge_runtime_version"] == "2.9.0-alpha.1"
    assert set(manifest["knowledge_runtime_files"]) == KB_RUNTIME_FILES


def test_run_config_knowledge_runtime_writes_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "run.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing strategy and revenue evidence for product planning.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
knowledge_runtime:
  enabled: true
  query: pricing revenue
  top_k: 3
  min_score: 2
  citation_required: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert all((output_dir / name).exists() for name in KB_RUNTIME_FILES)
    report = _read_json(output_dir / "kb_answer_report.json")
    assert report["status"] == "answered"


def test_pipeline_config_reports_knowledge_runtime_stages(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "pipeline.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing strategy and revenue evidence for product planning.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
knowledge_runtime:
  enabled: true
  query: pricing revenue
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    pipeline_manifest = _read_json(output_dir / "pipeline_manifest.json")
    stages = {stage["name"]: stage for stage in pipeline_manifest["stages"]}
    for stage_name in [
        "kb_index",
        "kb_query",
        "kb_answer",
        "retrieval_quality_report",
        "rag_eval_baseline",
    ]:
        assert stages[stage_name]["enabled"] is True
        assert stages[stage_name]["status"] == "success"
    assert pipeline_manifest["final_status"] == "pass"


def _build_package(tmp_path, text):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "package"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text(text, encoding="utf-8")
    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir)])
    assert result.exit_code == 0, result.output
    return output_dir


def _read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))
