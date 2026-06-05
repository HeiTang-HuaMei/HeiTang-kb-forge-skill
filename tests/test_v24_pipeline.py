import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_v24_pipeline_reports_platform_distribution_stage(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "output"
    config = tmp_path / "v24.yaml"
    input_dir.mkdir()
    (input_dir / "001_note.md").write_text("v24 pipeline fixture.", encoding="utf-8")
    config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
skill:
  enabled: true
platform_distribution:
  enabled: true
  platform: generic
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["pipeline", "--config", str(config)])

    assert result.exit_code == 0, result.output
    stages = {stage["name"]: stage for stage in json.loads((output / "pipeline_manifest.json").read_text(encoding="utf-8"))["stages"]}
    assert stages["platform_distribution"]["status"] == "success"

