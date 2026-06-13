from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path, PureWindowsPath
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json

GENERATED_AT = "2026-06-13T20:10:00+08:00"

ASSET_DOMAINS = [
    "sources",
    "knowledge_bases",
    "skills",
    "agents",
    "workflows",
    "runs",
    "reports",
    "audits",
    "exports",
    "memory",
    "settings",
]

KB_TYPES = [
    "general",
    "specialized",
    "project",
    "personal",
    "skill_source",
    "agent_bound",
    "imported",
    "archived",
]

ACCESS_SCOPES = [
    "workspace_private",
    "shared_read_only",
    "cloned_copy",
    "imported_copy",
    "public_reference",
    "agent_bound",
    "archived_read_only",
]

REQUIRED_PRODUCT_OUTPUTS = [
    "docs/product/WORKSPACE_PARTITION_AND_ASSET_ISOLATION_PLAN.md",
    "docs/product/WORKSPACE_PARTITION_AND_ASSET_ISOLATION_PLAN.json",
    "docs/product/WORKSPACE_MANIFEST_SCHEMA.json",
    "docs/product/WORKSPACE_REGISTRY_SCHEMA.json",
    "docs/product/KNOWLEDGE_BASE_PARTITION_SCHEMA.json",
    "docs/product/KNOWLEDGE_BASE_ACCESS_SCOPE_MATRIX.json",
    "docs/product/WORKSPACE_ASSET_ISOLATION_MATRIX.json",
    "docs/product/CROSS_WORKSPACE_REFERENCE_POLICY.md",
    "docs/product/WORKSPACE_PATH_BOUNDARY_POLICY.md",
    "docs/product/WORKSPACE_PARTITION_UI_HANDOFF_CONTRACT.md",
    "docs/product/WORKSPACE_PARTITION_UI_HANDOFF_CONTRACT.json",
]

REQUIRED_BRIDGE_OUTPUTS = [
    "docs/bridge/WORKSPACE_BOUNDARY_BRIDGE_HANDOFF_CONTRACT.md",
    "docs/bridge/WORKSPACE_BOUNDARY_BRIDGE_HANDOFF_CONTRACT.json",
]

REQUIRED_AUDIT_OUTPUTS = [
    "run_manifest.json",
    "validation_report.json",
    "checkpoint.json",
]


@dataclass(frozen=True)
class PathBoundaryResult:
    path: str
    status: str
    reason: str
    repair_suggestion: str


def evaluate_workspace_path_candidate(path: str) -> dict[str, str]:
    """Classify a path candidate for the Pre-4.0 boundary contract.

    This is a contract validator, not a runtime file opener. It deliberately
    rejects absolute and parent-escape candidates before any filesystem read.
    """
    normalized = path.replace("\\", "/")
    lowered = normalized.lower()
    parts = [part for part in PureWindowsPath(path).parts if part not in ("", ".")]

    result = PathBoundaryResult(
        path=path,
        status="accepted",
        reason="workspace_relative_path",
        repair_suggestion="Keep the path relative to the active workspace asset root.",
    )
    if path in {"", ".", "./"}:
        result = PathBoundaryResult(
            path,
            "rejected",
            "empty_or_workspace_root_path",
            "Select a concrete asset path inside a workspace-owned asset root.",
        )
    elif normalized.startswith("/") or PureWindowsPath(path).is_absolute():
        result = PathBoundaryResult(
            path,
            "rejected",
            "absolute_path_escape",
            "Use a workspace-relative asset path instead of an absolute path.",
        )
    elif ".." in parts or "/../" in normalized or normalized.startswith("../"):
        result = PathBoundaryResult(
            path,
            "rejected",
            "parent_directory_escape",
            "Remove parent-directory traversal and choose an asset under the workspace root.",
        )
    elif "open-any-path" in lowered or lowered == "open_any_path":
        result = PathBoundaryResult(
            path,
            "rejected",
            "open_any_path_behavior",
            "Route access through an allowlisted workspace asset reference.",
        )
    elif lowered in {"repo", "repo_root", "repository_root"} or lowered.startswith("repo/"):
        result = PathBoundaryResult(
            path,
            "rejected",
            "repo_root_output_forbidden",
            "Write output under the active workspace export or audit root.",
        )
    elif lowered.startswith("c:/windows") or lowered.startswith("c:/program files"):
        result = PathBoundaryResult(
            path,
            "rejected",
            "system_path_forbidden",
            "System directories are outside the workspace boundary.",
        )
    elif lowered.startswith("c:/users/") or lowered.startswith("~/"):
        result = PathBoundaryResult(
            path,
            "rejected",
            "home_or_profile_path_forbidden",
            "Use the active workspace path instead of a user profile path.",
        )
    return {
        "path": result.path,
        "status": result.status,
        "reason": result.reason,
        "repair_suggestion": result.repair_suggestion,
    }


def build_pre_4_0_workspace_partition_foundation_gate(repo_root: Path) -> dict[str, Any]:
    repo_root = Path(repo_root)
    docs = _build_product_documents()
    bridge = _build_bridge_documents()
    path_checks = [
        evaluate_workspace_path_candidate(path)
        for path in [
            "sources/input.pdf",
            "../outside.pdf",
            "C:/Windows/system32/config",
            "C:/Program Files/tool/bin.exe",
            "C:/Users/Administrator/Desktop/source.pdf",
            "/absolute/output",
            "repo/root-output.json",
            "open-any-path",
        ]
    ]
    validation = _validate_payloads(docs, bridge, path_checks)
    passed = validation["status"] == "passed"
    return {
        "schema_version": "pre_4_0_workspace_partition_foundation_gate.v1",
        "generated_at": GENERATED_AT,
        "gate_id": "pre_4_0_workspace_partition_foundation_gate",
        "scope": "PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE",
        "status": "passed" if passed else "failed",
        "verdict": (
            "accepted_for_campaign_3_supplement_4_0_entry_gate"
            if passed
            else "failed"
        ),
        "integration_decision": "foundation_contract",
        "decision_qualifier": "workspace_partition_kb_access_scope_foundation_only",
        "repo_root": str(repo_root),
        "required_product_outputs": REQUIRED_PRODUCT_OUTPUTS,
        "required_bridge_outputs": REQUIRED_BRIDGE_OUTPUTS,
        "required_audit_outputs": REQUIRED_AUDIT_OUTPUTS,
        "asset_domains": ASSET_DOMAINS,
        "kb_types": KB_TYPES,
        "access_scopes": ACCESS_SCOPES,
        "product_documents": docs,
        "bridge_documents": bridge,
        "path_boundary_checks": path_checks,
        "validation_report": validation,
        "campaign_state_after_gate": _campaign_state_after_gate(passed),
        "non_substitution_rules": _non_substitution_rules(),
        "next_required_e2e_step": (
            "Run Campaign 3 Supplement 4.0 Entry Reconciliation Gate only."
            if passed
            else "Repair Pre-4.0 Workspace Partition Foundation Gate and rerun validation."
        ),
        "remaining_gap": (
            "Campaign 3 Supplement 4.0, Campaign 3 Final Consistency Gate, "
            "Campaign 1-3 Stage Test Gate, Integrated Closure, Closure Pack, "
            "Upload, Tag, CI Green, Closure Checklist Green, Campaigns 4-9, "
            "Full Gate, EXE packaging, and Final Release remain incomplete."
        ),
        "not_goal_complete": True,
    }


def write_pre_4_0_workspace_partition_foundation_gate(
    repo_root: Path,
    audit_output: Path | None = None,
) -> dict[str, Any]:
    repo_root = Path(repo_root)
    audit_output = Path(audit_output or repo_root / "artifacts" / "audits" / "pre_4_0_workspace_partition")
    report = build_pre_4_0_workspace_partition_foundation_gate(repo_root)

    _write_product_outputs(repo_root, report["product_documents"])
    _write_bridge_outputs(repo_root, report["bridge_documents"])
    audit_output.mkdir(parents=True, exist_ok=True)
    write_json(audit_output / "run_manifest.json", _run_manifest(report))
    write_json(audit_output / "validation_report.json", report["validation_report"])
    write_json(audit_output / "checkpoint.json", _checkpoint(report))
    (audit_output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")
    return report


def validate_pre_4_0_workspace_partition_foundation_gate(
    repo_root: Path,
    audit_output: Path | None = None,
) -> dict[str, Any]:
    repo_root = Path(repo_root)
    audit_output = Path(audit_output or repo_root / "artifacts" / "audits" / "pre_4_0_workspace_partition")
    errors: list[str] = []

    for relative in REQUIRED_PRODUCT_OUTPUTS + REQUIRED_BRIDGE_OUTPUTS:
        path = repo_root / relative
        if not path.exists():
            errors.append(f"missing_required_output:{relative}")

    manifest_path = audit_output / "run_manifest.json"
    validation_path = audit_output / "validation_report.json"
    checkpoint_path = audit_output / "checkpoint.json"
    manifest = _read_json(manifest_path, errors, "run_manifest")
    validation = _read_json(validation_path, errors, "validation_report")
    checkpoint = _read_json(checkpoint_path, errors, "checkpoint")

    if manifest.get("status") != "passed":
        errors.append("run_manifest_status_not_passed")
    if manifest.get("verdict") != "accepted_for_campaign_3_supplement_4_0_entry_gate":
        errors.append("run_manifest_verdict_mismatch")
    if validation.get("status") != "passed":
        errors.append("validation_report_status_not_passed")
    if checkpoint.get("checkpoint_id") != "pre_4_0_workspace_partition_foundation_gate_passed":
        errors.append("checkpoint_id_mismatch")

    state = manifest.get("campaign_state_after_gate", {})
    for key in (
        "pre_4_0_workspace_partition_complete",
        "workspace_manifest_ready",
        "workspace_registry_ready",
        "workspace_path_boundary_ready",
        "kb_partition_ready",
        "kb_access_scope_ready",
        "legacy_default_workspace_ready",
    ):
        if state.get(key) is not True:
            errors.append(f"{key}_not_true_after_gate")
    for key in (
        "campaign_3_4_0_active",
        "campaign_3_4_0_accepted",
        "campaign_4_active",
        "campaign_5_active",
        "agent_runtime_ready",
        "multi_agent_runtime_ready",
        "agent_memory_runtime_ready",
        "campaign_4_ui_complete",
        "campaign_5_bridge_complete",
        "future_bridge_action_added_to_current_allowlist",
        "bridge_execution_accepted",
    ):
        if state.get(key) is not False:
            errors.append(f"{key}_overclaim")

    return {
        "schema_version": "pre_4_0_workspace_partition_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "boundary_errors": errors,
        "validated_product_outputs": REQUIRED_PRODUCT_OUTPUTS,
        "validated_bridge_outputs": REQUIRED_BRIDGE_OUTPUTS,
        "validated_audit_outputs": [
            str((audit_output / name).relative_to(repo_root)).replace("\\", "/")
            if _is_relative_to(audit_output / name, repo_root)
            else str(audit_output / name)
            for name in REQUIRED_AUDIT_OUTPUTS
        ],
        "campaign_4_active": False,
        "campaign_5_active": False,
        "supplement_4_0_active": False,
        "not_goal_complete": True,
    }


def write_pre_4_0_workspace_partition_validation(
    repo_root: Path,
    audit_output: Path | None = None,
) -> dict[str, Any]:
    audit_output = Path(audit_output or Path(repo_root) / "artifacts" / "audits" / "pre_4_0_workspace_partition")
    validation = validate_pre_4_0_workspace_partition_foundation_gate(repo_root, audit_output)
    write_json(audit_output / "validation_report.json", validation)
    return validation


def _build_product_documents() -> dict[str, Any]:
    plan = {
        "schema_version": "workspace_partition_and_asset_isolation_plan.v1",
        "plan_id": "pre_4_0_workspace_partition",
        "status": "foundation_ready",
        "default_isolation": "workspace_private",
        "asset_domains": [
            {
                "asset_type": domain,
                "owner_field": "workspace_id",
                "default_scope": "workspace_private",
                "path_root": f"workspace/{domain}",
                "cross_workspace_default": "denied_without_explicit_reference",
                "audit_required": True,
            }
            for domain in ASSET_DOMAINS
        ],
        "legacy_default_workspace": {
            "workspace_id": "legacy_default_workspace",
            "compatibility_mode": "register_without_move_delete_or_rename",
            "moves_legacy_artifacts": False,
            "deletes_legacy_artifacts": False,
            "renames_legacy_artifacts": False,
        },
        "non_completion_boundaries": _non_substitution_rules(),
    }
    return {
        "WORKSPACE_PARTITION_AND_ASSET_ISOLATION_PLAN.json": plan,
        "WORKSPACE_PARTITION_AND_ASSET_ISOLATION_PLAN.md": _render_plan_md(plan),
        "WORKSPACE_MANIFEST_SCHEMA.json": _workspace_manifest_schema(),
        "WORKSPACE_REGISTRY_SCHEMA.json": _workspace_registry_schema(),
        "KNOWLEDGE_BASE_PARTITION_SCHEMA.json": _knowledge_base_partition_schema(),
        "KNOWLEDGE_BASE_ACCESS_SCOPE_MATRIX.json": _knowledge_base_access_scope_matrix(),
        "WORKSPACE_ASSET_ISOLATION_MATRIX.json": _workspace_asset_isolation_matrix(),
        "CROSS_WORKSPACE_REFERENCE_POLICY.md": _cross_workspace_reference_policy_md(),
        "WORKSPACE_PATH_BOUNDARY_POLICY.md": _workspace_path_boundary_policy_md(),
        "WORKSPACE_PARTITION_UI_HANDOFF_CONTRACT.json": _ui_handoff_contract(),
        "WORKSPACE_PARTITION_UI_HANDOFF_CONTRACT.md": _ui_handoff_contract_md(),
    }


def _build_bridge_documents() -> dict[str, Any]:
    contract = {
        "schema_version": "workspace_boundary_bridge_handoff_contract.v1",
        "contract_id": "workspace_boundary_bridge_handoff_contract",
        "status": "handoff_contract_ready",
        "campaign_5_bridge_complete": False,
        "bridge_execution_accepted": False,
        "future_bridge_action_added_to_current_allowlist": False,
        "current_gate_adds_current_allowlist_actions": False,
        "required_bridge_checks_for_future_campaign_5": [
            "workspace_id_required",
            "asset_id_required",
            "path_boundary_check_required",
            "cross_workspace_reference_must_be_explicit",
            "denied_kb_ids_must_override_allowed_scopes",
            "audit_log_required",
            "open_any_path_forbidden",
        ],
        "future_allowlist_candidates": [
            {
                "action_id": "validate-workspace-boundary",
                "registered_in_current_allowlist": False,
                "activation_campaign": "Campaign 5 Chain-Level Local Core Bridge",
            },
            {
                "action_id": "register-workspace-asset",
                "registered_in_current_allowlist": False,
                "activation_campaign": "Campaign 5 Chain-Level Local Core Bridge",
            },
            {
                "action_id": "resolve-kb-access-scope",
                "registered_in_current_allowlist": False,
                "activation_campaign": "Campaign 5 Chain-Level Local Core Bridge",
            },
        ],
        "forbidden_bridge_behaviors": [
            "arbitrary_shell_execution",
            "open_any_path",
            "absolute_path_escape",
            "parent_directory_escape",
            "implicit_cross_workspace_read",
            "future_action_enabled_before_campaign_5",
        ],
    }
    return {
        "WORKSPACE_BOUNDARY_BRIDGE_HANDOFF_CONTRACT.json": contract,
        "WORKSPACE_BOUNDARY_BRIDGE_HANDOFF_CONTRACT.md": _bridge_handoff_contract_md(contract),
    }


def _workspace_manifest_schema() -> dict[str, Any]:
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": "HeiTang Workspace Manifest",
        "type": "object",
        "additionalProperties": False,
        "required": [
            "workspace_id",
            "workspace_name",
            "schema_version",
            "workspace_root",
            "asset_roots",
            "registries",
            "path_boundary",
            "legacy_default_workspace",
        ],
        "properties": {
            "workspace_id": {"type": "string"},
            "workspace_name": {"type": "string"},
            "schema_version": {"type": "string"},
            "workspace_root": {"type": "string"},
            "asset_roots": {
                "type": "object",
                "required": ASSET_DOMAINS,
                "properties": {domain: {"type": "string"} for domain in ASSET_DOMAINS},
            },
            "registries": {
                "type": "object",
                "required": ASSET_DOMAINS,
                "properties": {
                    domain: {"type": "string", "pattern": r"^registries/.+\.jsonl?$"}
                    for domain in ASSET_DOMAINS
                },
            },
            "path_boundary": {"type": "string", "enum": ["workspace_relative_only"]},
            "legacy_default_workspace": {
                "type": "object",
                "required": ["enabled", "mode", "moves_legacy_artifacts"],
                "properties": {
                    "enabled": {"type": "boolean"},
                    "mode": {"const": "register_without_move_delete_or_rename"},
                    "moves_legacy_artifacts": {"const": False},
                },
            },
        },
    }


def _workspace_registry_schema() -> dict[str, Any]:
    entry_schema = {
        "type": "object",
        "required": [
            "asset_id",
            "workspace_id",
            "asset_type",
            "asset_path",
            "content_hash",
            "source_trace",
            "access_scope",
        ],
        "properties": {
            "asset_id": {"type": "string"},
            "workspace_id": {"type": "string"},
            "asset_type": {"type": "string", "enum": ASSET_DOMAINS},
            "asset_path": {"type": "string"},
            "content_hash": {"type": "string"},
            "source_trace": {"type": "object"},
            "access_scope": {"type": "string", "enum": ACCESS_SCOPES},
        },
    }
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": "HeiTang Workspace Registry",
        "type": "object",
        "required": ["workspace_id", "registries"],
        "properties": {
            "workspace_id": {"type": "string"},
            "registries": {
                "type": "object",
                "required": ASSET_DOMAINS,
                "properties": {
                    domain: {"type": "array", "items": entry_schema}
                    for domain in ASSET_DOMAINS
                },
            },
        },
    }


def _knowledge_base_partition_schema() -> dict[str, Any]:
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": "HeiTang Knowledge Base Partition",
        "type": "object",
        "additionalProperties": False,
        "required": [
            "kb_id",
            "workspace_id",
            "kb_type",
            "access_scope",
            "bound_source_ids",
            "allowed_workspace_ids",
            "denied_workspace_ids",
            "allowed_kb_scopes",
            "denied_kb_ids",
            "retrieval_policy",
            "audit_scope",
            "source_trace",
        ],
        "properties": {
            "kb_id": {"type": "string"},
            "workspace_id": {"type": "string"},
            "kb_type": {"type": "string", "enum": KB_TYPES},
            "access_scope": {"type": "string", "enum": ACCESS_SCOPES},
            "bound_source_ids": {"type": "array", "items": {"type": "string"}},
            "allowed_workspace_ids": {"type": "array", "items": {"type": "string"}},
            "denied_workspace_ids": {"type": "array", "items": {"type": "string"}},
            "allowed_kb_scopes": {"type": "array", "items": {"type": "string", "enum": ACCESS_SCOPES}},
            "denied_kb_ids": {"type": "array", "items": {"type": "string"}},
            "retrieval_policy": {
                "type": "object",
                "required": ["default_mode", "cross_workspace_reference_mode"],
                "properties": {
                    "default_mode": {"enum": ["local_workspace_only"]},
                    "cross_workspace_reference_mode": {"enum": ["explicit_reference_only"]},
                },
            },
            "audit_scope": {"enum": ["workspace", "workspace_and_referenced_sources"]},
            "source_trace": {"type": "object"},
        },
    }


def _knowledge_base_access_scope_matrix() -> dict[str, Any]:
    rows = [
        {
            "kb_type": kb_type,
            "default_access_scope": "workspace_private",
            "allowed_scopes": ACCESS_SCOPES,
            "denied_by_default": [
                "implicit_cross_workspace_read",
                "agent_unscoped_retrieval",
                "global_memory_read",
            ],
            "explicit_grant_required": True,
        }
        for kb_type in KB_TYPES
    ]
    return {
        "schema_version": "knowledge_base_access_scope_matrix.v1",
        "status": "foundation_ready",
        "rows": rows,
        "denied_kb_ids_override_allowed_scopes": True,
        "agent_package_required_fields": [
            "bound_knowledge_base_ids",
            "allowed_kb_scopes",
            "denied_kb_ids",
            "retrieval_policy",
            "audit_scope",
        ],
    }


def _workspace_asset_isolation_matrix() -> dict[str, Any]:
    return {
        "schema_version": "workspace_asset_isolation_matrix.v1",
        "status": "foundation_ready",
        "rows": [
            {
                "asset_type": domain,
                "owner_field": "workspace_id",
                "default_scope": "workspace_private",
                "path_root": f"workspace/{domain}",
                "allowed_cross_workspace_reference": "explicit_reference_record",
                "forbidden_misinterpretation": "asset_presence_is_global_access",
            }
            for domain in ASSET_DOMAINS
        ],
    }


def _ui_handoff_contract() -> dict[str, Any]:
    return {
        "schema_version": "workspace_partition_ui_handoff_contract.v1",
        "status": "handoff_contract_ready",
        "campaign_4_ui_complete": False,
        "campaign_4_active": False,
        "ui_industrial_workbench_complete": False,
        "display_modes": [
            "workspace_status_card",
            "asset_scope_badge",
            "kb_access_scope_detail",
            "legacy_default_workspace_notice",
            "path_boundary_error_detail",
        ],
        "forbidden_ui_claims": [
            "workspace_partition_contract_is_campaign_4_complete",
            "kb_scope_contract_is_runtime_permission_enforcement",
            "agent_binding_spec_is_agent_runtime_ready",
            "bridge_handoff_contract_is_campaign_5_complete",
        ],
    }


def _non_substitution_rules() -> dict[str, bool]:
    return {
        "pre_4_0_gate_accepts_campaign_3": False,
        "pre_4_0_gate_starts_supplement_4_0": False,
        "pre_4_0_gate_completes_supplement_4_0": False,
        "pre_4_0_gate_opens_campaign_4": False,
        "pre_4_0_gate_completes_campaign_4_ui": False,
        "pre_4_0_gate_completes_campaign_5_bridge": False,
        "pre_4_0_gate_creates_agent_runtime": False,
        "pre_4_0_gate_adds_future_bridge_allowlist_actions": False,
        "pre_4_0_gate_moves_legacy_artifacts": False,
    }


def _campaign_state_after_gate(passed: bool) -> dict[str, Any]:
    return {
        "campaign_3_supplement_3_0_accepted": True,
        "pre_4_0_workspace_partition_complete": passed,
        "workspace_manifest_ready": passed,
        "workspace_registry_ready": passed,
        "workspace_path_boundary_ready": passed,
        "kb_partition_ready": passed,
        "kb_access_scope_ready": passed,
        "legacy_default_workspace_ready": passed,
        "workspace_partition_runtime_enforcement_ready": False,
        "kb_access_scope_runtime_enforcement_ready": False,
        "campaign_3_4_0_entry_gate_passed": False,
        "campaign_3_4_0_active": False,
        "campaign_3_4_0_accepted": False,
        "campaign_3_accepted": False,
        "campaign_4_allowed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "campaign_6_active": False,
        "campaign_7_active": False,
        "campaign_8_active": False,
        "campaign_9_active": False,
        "agent_runtime_ready": False,
        "multi_agent_runtime_ready": False,
        "agent_memory_runtime_ready": False,
        "campaign_4_ui_complete": False,
        "campaign_5_bridge_complete": False,
        "bridge_execution_accepted": False,
        "future_bridge_action_added_to_current_allowlist": False,
        "full_gate_passed": False,
        "exe_packaging_done": False,
        "final_release_allowed": False,
        "next_business_item": (
            "Campaign 3 Supplement 4.0 Entry Reconciliation Gate"
            if passed
            else "Repair Pre-4.0 Workspace Partition Foundation Gate"
        ),
    }


def _validate_payloads(
    docs: dict[str, Any],
    bridge: dict[str, Any],
    path_checks: list[dict[str, str]],
) -> dict[str, Any]:
    errors: list[str] = []
    manifest_schema = docs["WORKSPACE_MANIFEST_SCHEMA.json"]
    registry_schema = docs["WORKSPACE_REGISTRY_SCHEMA.json"]
    kb_schema = docs["KNOWLEDGE_BASE_PARTITION_SCHEMA.json"]
    kb_matrix = docs["KNOWLEDGE_BASE_ACCESS_SCOPE_MATRIX.json"]
    ui_contract = docs["WORKSPACE_PARTITION_UI_HANDOFF_CONTRACT.json"]
    bridge_contract = bridge["WORKSPACE_BOUNDARY_BRIDGE_HANDOFF_CONTRACT.json"]

    if set(manifest_schema["properties"]["asset_roots"]["required"]) != set(ASSET_DOMAINS):
        errors.append("workspace_manifest_asset_roots_missing_domains")
    if set(registry_schema["properties"]["registries"]["required"]) != set(ASSET_DOMAINS):
        errors.append("workspace_registry_missing_asset_domains")
    for required in (
        "kb_type",
        "access_scope",
        "workspace_id",
        "allowed_kb_scopes",
        "denied_kb_ids",
        "retrieval_policy",
        "audit_scope",
    ):
        if required not in kb_schema["required"]:
            errors.append(f"kb_partition_missing_required_field:{required}")
    if len(kb_matrix["rows"]) != len(KB_TYPES):
        errors.append("kb_access_scope_matrix_missing_kb_types")
    if any(check["status"] != "rejected" for check in path_checks[1:]):
        errors.append("path_boundary_rejected_examples_not_all_rejected")
    if ui_contract["campaign_4_ui_complete"] is not False:
        errors.append("ui_handoff_claims_campaign_4_complete")
    if bridge_contract["campaign_5_bridge_complete"] is not False:
        errors.append("bridge_handoff_claims_campaign_5_complete")
    if bridge_contract["current_gate_adds_current_allowlist_actions"] is not False:
        errors.append("bridge_handoff_adds_current_allowlist_actions")
    return {
        "schema_version": "pre_4_0_workspace_partition_validation.v1",
        "generated_at": GENERATED_AT,
        "status": "passed" if not errors else "failed",
        "error_count": len(errors),
        "boundary_errors": errors,
        "checked_domains": ASSET_DOMAINS,
        "checked_kb_types": KB_TYPES,
        "checked_access_scopes": ACCESS_SCOPES,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "supplement_4_0_active": False,
        "not_goal_complete": True,
    }


def _write_product_outputs(repo_root: Path, docs: dict[str, Any]) -> None:
    product_root = repo_root / "docs" / "product"
    for name, payload in docs.items():
        path = product_root / name
        if isinstance(payload, dict):
            write_json(path, payload)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(payload, encoding="utf-8")


def _write_bridge_outputs(repo_root: Path, docs: dict[str, Any]) -> None:
    bridge_root = repo_root / "docs" / "bridge"
    for name, payload in docs.items():
        path = bridge_root / name
        if isinstance(payload, dict):
            write_json(path, payload)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(payload, encoding="utf-8")


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "run_manifest.v1",
        "run_id": "pre_4_0_workspace_partition",
        "type": "pre_campaign_foundation_gate",
        "scope": report["scope"],
        "status": report["status"],
        "verdict": report["verdict"],
        "integration_decision": report["integration_decision"],
        "decision_qualifier": report["decision_qualifier"],
        "generated_at": report["generated_at"],
        "required_product_outputs": report["required_product_outputs"],
        "required_bridge_outputs": report["required_bridge_outputs"],
        "validation_status": report["validation_report"]["status"],
        "campaign_state_after_gate": report["campaign_state_after_gate"],
        "non_substitution_rules": report["non_substitution_rules"],
        "next_safe_action": report["next_required_e2e_step"],
        "remaining_gap": report["remaining_gap"],
        "not_goal_complete": True,
    }


def _checkpoint(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "pre_4_0_workspace_partition_checkpoint.v1",
        "checkpoint_id": "pre_4_0_workspace_partition_foundation_gate_passed"
        if report["status"] == "passed"
        else "pre_4_0_workspace_partition_foundation_gate_failed",
        "updated_at": report["generated_at"],
        "current_item": "Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate",
        "current_status": report["status"],
        "last_successful_step": "Pre-4.0 workspace partition contracts generated and validated"
        if report["status"] == "passed"
        else "Campaign 3 Supplement 3.0 Acceptance Gate",
        "next_safe_action": report["next_required_e2e_step"],
        "blocked_future_items": [
            "Campaign 4",
            "Campaign 5",
            "Full Gate",
            "EXE",
            "Release",
        ],
        "tests_run": [],
        "tests_passed": [],
        "tests_failed": [],
        "audit_outputs": [
            "artifacts/audits/pre_4_0_workspace_partition/run_manifest.json",
            "artifacts/audits/pre_4_0_workspace_partition/validation_report.json",
            "artifacts/audits/pre_4_0_workspace_partition/checkpoint.json",
        ],
        "retry_summary": {"transient_retries": 0},
        "resume_prompt_path": "artifacts/audits/current_run/resume_prompt.md",
        "not_goal_complete": True,
    }


def _render_summary(report: dict[str, Any]) -> str:
    return "\n".join(
        [
            "# Pre-4.0 Workspace Partition Foundation Gate",
            "",
            f"- status: `{report['status']}`",
            f"- verdict: `{report['verdict']}`",
            f"- decision: `{report['integration_decision']} / {report['decision_qualifier']}`",
            "- boundary: foundation contract only; not Campaign 4 UI, not Campaign 5 Bridge, not Agent runtime",
            f"- next safe action: {report['next_required_e2e_step']}",
            "",
        ]
    )


def _render_plan_md(plan: dict[str, Any]) -> str:
    rows = "\n".join(
        f"| `{row['asset_type']}` | `{row['default_scope']}` | `{row['path_root']}` | `{row['cross_workspace_default']}` |"
        for row in plan["asset_domains"]
    )
    return f"""# Workspace Partition And Asset Isolation Plan

Status: `{plan['status']}`

This Pre-4.0 foundation contract defines workspace ownership and asset isolation
for later Skill, Agent Package, memory, and multi-agent specifications.

It does not implement Campaign 4 UI, Campaign 5 Bridge execution, Agent runtime,
or KB access-scope runtime enforcement.

| Asset Type | Default Scope | Path Root | Cross-Workspace Default |
| --- | --- | --- | --- |
{rows}

Legacy artifacts are handled by `legacy_default_workspace` compatibility:
register without moving, deleting, or renaming historical files.
"""


def _cross_workspace_reference_policy_md() -> str:
    return """# Cross-Workspace Reference Policy

Default rule: workspace assets are private to their owning `workspace_id`.

Allowed cross-workspace access requires an explicit reference record with:

- requesting_workspace_id
- source_workspace_id
- asset_id or kb_id
- access_scope
- reason
- source_trace
- audit_scope

Forbidden by default:

- implicit cross-workspace reads
- global knowledge-base search without a scope
- global Agent memory reads
- denied_kb_ids being overridden by allowed scopes
- treating imported or cloned knowledge as the original source without trace
"""


def _workspace_path_boundary_policy_md() -> str:
    return """# Workspace Path Boundary Policy

All future workspace operations must use workspace-relative asset references.

Rejected path behavior:

- `../` parent-directory escape
- absolute path escape
- repo-root output
- system path output
- home/profile path output
- open-any-path behavior
- implicit cross-workspace read

Repair rule: convert user input into an allowlisted workspace asset reference,
then preserve source trace and audit scope.
"""


def _ui_handoff_contract_md() -> str:
    return """# Workspace Partition UI Handoff Contract

This is a Campaign 4 handoff contract only.

Campaign 4 may later display workspace selection, asset scope badges, KB access
scope details, legacy default workspace notices, and path-boundary repair
messages.

Forbidden UI claims:

- workspace partition contract equals Campaign 4 completion
- KB scope contract equals runtime permission enforcement
- Agent binding spec equals Agent runtime readiness
- Bridge handoff contract equals Campaign 5 completion
"""


def _bridge_handoff_contract_md(contract: dict[str, Any]) -> str:
    actions = "\n".join(
        f"- `{item['action_id']}`: registered_in_current_allowlist = `{item['registered_in_current_allowlist']}`"
        for item in contract["future_allowlist_candidates"]
    )
    return f"""# Workspace Boundary Bridge Handoff Contract

Status: `{contract['status']}`

This is a Campaign 5 handoff contract only. It does not add current Bridge
allowlist actions and does not accept Bridge execution.

Future candidates:

{actions}

Forbidden behavior: arbitrary shell execution, open-any-path, absolute escape,
parent-directory escape, implicit cross-workspace read, and enabling future
actions before Campaign 5.
"""


def _read_json(path: Path, errors: list[str], label: str) -> dict[str, Any]:
    if not path.exists():
        errors.append(f"missing_{label}:{path}")
        return {}
    try:
        import json

        return json.loads(path.read_text(encoding="utf-8-sig"))
    except Exception as exc:  # pragma: no cover - defensive parse report
        errors.append(f"invalid_{label}:{exc}")
        return {}


def _is_relative_to(path: Path, root: Path) -> bool:
    try:
        path.resolve().relative_to(root.resolve())
        return True
    except ValueError:
        return False
