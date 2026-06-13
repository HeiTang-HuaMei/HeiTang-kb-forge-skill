from __future__ import annotations

import json
import re
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json


N8N_EXPORT_OUTPUT_FILES = [
    "n8n_workflow.json",
    "webhook_contract.json",
    "sample_event.json",
    "external_automation_manifest.json",
    "n8n_export_validation.json",
    "n8n_export_report.md",
]

_ALLOWED_NODE_TYPES = {
    "n8n-nodes-base.webhook",
    "n8n-nodes-base.respondToWebhook",
}
_DANGEROUS_NODE_TYPES = {
    "n8n-nodes-base.executeCommand",
    "n8n-nodes-base.ssh",
}
_WEBHOOK_PATH = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*(?:/[A-Za-z0-9][A-Za-z0-9._-]*)*$")
_SECRET_MARKERS = ("api_key", "apikey", "password", "secret", "token", "bearer ")


def export_n8n_workflow(
    output: Path,
    *,
    workflow_name: str = "HeiTang KB Forge Event Intake",
    webhook_path: str = "heitang-kb-forge/events",
) -> dict[str, Any]:
    _validate_webhook_path(webhook_path)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    workflow = _workflow(workflow_name, webhook_path)
    contract = _webhook_contract(webhook_path)
    sample = _sample_event()
    manifest = _automation_manifest(workflow_name, webhook_path)
    write_json(output / "n8n_workflow.json", workflow)
    write_json(output / "webhook_contract.json", contract)
    write_json(output / "sample_event.json", sample)
    write_json(output / "external_automation_manifest.json", manifest)
    validation = validate_n8n_workflow(
        output / "n8n_workflow.json",
        output=output,
        webhook_contract=output / "webhook_contract.json",
    )
    (output / "n8n_export_report.md").write_text(
        _render_report(manifest, validation),
        encoding="utf-8",
    )
    return {
        "status": validation["status"],
        "workflow": workflow,
        "webhook_contract": contract,
        "sample_event": sample,
        "manifest": manifest,
        "validation": validation,
        "output_files": N8N_EXPORT_OUTPUT_FILES,
    }


def validate_n8n_workflow(
    workflow_path: Path,
    *,
    output: Path | None = None,
    webhook_contract: Path | None = None,
) -> dict[str, Any]:
    workflow_path = Path(workflow_path)
    workflow = json.loads(workflow_path.read_text(encoding="utf-8"))
    errors: list[str] = []
    warnings: list[str] = []
    required = {"name", "nodes", "connections", "settings", "active"}
    missing = sorted(required - set(workflow)) if isinstance(workflow, dict) else sorted(required)
    errors.extend(f"missing_workflow_field:{field}" for field in missing)
    nodes = workflow.get("nodes", []) if isinstance(workflow, dict) else []
    if not isinstance(nodes, list) or not nodes:
        errors.append("nodes_required")
        nodes = []
    node_names = [str(node.get("name", "")) for node in nodes if isinstance(node, dict)]
    node_ids = [str(node.get("id", "")) for node in nodes if isinstance(node, dict)]
    if len(node_names) != len(set(node_names)):
        errors.append("duplicate_node_name")
    if len(node_ids) != len(set(node_ids)) or any(not node_id for node_id in node_ids):
        errors.append("invalid_or_duplicate_node_id")

    node_types = {str(node.get("type", "")) for node in nodes if isinstance(node, dict)}
    if "n8n-nodes-base.webhook" not in node_types:
        errors.append("webhook_node_required")
    if "n8n-nodes-base.respondToWebhook" not in node_types:
        errors.append("respond_to_webhook_node_required")
    dangerous = sorted(node_types & _DANGEROUS_NODE_TYPES)
    errors.extend(f"dangerous_node_type:{node_type}" for node_type in dangerous)
    unsupported = sorted(node_types - _ALLOWED_NODE_TYPES)
    errors.extend(f"unsupported_node_type:{node_type}" for node_type in unsupported)

    serialized = json.dumps(workflow, ensure_ascii=False).lower()
    if '"credentials"' in serialized:
        errors.append("credentials_embedded")
    if any(marker in serialized for marker in _SECRET_MARKERS):
        errors.append("secret_marker_detected")
    if workflow.get("active") is not False:
        errors.append("workflow_must_be_inactive")

    webhook_nodes = [node for node in nodes if node.get("type") == "n8n-nodes-base.webhook"]
    webhook_path = ""
    if webhook_nodes:
        webhook = webhook_nodes[0]
        params = webhook.get("parameters", {})
        webhook_path = str(params.get("path", ""))
        try:
            _validate_webhook_path(webhook_path)
        except ValueError:
            errors.append("invalid_webhook_path")
        if params.get("httpMethod") != "POST":
            errors.append("webhook_method_must_be_post")
        if params.get("responseMode") != "responseNode":
            errors.append("webhook_response_mode_must_use_response_node")

    connections = workflow.get("connections", {})
    if not _has_connection(connections, "HeiTang Event Webhook", "Acknowledge HeiTang Event"):
        errors.append("webhook_response_connection_missing")

    contract_path = Path(webhook_contract) if webhook_contract else None
    if contract_path:
        contract = json.loads(contract_path.read_text(encoding="utf-8"))
        if contract.get("method") != "POST":
            errors.append("contract_method_must_be_post")
        if contract.get("path") != webhook_path:
            errors.append("contract_path_mismatch")

    if not workflow.get("tags"):
        warnings.append("workflow_tags_empty")
    result = {
        "schema_version": "n8n_export_validation.v1",
        "status": "passed" if not errors else "failed",
        "validated_at": datetime.now(timezone.utc).isoformat(),
        "workflow_path": str(workflow_path),
        "workflow_name": workflow.get("name") if isinstance(workflow, dict) else None,
        "node_count": len(nodes),
        "node_types": sorted(node_types),
        "webhook_path": webhook_path,
        "active": workflow.get("active") if isinstance(workflow, dict) else None,
        "credentials_embedded": "credentials_embedded" in errors,
        "secret_marker_detected": "secret_marker_detected" in errors,
        "dangerous_node_types": dangerous,
        "n8n_runtime_bundled": False,
        "n8n_runtime_started": False,
        "network_called": False,
        "errors": errors,
        "warnings": warnings,
        "final_target_not_downgraded": True,
        "remaining_gap": "Export validation proves a safe n8n-compatible workflow shape, not import into a user-owned n8n instance, runtime execution, UI workflow completion, Full Gate, EXE, or release readiness.",
        "next_required_e2e_step": "Finish the Section 5 item 5.4 integration decision and UI impact evidence before processing item 5.5 MMSkills.",
        "not_goal_complete": True,
    }
    if output is not None:
        output = Path(output)
        output.mkdir(parents=True, exist_ok=True)
        write_json(output / "n8n_export_validation.json", result)
    return result


def _workflow(name: str, webhook_path: str) -> dict[str, Any]:
    namespace = uuid.UUID("6143f1fe-5f6b-4c5e-a8d0-296d879c48f0")
    webhook_id = str(uuid.uuid5(namespace, f"{webhook_path}:webhook"))
    response_id = str(uuid.uuid5(namespace, f"{webhook_path}:response"))
    version_id = str(uuid.uuid5(namespace, f"{name}:{webhook_path}:version"))
    return {
        "name": name,
        "nodes": [
            {
                "parameters": {
                    "httpMethod": "POST",
                    "path": webhook_path,
                    "responseMode": "responseNode",
                    "options": {},
                },
                "id": webhook_id,
                "name": "HeiTang Event Webhook",
                "type": "n8n-nodes-base.webhook",
                "typeVersion": 2,
                "position": [0, 0],
                "webhookId": webhook_id,
            },
            {
                "parameters": {
                    "respondWith": "json",
                    "responseBody": (
                        '={{ {"accepted": true, "event_type": $json.body.event_type, '
                        '"run_id": $json.body.run_id} }}'
                    ),
                    "options": {
                        "responseCode": 202,
                    },
                },
                "id": response_id,
                "name": "Acknowledge HeiTang Event",
                "type": "n8n-nodes-base.respondToWebhook",
                "typeVersion": 1.4,
                "position": [280, 0],
            },
        ],
        "pinData": {},
        "connections": {
            "HeiTang Event Webhook": {
                "main": [
                    [
                        {
                            "node": "Acknowledge HeiTang Event",
                            "type": "main",
                            "index": 0,
                        }
                    ]
                ]
            }
        },
        "active": False,
        "settings": {
            "executionOrder": "v1",
        },
        "versionId": version_id,
        "meta": {
            "templateCredsSetupCompleted": True,
            "heitangExportAdapter": "n8n_workflow_export.v1",
        },
        "tags": [],
    }


def _webhook_contract(path: str) -> dict[str, Any]:
    return {
        "schema_version": "heitang_external_webhook.v1",
        "adapter_id": "n8n_workflow_export",
        "method": "POST",
        "path": path,
        "content_type": "application/json",
        "authentication": {
            "mode": "user_configured_at_destination",
            "credentials_embedded": False,
        },
        "request": {
            "required_fields": [
                "event_type",
                "run_id",
                "occurred_at",
                "workspace_id",
                "status",
                "artifact_refs",
            ],
            "event_types": [
                "knowledge_package.ready",
                "skill_suite.ready",
                "agent_run.completed",
                "verification.completed",
            ],
            "artifact_refs_type": "array[string]",
        },
        "response": {
            "status_code": 202,
            "body_fields": ["accepted", "event_type", "run_id"],
        },
        "source_trace_required": True,
        "n8n_runtime_bundled": False,
    }


def _sample_event() -> dict[str, Any]:
    return {
        "event_type": "knowledge_package.ready",
        "run_id": "run_example",
        "occurred_at": "2026-06-12T00:00:00Z",
        "workspace_id": "workspace_example",
        "status": "passed",
        "artifact_refs": [
            "knowledge_package/manifest.json",
            "knowledge_package/source_trace.json",
        ],
        "source_trace": {
            "package_id": "pkg_example",
            "evidence_count": 2,
        },
    }


def _automation_manifest(workflow_name: str, webhook_path: str) -> dict[str, Any]:
    return {
        "schema_version": "external_automation_manifest.v1",
        "adapter_id": "n8n_workflow_export",
        "adapter_name": "n8n Workflow Export Adapter",
        "status": "export_ready",
        "workflow_name": workflow_name,
        "webhook_path": webhook_path,
        "export_format": "n8n_workflow_json",
        "runtime_model": "user_owned_external_runtime",
        "n8n_runtime_bundled": False,
        "n8n_runtime_started": False,
        "network_required_for_export": False,
        "credentials_embedded": False,
        "workflow_active_by_default": False,
        "arbitrary_command_nodes_allowed": False,
        "output_files": N8N_EXPORT_OUTPUT_FILES,
        "official_references": [
            "https://docs.n8n.io/workflows/export-import/",
            "https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/",
            "https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.respondtowebhook/",
        ],
        "final_target_not_downgraded": True,
        "remaining_gap": "The export adapter is local and offline. A user-owned n8n instance must import and execute the workflow; desktop Workflow Export UI and Core Bridge actions are not complete.",
        "next_required_e2e_step": "Expose this exporter later through the Workflow Export settings surface and validate import against a user-owned n8n instance without bundling it.",
        "not_goal_complete": True,
    }


def _has_connection(connections: Any, source: str, target: str) -> bool:
    if not isinstance(connections, dict):
        return False
    source_connections = connections.get(source, {})
    if not isinstance(source_connections, dict):
        return False
    for branch in source_connections.get("main", []):
        if isinstance(branch, list) and any(
            isinstance(item, dict) and item.get("node") == target for item in branch
        ):
            return True
    return False


def _validate_webhook_path(path: str) -> None:
    if not _WEBHOOK_PATH.fullmatch(path):
        raise ValueError(
            "Webhook path must contain safe URL path segments without a leading slash."
        )


def _render_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    return (
        "# n8n Workflow Export Report\n\n"
        f"- Status: `{validation['status']}`\n"
        f"- Workflow: `{manifest['workflow_name']}`\n"
        f"- Webhook: `POST /{manifest['webhook_path']}`\n"
        f"- Nodes: {validation['node_count']}\n"
        f"- Credentials embedded: `{str(validation['credentials_embedded']).lower()}`\n"
        f"- Dangerous nodes: `{len(validation['dangerous_node_types'])}`\n"
        "- n8n runtime bundled: `false`\n"
        "- n8n runtime started: `false`\n"
        "- Network called during export: `false`\n\n"
        "The workflow is exported inactive. Import and execution require a user-owned n8n instance.\n"
    )
