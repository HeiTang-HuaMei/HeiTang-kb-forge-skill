import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v19_pipeline_reports_workspace_stages(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    workspace = tmp_path / "workspace"
    config = tmp_path / "v19.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("v19 pipeline fixture", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
workspace:
  enabled: true
  path: {workspace.as_posix()}
  register_outputs: true
  health_check: true
provider_registry:
  enabled: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output_dir / "pipeline_manifest.json").read_text(encoding="utf-8"))
    stages = {stage["name"] for stage in manifest["stages"]}
    assert {"workspace_init", "workspace_register", "provider_registry_update", "workspace_health_check"}.issubset(stages)
