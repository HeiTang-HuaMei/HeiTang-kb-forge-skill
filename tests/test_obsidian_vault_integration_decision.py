import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "obsidian_vault_strengthening"
DECISION = RUN_DIR / "obsidian_vault_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "obsidian_vault_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
RULES = RUN_DIR / "rules" / "obsidian_vault_strengthening_manifest.json"
VALIDATION = RUN_DIR / "validation" / "obsidian_vault_validation_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
MATRIX = ROOT / "docs" / "governance" / "TARGET_ACCEPTANCE_MATRIX.md"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_obsidian_vault_decision_is_local_vault_adapter_not_obsidian_runtime():
    decision = _json(DECISION)
    rules = _json(RULES)
    validation = _json(VALIDATION)

    assert decision["project_id"] == "obsidian_compatible_vault"
    assert decision["section"] == "5.S3"
    assert decision["decision"] == "real_integration"
    assert decision["decision_qualifier"] == "local_vault_adapter_only"
    assert decision["integration_mode"] == "local_markdown_vault_adapter_strengthening"
    assert decision["verification_state"] == "local_adapter_strengthening_record_only"
    runtime = decision["runtime_contract"]
    assert runtime["local_vault_adapter_implemented"] is True
    assert runtime["markdown_folder_import"] is True
    assert runtime["markdown_folder_export"] is True
    assert runtime["frontmatter_support"] is True
    assert runtime["wikilink_support"] is True
    assert runtime["backlink_map_support"] is True
    assert runtime["folder_structure_support"] is True
    assert runtime["obsidian_runtime_integrated"] is False
    assert runtime["obsidian_plugin_required"] is False
    assert runtime["obsidian_app_launched"] is False
    assert runtime["obsidian_sync_required"] is False
    assert runtime["database_required"] is False
    assert runtime["network_required"] is False
    assert runtime["external_source_ingestion_implemented"] is False
    assert runtime["campaign_3_3_0_implemented"] is False
    assert runtime["campaign_3_4_0_implemented"] is False
    assert rules["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []
    assert validation["note_count"] == 2
    assert validation["folder_count"] == 2
    assert validation["backlink_edge_count"] == 2


def test_obsidian_vault_ui_state_is_status_only_and_not_executable():
    ui = _json(UI_IMPACT)

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["local_vault_import_visible"] is True
    assert ui["current_ui_state"]["markdown_folder_import_visible"] is True
    assert ui["current_ui_state"]["obsidian_compatible_export_visible"] is True
    assert ui["current_ui_state"]["frontmatter_preview_visible"] is True
    assert ui["current_ui_state"]["backlink_map_preview_visible"] is True
    assert ui["current_ui_state"]["folder_structure_preview_visible"] is True
    assert ui["current_ui_state"]["local_ready"] is True
    assert ui["current_ui_state"]["ready"] is False
    assert ui["current_ui_state"]["executable_action"] is False
    assert ui["current_ui_state"]["obsidian_runtime_action_available"] is False
    assert ui["current_ui_state"]["obsidian_plugin_action_available"] is False
    assert ui["current_ui_state"]["sync_service_action_available"] is False
    assert ui["current_ui_state"]["campaign_4_workflow_accepted"] is False
    assert "Obsidian runtime ready" in ui["ui_must_not_show"]
    assert "Install or run Obsidian plugin" in ui["ui_must_not_show"]
    assert "Start Obsidian sync" in ui["ui_must_not_show"]
    assert "Campaign 3.0 active" in ui["ui_must_not_show"]


def test_obsidian_vault_sequence_advances_only_to_closure_gate():
    run = _json(RUN_MANIFEST)
    audit = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in audit["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    matrix = MATRIX.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert run["integration_decision"] == "real_integration"
    assert run["decision_qualifier"] == "local_vault_adapter_only"
    assert run["campaign_state_after_run"]["campaign_3_item_5_S3"] == (
        "advanced_local_vault_adapter_only"
    )
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_3_3_0_active"] is False
    assert run["campaign_state_after_run"]["campaign_3_4_0_active"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == (
        "Campaign 3 Supplement 2.0 closure gate"
    )
    assert runs["obsidian_vault_strengthening"]["scope"] == (
        "SECTION_5_STRENGTHENING_5_S3_OBSIDIAN_COMPATIBLE_VAULT"
    )
    assert runs["obsidian_vault_strengthening"]["decision_qualifier"] == (
        "local_vault_adapter_only"
    )
    assert "obsidian_vault_strengthening" in index
    assert "Next Section 5 item: `Campaign 3 Supplement 2.0 closure gate`" in plan
    assert "Campaign 3 Supplement 2.0 closure gate" in matrix


def test_obsidian_vault_non_downgrade_fields_point_to_closure_gate():
    for payload in [
        _json(DECISION),
        _json(UI_IMPACT),
        _json(RUN_MANIFEST),
        _json(RULES),
        _json(VALIDATION),
    ]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"] == (
            "Run Campaign 3 Supplement 2.0 closure gate only."
        )
        assert payload["not_goal_complete"] is True
