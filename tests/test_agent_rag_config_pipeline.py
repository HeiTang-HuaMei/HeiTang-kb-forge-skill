import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_agent_rag_config_pipeline_writes_rag_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "agent-rag.pipeline.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Agent RAG config pipeline fixture.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
agent_rag:
  enabled: true
  query: config pipeline
  top_k: 3
  citation_required: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert (output_dir / "answer.md").exists()
    assert (output_dir / "retrieval_trace.json").exists()
    assert (output_dir / "citation_trace.json").exists()
    manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"]: stage for stage in manifest["stages"]}
    assert stages["agent_rag_retrieve"]["status"] == "success"
    assert stages["agent_rag_answer"]["status"] == "success"
    assert stages["citation_trace"]["status"] == "success"
