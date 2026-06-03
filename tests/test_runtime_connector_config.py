import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_run_config_supports_embedding_and_vector(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "runtime.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Runtime connector config fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
rag:
  enabled: true
embedding:
  enabled: true
  provider: fake
  model: fake-embedding-model
vector:
  enabled: true
  store: local_json
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["embedding_enabled"] is True
    assert manifest["vector_export_enabled"] is True
    assert (output_dir / "embeddings.jsonl").exists()
    assert (output_dir / "vector_store_records.jsonl").exists()


def test_pipeline_config_reports_embedding_and_vector_stages(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "runtime_pipeline.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Runtime connector pipeline fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
rag:
  enabled: true
embedding:
  enabled: true
vector:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    pipeline_manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    report = (output_dir / "pipeline_report.md").read_text(encoding="utf-8")
    stages = {stage["name"]: stage for stage in pipeline_manifest["stages"]}
    assert stages["embedding_generation"]["status"] == "success"
    assert stages["vector_export"]["status"] == "success"
    assert "embedding_generation" in report
    assert "vector_export" in report
