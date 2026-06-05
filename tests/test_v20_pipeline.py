import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v20_pipeline_reports_stable_stages(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    workspace = tmp_path / "workspace"
    config = tmp_path / "v20.yaml"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("v20 pipeline fixture", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
workspace:
  enabled: true
  path: {workspace.as_posix()}
  register_outputs: true
provider_registry:
  enabled: true
studio:
  enabled: true
  project_name: pipeline_demo
stable_check:
  enabled: true
provider_health:
  enabled: true
reliability:
  enabled: true
release_package:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"]: stage for stage in manifest["stages"]}
    assert stages["studio_run"]["status"] == "success"
    assert stages["stable_contract_check"]["status"] == "success"
    assert stages["provider_health_check"]["status"] == "success"
    assert stages["reliability_scoring"]["status"] == "success"
    assert stages["release_package"]["status"] == "success"
