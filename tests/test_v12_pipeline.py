import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_pipeline_reports_v12_stages(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    workspace = tmp_path / "workspace"
    config = tmp_path / "config.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("V1.2 pipeline fixture.", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
risk_labels:
  enabled: true
runtime:
  enabled: true
workspace:
  enabled: true
  path: {workspace.as_posix()}
refresh:
  enabled: true
review:
  enabled: true
evaluation_dashboard:
  enabled: true
publish:
  enabled: true
  profile: generic_rag
planning_readiness:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"]: stage for stage in manifest["stages"]}
    assert stages["workspace_registry"]["status"] == "success"
    assert stages["refresh_check"]["status"] == "success"
    assert stages["review_queue"]["status"] == "success"
    assert stages["evaluation_dashboard"]["status"] == "success"
    assert stages["publish_profile"]["status"] == "success"
    assert stages["planning_readiness"]["status"] == "success"
