import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v24_config_generates_platform_distribution(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    config = tmp_path / "v24.yaml"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("v24 config fixture.", encoding="utf-8")
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
platform_distribution:
  enabled: true
  platform: generic
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config)])

    assert result.exit_code == 0, result.output
    manifest = json.loads((output / "platform_distribution" / "platform_manifest.json").read_text(encoding="utf-8"))
    assert manifest["platform"] == "generic"
    assert manifest["real_platform_runtime_started"] is False

