import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli_runtime import app
from heitang_kb_forge.pre_4_0_workspace_partition import (
    ASSET_DOMAINS,
    build_pre_4_0_workspace_partition_foundation_gate,
    evaluate_workspace_path_candidate,
    validate_pre_4_0_workspace_partition_foundation_gate,
    write_pre_4_0_workspace_partition_foundation_gate,
)


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "pre_4_0_workspace_partition"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_builds_workspace_partition_contract_with_required_asset_domains():
    report = build_pre_4_0_workspace_partition_foundation_gate(ROOT)
    docs = report["product_documents"]
    manifest_schema = docs["WORKSPACE_MANIFEST_SCHEMA.json"]
    registry_schema = docs["WORKSPACE_REGISTRY_SCHEMA.json"]

    assert report["status"] == "passed"
    assert report["verdict"] == "accepted_for_campaign_3_supplement_4_0_entry_gate"
    assert report["integration_decision"] == "foundation_contract"
    assert report["decision_qualifier"] == "workspace_partition_kb_access_scope_foundation_only"
    assert set(manifest_schema["properties"]["asset_roots"]["required"]) == set(ASSET_DOMAINS)
    assert set(registry_schema["properties"]["registries"]["required"]) == set(ASSET_DOMAINS)
    for domain in [
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
    ]:
        assert domain in report["asset_domains"]


def test_knowledge_base_partition_schema_covers_access_scope_and_agent_binding_fields():
    report = build_pre_4_0_workspace_partition_foundation_gate(ROOT)
    schema = report["product_documents"]["KNOWLEDGE_BASE_PARTITION_SCHEMA.json"]
    matrix = report["product_documents"]["KNOWLEDGE_BASE_ACCESS_SCOPE_MATRIX.json"]

    for field in [
        "kb_type",
        "access_scope",
        "workspace_id",
        "allowed_kb_scopes",
        "denied_kb_ids",
        "retrieval_policy",
        "audit_scope",
        "source_trace",
    ]:
        assert field in schema["required"]
    assert "workspace_private" in schema["properties"]["access_scope"]["enum"]
    assert "agent_bound" in schema["properties"]["kb_type"]["enum"]
    assert matrix["denied_kb_ids_override_allowed_scopes"] is True
    assert matrix["agent_package_required_fields"] == [
        "bound_knowledge_base_ids",
        "allowed_kb_scopes",
        "denied_kb_ids",
        "retrieval_policy",
        "audit_scope",
    ]


def test_workspace_path_boundary_rejects_escape_and_open_any_path_cases():
    rejected = [
        "../outside.pdf",
        "C:/Windows/system32/config",
        "C:/Program Files/tool/bin.exe",
        "C:/Users/Administrator/Desktop/source.pdf",
        "/absolute/output",
        "repo/root-output.json",
        "open-any-path",
    ]

    assert evaluate_workspace_path_candidate("sources/input.pdf")["status"] == "accepted"
    for candidate in rejected:
        result = evaluate_workspace_path_candidate(candidate)
        assert result["status"] == "rejected"
        assert result["repair_suggestion"]


def test_gate_preserves_legacy_default_workspace_without_moving_artifacts():
    report = build_pre_4_0_workspace_partition_foundation_gate(ROOT)
    legacy = report["product_documents"]["WORKSPACE_PARTITION_AND_ASSET_ISOLATION_PLAN.json"][
        "legacy_default_workspace"
    ]

    assert legacy["workspace_id"] == "legacy_default_workspace"
    assert legacy["compatibility_mode"] == "register_without_move_delete_or_rename"
    assert legacy["moves_legacy_artifacts"] is False
    assert legacy["deletes_legacy_artifacts"] is False
    assert legacy["renames_legacy_artifacts"] is False


def test_handoff_contracts_do_not_claim_campaign_4_or_5_completion():
    report = build_pre_4_0_workspace_partition_foundation_gate(ROOT)
    ui = report["product_documents"]["WORKSPACE_PARTITION_UI_HANDOFF_CONTRACT.json"]
    bridge = report["bridge_documents"]["WORKSPACE_BOUNDARY_BRIDGE_HANDOFF_CONTRACT.json"]
    state = report["campaign_state_after_gate"]

    assert ui["campaign_4_ui_complete"] is False
    assert ui["campaign_4_active"] is False
    assert ui["ui_industrial_workbench_complete"] is False
    assert bridge["campaign_5_bridge_complete"] is False
    assert bridge["bridge_execution_accepted"] is False
    assert bridge["future_bridge_action_added_to_current_allowlist"] is False
    assert bridge["current_gate_adds_current_allowlist_actions"] is False
    assert all(
        item["registered_in_current_allowlist"] is False
        for item in bridge["future_allowlist_candidates"]
    )
    assert state["pre_4_0_workspace_partition_complete"] is True
    assert state["workspace_manifest_ready"] is True
    assert state["kb_access_scope_ready"] is True
    assert state["campaign_3_4_0_active"] is False
    assert state["campaign_4_active"] is False
    assert state["campaign_5_active"] is False
    assert state["agent_runtime_ready"] is False


def test_cli_build_and_validate_write_required_outputs(tmp_path):
    audit = tmp_path / "audit"
    build = CliRunner().invoke(
        app,
        [
            "build-pre-4-0-workspace-partition-foundation-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(audit),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "status=passed" in build.output
    assert _json(audit / "run_manifest.json")["status"] == "passed"
    assert _json(audit / "checkpoint.json")["checkpoint_id"] == (
        "pre_4_0_workspace_partition_foundation_gate_passed"
    )
    assert (ROOT / "docs" / "product" / "WORKSPACE_MANIFEST_SCHEMA.json").exists()
    assert (ROOT / "docs" / "bridge" / "WORKSPACE_BOUNDARY_BRIDGE_HANDOFF_CONTRACT.json").exists()

    validate = CliRunner().invoke(
        app,
        [
            "validate-pre-4-0-workspace-partition-foundation-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(audit),
        ],
    )

    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    assert _json(audit / "validation_report.json")["status"] == "passed"


def test_active_audit_outputs_validate_when_present():
    if not AUDIT_DIR.exists():
        return

    validation = validate_pre_4_0_workspace_partition_foundation_gate(ROOT, AUDIT_DIR)

    assert validation["status"] == "passed"
    assert validation["campaign_4_active"] is False
    assert validation["campaign_5_active"] is False


def test_write_function_returns_passed_and_never_marks_final_goal_complete(tmp_path):
    output = tmp_path / "pre_4_0"
    report = write_pre_4_0_workspace_partition_foundation_gate(ROOT, output)

    assert report["status"] == "passed"
    assert report["not_goal_complete"] is True
    assert report["campaign_state_after_gate"]["final_release_allowed"] is False
    assert report["next_required_e2e_step"] == (
        "Run Campaign 3 Supplement 4.0 Entry Reconciliation Gate only."
    )
    assert (output / "run_summary.md").exists()
