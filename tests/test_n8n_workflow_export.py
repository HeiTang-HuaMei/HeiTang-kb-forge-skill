import json
from pathlib import Path

import pytest
from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.external_automation import (
    export_n8n_workflow,
    validate_n8n_workflow,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_n8n_export_writes_safe_import_bundle(tmp_path):
    result = export_n8n_workflow(
        tmp_path,
        workflow_name="HeiTang Events",
        webhook_path="heitang/events",
    )

    assert result["status"] == "passed"
    for filename in result["output_files"]:
        assert (tmp_path / filename).exists(), filename

    workflow = _json(tmp_path / "n8n_workflow.json")
    validation = _json(tmp_path / "n8n_export_validation.json")
    manifest = _json(tmp_path / "external_automation_manifest.json")
    contract = _json(tmp_path / "webhook_contract.json")

    assert workflow["name"] == "HeiTang Events"
    assert workflow["active"] is False
    assert {node["type"] for node in workflow["nodes"]} == {
        "n8n-nodes-base.webhook",
        "n8n-nodes-base.respondToWebhook",
    }
    assert all("credentials" not in node for node in workflow["nodes"])
    assert validation["status"] == "passed"
    assert validation["credentials_embedded"] is False
    assert validation["dangerous_node_types"] == []
    assert validation["n8n_runtime_bundled"] is False
    assert validation["n8n_runtime_started"] is False
    assert validation["network_called"] is False
    assert manifest["runtime_model"] == "user_owned_external_runtime"
    assert contract["method"] == "POST"
    assert contract["path"] == "heitang/events"
    assert contract["source_trace_required"] is True


def test_n8n_export_is_deterministic_for_same_name_and_path(tmp_path):
    first = tmp_path / "first"
    second = tmp_path / "second"

    export_n8n_workflow(first, workflow_name="Stable Export", webhook_path="heitang/events")
    export_n8n_workflow(second, workflow_name="Stable Export", webhook_path="heitang/events")

    assert _json(first / "n8n_workflow.json") == _json(second / "n8n_workflow.json")


@pytest.mark.parametrize(
    "path",
    [
        "/leading/slash",
        "../escape",
        "unsafe path",
        "https://example.test/hook",
        "",
    ],
)
def test_n8n_export_rejects_unsafe_webhook_paths(tmp_path, path):
    with pytest.raises(ValueError):
        export_n8n_workflow(tmp_path, webhook_path=path)


def test_n8n_validation_rejects_credentials_and_dangerous_nodes(tmp_path):
    export_dir = tmp_path / "export"
    export_n8n_workflow(export_dir)
    workflow_path = export_dir / "n8n_workflow.json"
    workflow = _json(workflow_path)
    workflow["nodes"][0]["credentials"] = {
        "httpHeaderAuth": {
            "id": "credential-id",
            "name": "credential-name",
        }
    }
    workflow["nodes"].append(
        {
            "parameters": {"command": "whoami"},
            "id": "dangerous-node",
            "name": "Run Command",
            "type": "n8n-nodes-base.executeCommand",
            "typeVersion": 1,
            "position": [560, 0],
        }
    )
    workflow_path.write_text(json.dumps(workflow), encoding="utf-8")

    result = validate_n8n_workflow(workflow_path)

    assert result["status"] == "failed"
    assert "credentials_embedded" in result["errors"]
    assert "dangerous_node_type:n8n-nodes-base.executeCommand" in result["errors"]
    assert "unsupported_node_type:n8n-nodes-base.executeCommand" in result["errors"]


def test_n8n_validation_rejects_contract_path_mismatch(tmp_path):
    export_n8n_workflow(tmp_path)
    contract = _json(tmp_path / "webhook_contract.json")
    contract["path"] = "different/path"
    contract_path = tmp_path / "mismatched_contract.json"
    contract_path.write_text(json.dumps(contract), encoding="utf-8")

    result = validate_n8n_workflow(
        tmp_path / "n8n_workflow.json",
        webhook_contract=contract_path,
    )

    assert result["status"] == "failed"
    assert "contract_path_mismatch" in result["errors"]


def test_n8n_cli_exports_and_validates_without_runtime(tmp_path):
    runner = CliRunner()
    export_dir = tmp_path / "export"
    validation_dir = tmp_path / "validation"

    export_result = runner.invoke(
        app,
        [
            "export-n8n-workflow",
            "--output",
            str(export_dir),
            "--workflow-name",
            "HeiTang CLI Export",
            "--webhook-path",
            "heitang/events",
        ],
    )
    validate_result = runner.invoke(
        app,
        [
            "validate-n8n-workflow",
            "--workflow",
            str(export_dir / "n8n_workflow.json"),
            "--webhook-contract",
            str(export_dir / "webhook_contract.json"),
            "--output",
            str(validation_dir),
        ],
    )

    assert export_result.exit_code == 0, export_result.output
    assert validate_result.exit_code == 0, validate_result.output
    assert "runtime_bundled=false" in export_result.output
    assert "runtime_started=false" in validate_result.output
    assert _json(validation_dir / "n8n_export_validation.json")["status"] == "passed"
