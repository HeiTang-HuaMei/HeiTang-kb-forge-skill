import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v20_config_generates_stable_workspace_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    workspace = tmp_path / "workspace"
    config = tmp_path / "v20.yaml"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("v20 stable config fixture", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
skill:
  enabled: true
  name: Stable Skill
  validate: true
agent_package:
  enabled: true
  name: Stable Agent
workspace:
  enabled: true
  path: {workspace.as_posix()}
  register_outputs: true
  health_check: true
provider_registry:
  enabled: true
  providers:
    - provider_id: mock_default
      provider_type: mock
      default_model: mock-model
studio:
  enabled: true
  project_name: stable_demo
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

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    assert (workspace / "studio_run_manifest.json").exists()
    stable = json.loads((workspace / "stable_check_result.json").read_text(encoding="utf-8"))
    assert stable["extension_readiness"]["master_skill_learning"] == "not_enabled"
    assert (workspace / "provider_health_result.json").exists()
    assert (workspace / "reliability_score.json").exists()
    assert (output_dir / "release_package" / "release_manifest.json").exists()
