import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "gbrain_memory_profile_kg_strengthening"
DECISION = RUN_DIR / "gbrain_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "gbrain_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
RULES = RUN_DIR / "rules" / "gbrain_strengthening_manifest.json"
VALIDATION = RUN_DIR / "validation" / "gbrain_strengthening_validation_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
MATRIX = ROOT / "docs" / "governance" / "TARGET_ACCEPTANCE_MATRIX.md"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_gbrain_decision_is_strengthening_not_peer_runtime():
    decision = _json(DECISION)
    rules = _json(RULES)
    validation = _json(VALIDATION)

    assert decision["project_id"] == "gbrain"
    assert decision["section"] == "5.S1"
    assert decision["decision"] == "needs_strengthening"
    assert decision["integration_mode"] == "memory_profile_kg_strengthening_record"
    assert decision["verification_state"] == "verified_source_strengthening_record_only"
    repo = decision["repository_check"]
    assert repo["git_ls_remote_result"] == "accessible"
    assert repo["git_ls_remote_head"] == "4ee530f3c545b880cecc47c4f877e0ed014896b4"
    assert repo["default_branch"] == "master"
    assert repo["license_spdx"] == "MIT"
    assert repo["repository_cloned"] is False
    assert repo["external_code_copied"] is False
    assert repo["external_skill_files_copied"] is False
    runtime = decision["runtime_contract"]
    assert runtime["local_strengthening_rules_implemented"] is True
    assert runtime["gbrain_runtime_integrated"] is False
    assert runtime["bun_dependency_installed"] is False
    assert runtime["pglite_or_postgres_configured"] is False
    assert runtime["pgvector_required"] is False
    assert runtime["mcp_connector_enabled"] is False
    assert runtime["agent_created_or_bound"] is False
    assert runtime["campaign_3_3_0_implemented"] is False
    assert runtime["campaign_3_4_0_implemented"] is False
    assert rules["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []


def test_gbrain_ui_state_is_status_only_and_not_executable():
    ui = _json(UI_IMPACT)

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["memory_profile_strengthening_visible"] is True
    assert ui["current_ui_state"]["kg_gap_rules_visible"] is True
    assert ui["current_ui_state"]["local_ready"] is True
    assert ui["current_ui_state"]["ready"] is False
    assert ui["current_ui_state"]["executable_action"] is False
    assert ui["current_ui_state"]["gbrain_runtime_action_available"] is False
    assert ui["current_ui_state"]["mcp_connector_action_available"] is False
    assert ui["current_ui_state"]["database_setup_action_available"] is False
    assert "GBrain runtime ready" in ui["ui_must_not_show"]
    assert "Connect GBrain MCP" in ui["ui_must_not_show"]
    assert "Create Agent from GBrain" in ui["ui_must_not_show"]


def test_gbrain_sequence_advances_only_to_5_s2():
    run = _json(RUN_MANIFEST)
    audit = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in audit["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    matrix = MATRIX.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert run["integration_decision"] == "needs_strengthening"
    assert run["campaign_state_after_run"]["campaign_3_item_5_S1"] == (
        "advanced_strengthening_record_only"
    )
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_3_3_0_active"] is False
    assert run["campaign_state_after_run"]["campaign_3_4_0_active"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == "5.S2 Horizon"
    assert runs["gbrain_memory_profile_kg_strengthening"]["scope"] == "SECTION_5_STRENGTHENING_5_S1_GBRAIN"
    assert "gbrain_memory_profile_kg_strengthening" in index
    assert "Next Section 5 item: `5.S2 Horizon`" in plan
    assert "Section 5 strengthening item 5.S2 Horizon" in matrix


def test_gbrain_non_downgrade_fields_point_to_5_s2():
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
            "Process Section 5 strengthening item 5.S2 Horizon only."
        )
        assert payload["not_goal_complete"] is True
