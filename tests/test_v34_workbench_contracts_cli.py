import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.exporters.jsonl_exporter import write_json


def test_workbench_contracts_command_writes_contract_files(tmp_path):
    core = tmp_path / "core"
    output = tmp_path / "contracts"
    core.mkdir()
    write_json(core / "manifest.json", {"package_id": "demo"})

    result = CliRunner().invoke(
        app,
        ["workbench-contracts", "--core-output", str(core), "--output", str(output), "--project-name", "CLI Workbench"],
    )

    assert result.exit_code == 0, result.output
    assert _json(output / "workbench_contract_manifest.json")["project_name"] == "CLI Workbench"
    assert (output / "workbench_navigation_contract.json").exists()
    assert _json(output / "workbench_storage_contract.json")["storage_backend"] == "local_workspace"
    assert (output / "workbench_error_contract.json").exists()


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
