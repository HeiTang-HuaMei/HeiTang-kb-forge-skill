from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.config.loader import load_config
from tests.v310_helpers import make_agent, read_json


def test_v310_config_defaults(tmp_path):
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    config = tmp_path / "run.yaml"
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {(tmp_path / "out").as_posix()}
""",
        encoding="utf-8",
    )

    loaded = load_config(config)

    assert loaded.local_agent_runtime.enabled is False
    assert loaded.local_agent_runtime.allow_llm is False
    assert loaded.local_agent_runtime.allow_network is False


def test_run_config_local_agent_runtime_writes_reports_and_manifest(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing policy evidence.", encoding="utf-8")
    child = make_agent(tmp_path, "output-child", "kb_bound", "output")
    config = tmp_path / "run.yaml"
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
local_agent_runtime:
  enabled: true
  agents:
    - {child.as_posix()}
  task: pricing policy
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = read_json(output / "manifest.json")
    assert manifest["local_agent_runtime_enabled"] is True
    assert manifest["local_agent_runtime_llm_required"] is False
    assert (output / "local_agent_runtime_status.json").exists()


def test_run_config_rejects_llm_and_network_runtime_modes(tmp_path):
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing policy evidence.", encoding="utf-8")
    config = tmp_path / "run.yaml"
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {(tmp_path / "output").as_posix()}
local_agent_runtime:
  enabled: true
  allow_network: true
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code != 0
    assert "local_agent_runtime.allow_network must remain false" in result.output
