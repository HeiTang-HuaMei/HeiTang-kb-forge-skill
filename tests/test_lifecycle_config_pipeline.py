import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_lifecycle_config_pipeline_reports_lifecycle_stages(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "pipeline.lifecycle.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Lifecycle config pipeline fixture.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
domain: education
mode: lifecycle
lifecycle:
  enabled: true
  update_mode: incremental
  missing_source_policy: mark_stale
  quality_gate: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert (output_dir / "source_registry.json").exists()
    assert (output_dir / "pipeline_manifest.json").exists()
    manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"]: stage for stage in manifest["stages"]}
    assert stages["source_registry"]["status"] == "success"
    assert stages["change_detection"]["status"] == "success"
    assert stages["update_quality_gate"]["status"] == "success"
