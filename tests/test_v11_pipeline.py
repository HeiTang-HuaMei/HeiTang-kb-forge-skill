import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_pipeline_reports_v11_stages(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    config = tmp_path / "config.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pipeline v1.1 fixture.", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
versioning:
  enabled: true
knowledge_graph:
  enabled: true
retrieval_eval:
  enabled: true
risk_labels:
  enabled: true
runtime:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"]: stage for stage in manifest["stages"]}
    assert stages["package_versioning"]["status"] == "success"
    assert stages["knowledge_graph_export"]["status"] == "success"
    assert stages["retrieval_eval_export"]["status"] == "success"
    assert stages["risk_labeling"]["status"] == "success"
    assert stages["agent_runtime_smoke"]["status"] == "success"
