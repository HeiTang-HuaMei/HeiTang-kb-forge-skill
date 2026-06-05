import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v22_config_generates_gap_fill_outputs(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    workspace = tmp_path / "workspace"
    config = tmp_path / "v22.yaml"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("v22 config fixture.", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
workspace:
  enabled: true
  path: {workspace.as_posix()}
skill:
  enabled: true
  type: qa_skill
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

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    assert (output / "skill_package" / "TASKS.md").exists()
    assert (output / "agent_package" / "agent_compat_check_result.json").exists()
    assert (output / "workspace_refresh" / "refresh_plan.json").exists()
    assert (output / "provider_readiness" / "provider_readiness_result.json").exists()
    assert json.loads((workspace / "studio_v22_summary.json").read_text(encoding="utf-8"))["workspace_refresh"] == "available"

