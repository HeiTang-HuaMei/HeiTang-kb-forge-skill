import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app


def test_run_config_workbench_contracts_writes_from_core_output(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    config_path = tmp_path / "v34.yaml"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Workbench contract config evidence.", encoding="utf-8")
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output_dir.as_posix()}
workbench_contracts:
  enabled: true
  project_name: Config Workbench
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    manifest = _json(output_dir / "workbench_contract_manifest.json")
    assert manifest["project_name"] == "Config Workbench"
    assert _json(output_dir / "workbench_status_contract.json")["status"] == "ready"
    assert _json(output_dir / "workbench_status_contract.json")["storage_backend"] == "local_workspace"


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
