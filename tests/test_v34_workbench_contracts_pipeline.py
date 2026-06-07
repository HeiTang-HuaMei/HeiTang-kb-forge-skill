import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_pipeline_reports_workbench_contracts_only_when_enabled(tmp_path):
    default_output = _run_pipeline(tmp_path, False)
    enabled_output = _run_pipeline(tmp_path, True)

    default_stage = _stages(default_output)["workbench_contracts"]
    enabled_stage = _stages(enabled_output)["workbench_contracts"]
    assert default_stage["status"] == "skipped"
    assert enabled_stage["status"] == "success"
    assert "workbench_action_contract.json" in enabled_stage["output_files"]
    assert "workbench_storage_contract.json" in enabled_stage["output_files"]


def _run_pipeline(tmp_path, enabled):
    input_dir = tmp_path / ("input_enabled" if enabled else "input_default")
    output_dir = tmp_path / ("output_enabled" if enabled else "output_default")
    config_path = tmp_path / ("enabled.yaml" if enabled else "default.yaml")
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Workbench contract pipeline evidence.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
workbench_contracts:
  enabled: {str(enabled).lower()}
""",
        encoding="utf-8",
    )
    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])
    assert result.exit_code == 0, result.output
    result = CliRunner().invoke(app, ["pipeline", "--config", str(config_path)])
    assert result.exit_code == 0, result.output
    return output_dir


def _stages(output):
    manifest = json.loads((output / "pipeline_manifest.json").read_text(encoding="utf-8"))
    return {stage["name"]: stage for stage in manifest["stages"]}
