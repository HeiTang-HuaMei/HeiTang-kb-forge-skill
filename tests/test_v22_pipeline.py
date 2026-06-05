import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v22_pipeline_reports_gap_fill_stages(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    config = tmp_path / "v22.yaml"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("v22 pipeline fixture.", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
skill:
  enabled: true
  enhanced_template: true
agent_package:
  enabled: true
  compat: true
studio:
  enabled: true
workspace_refresh:
  enabled: true
provider_readiness:
  enabled: true
prompt_profile_versioning:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config)])

    assert result.exit_code == 0, result.output
    stages = {stage["name"]: stage for stage in json.loads((output / "pipeline_manifest.json").read_text(encoding="utf-8"))["stages"]}
    assert stages["enhanced_skill_template"]["status"] == "success"
    assert stages["agent_compatibility"]["status"] == "success"
    assert stages["workspace_refresh"]["status"] == "success"
    assert stages["provider_readiness"]["status"] == "success"
    assert stages["prompt_profile_versioning"]["status"] == "success"

