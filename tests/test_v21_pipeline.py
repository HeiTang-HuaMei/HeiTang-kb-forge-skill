import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v21_pipeline_reports_quality_stages(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    config = tmp_path / "v21.yaml"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("KB Forge v21 pipeline fixture.", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
input_hardening:
  enabled: true
quality:
  enabled: true
review:
  enabled: true
  workflow: true
  curation: true
retrieval_eval:
  enabled: true
evidence_benchmark:
  enabled: true
llm_quality_assist:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"]: stage for stage in manifest["stages"]}
    assert stages["input_coverage"]["status"] == "success"
    assert stages["knowledge_quality_scoring"]["status"] == "success"
    assert stages["retrieval_evaluation"]["status"] == "success"
    assert stages["evidence_benchmark"]["status"] == "success"
