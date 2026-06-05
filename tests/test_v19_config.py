from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v19_config_creates_workspace_registries(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    workspace = tmp_path / "workspace"
    config = tmp_path / "v19.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("v19 workspace config fixture", encoding="utf-8")
    rules = tmp_path / "rules.yaml"
    rules.write_text("rules: []", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
skill:
  enabled: true
  name: Demo Skill
agent_package:
  enabled: true
  name: Demo Agent
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
prompt_profiles:
  enabled: true
  profiles:
    - profile_id: skill_default
      profile_type: skill_generation
      rules_path: {rules.as_posix()}
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    assert (workspace / "registries" / "package_registry.jsonl").read_text(encoding="utf-8").strip()
    assert (workspace / "registries" / "skill_registry.jsonl").read_text(encoding="utf-8").strip()
    assert (workspace / "registries" / "agent_registry.jsonl").read_text(encoding="utf-8").strip()
    assert (workspace / "reports" / "workspace_health_report.md").exists()
