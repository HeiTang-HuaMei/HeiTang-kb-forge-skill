import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_pipeline_config_build_writes_pipeline_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "pipeline.build.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pipeline RAG Agent demo fixture question glossary", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
domain: product
mode: pipeline_demo
rag:
  enabled: true
  profile: basic
agent:
  enabled: true
  type: product_manager_agent
  name: Product Manager Pipeline Agent
demo:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert (output_dir / "pipeline_report.md").exists()
    assert (output_dir / "pipeline_manifest.json").exists()
    report = (output_dir / "pipeline_report.md").read_text(encoding="utf-8")
    manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    assert "## Pipeline Summary" in report
    assert "## Enabled Stages" in report
    assert "## Final Result" in report
    assert manifest["task"] == "build"
    assert manifest["final_status"] == "pass"
    stages = {stage["name"]: stage for stage in manifest["stages"]}
    assert stages["rag_export"]["enabled"] is True
    assert stages["rag_export"]["status"] == "success"
    assert stages["agent_template"]["enabled"] is True
    assert stages["agent_template"]["status"] == "success"
    assert stages["demo_report"]["enabled"] is True
    assert stages["demo_report"]["status"] == "success"


def test_run_config_does_not_write_pipeline_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "run.build.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Run config should not emit pipeline files", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert not (output_dir / "pipeline_report.md").exists()
    assert not (output_dir / "pipeline_manifest.json").exists()


def test_pipeline_config_batch_writes_pipeline_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "pipeline.batch.yaml"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("Pipeline batch fixture", encoding="utf-8")
    (input_dir / "002_more.txt").write_text("Pipeline batch text fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: batch
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
domain: product
mode: pipeline_batch
demo:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    assert manifest["task"] == "batch"
    assert manifest["final_status"] == "pass"
    assert (output_dir / "pipeline_report.md").exists()
    assert (output_dir / "batch_manifest.json").exists()


def test_pipeline_config_batch_merge_writes_pipeline_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "pipeline.merge.yaml"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("Pipeline merge fixture", encoding="utf-8")
    (input_dir / "001_more.txt").write_text("Pipeline merge text fixture", encoding="utf-8")
    config_path.write_text(
        f"""
task: batch
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
domain: product
mode: pipeline_merge
batch:
  merge_same_sequence: true
demo:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    batch_manifest = json.loads((output_dir / "batch_manifest.json").read_text(encoding="utf-8"))
    pipeline_manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    assert batch_manifest["merge_same_sequence"] is True
    assert batch_manifest["total_groups"] == 1
    assert pipeline_manifest["final_status"] == "pass"


def test_pipeline_config_reuses_loader_errors(tmp_path):
    config_path = tmp_path / "bad.yaml"
    config_path.write_text(
        """
task: export
input: ./input
output: ./output
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code != 0
    assert "Unsupported config task: export" in str(result.exception)
