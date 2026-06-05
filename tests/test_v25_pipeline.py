import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v25_pipeline_reports_release_quality_stages(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    config = tmp_path / "v25.yaml"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("v25 pipeline fixture.", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
platform_distribution:
  enabled: true
  platform: all
quality_gate:
  enabled: true
release_blockers:
  enabled: true
regression:
  enabled: true
golden_samples:
  enabled: true
export_certification:
  enabled: true
compatibility_matrix:
  enabled: true
llm_quality_gate_assist:
  enabled: true
release_readiness:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config)])

    assert result.exit_code == 0, result.output
    stages = {stage["name"]: stage for stage in json.loads((output / "pipeline_manifest.json").read_text(encoding="utf-8"))["stages"]}
    for name in [
        "quality_gate",
        "release_blockers",
        "regression_check",
        "golden_sample_validation",
        "platform_export_certification",
        "compatibility_matrix",
        "llm_quality_gate_assist",
        "release_readiness",
    ]:
        assert stages[name]["enabled"] is True

