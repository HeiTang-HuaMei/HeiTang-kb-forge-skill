import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "horizon_topic_intake_strengthening"
DECISION = RUN_DIR / "horizon_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "horizon_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
RULES = RUN_DIR / "rules" / "horizon_strengthening_manifest.json"
VALIDATION = RUN_DIR / "validation" / "horizon_strengthening_validation_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
MATRIX = ROOT / "docs" / "governance" / "TARGET_ACCEPTANCE_MATRIX.md"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_horizon_decision_is_topic_intake_schema_not_runtime():
    decision = _json(DECISION)
    rules = _json(RULES)
    validation = _json(VALIDATION)

    assert decision["project_id"] == "horizon"
    assert decision["section"] == "5.S2"
    assert decision["decision"] == "real_integration"
    assert decision["decision_qualifier"] == "topic_intake_pipeline_schema_only"
    assert decision["integration_mode"] == "topic_intake_pipeline_schema_strengthening"
    assert decision["verification_state"] == "verified_source_strengthening_record_only"
    repo = decision["repository_check"]
    assert repo["git_ls_remote_result"] == "accessible"
    assert repo["git_ls_remote_head"] == "7e0ffbbd069765b77af053e73ccc0cd6ccc2456f"
    assert repo["default_branch"] == "main"
    assert repo["license_spdx"] == "MIT"
    assert repo["repository_cloned"] is False
    assert repo["external_code_copied"] is False
    assert repo["external_workflow_copied"] is False
    runtime = decision["runtime_contract"]
    assert runtime["local_topic_intake_schema_implemented"] is True
    assert runtime["horizon_runtime_integrated"] is False
    assert runtime["crawler_or_scraper_integrated"] is False
    assert runtime["scheduled_fetcher_enabled"] is False
    assert runtime["api_key_required"] is False
    assert runtime["delivery_channel_enabled"] is False
    assert runtime["mcp_connector_enabled"] is False
    assert runtime["external_source_ingestion_implemented"] is False
    assert runtime["campaign_3_3_0_implemented"] is False
    assert runtime["campaign_3_4_0_implemented"] is False
    assert rules["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []


def test_horizon_ui_state_is_status_only_and_not_executable():
    ui = _json(UI_IMPACT)

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["topic_radar_visible"] is True
    assert ui["current_ui_state"]["information_intake_visible"] is True
    assert ui["current_ui_state"]["daily_briefing_preview_visible"] is True
    assert ui["current_ui_state"]["content_candidate_queue_visible"] is True
    assert ui["current_ui_state"]["local_ready"] is True
    assert ui["current_ui_state"]["ready"] is False
    assert ui["current_ui_state"]["executable_action"] is False
    assert ui["current_ui_state"]["horizon_runtime_action_available"] is False
    assert ui["current_ui_state"]["crawler_action_available"] is False
    assert ui["current_ui_state"]["scheduler_action_available"] is False
    assert ui["current_ui_state"]["delivery_action_available"] is False
    assert "Horizon runtime ready" in ui["ui_must_not_show"]
    assert "Start Horizon crawler" in ui["ui_must_not_show"]
    assert "Enable daily scheduled fetch" in ui["ui_must_not_show"]
    assert "Campaign 3.0 active" in ui["ui_must_not_show"]


def test_horizon_sequence_advances_only_to_5_s3():
    run = _json(RUN_MANIFEST)
    audit = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in audit["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    matrix = MATRIX.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert run["integration_decision"] == "real_integration"
    assert run["decision_qualifier"] == "topic_intake_pipeline_schema_only"
    assert run["campaign_state_after_run"]["campaign_3_item_5_S2"] == (
        "advanced_topic_intake_schema_only"
    )
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_3_3_0_active"] is False
    assert run["campaign_state_after_run"]["campaign_3_4_0_active"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == (
        "5.S3 Obsidian-compatible Vault"
    )
    assert runs["horizon_topic_intake_strengthening"]["scope"] == (
        "SECTION_5_STRENGTHENING_5_S2_HORIZON"
    )
    assert "horizon_topic_intake_strengthening" in index
    assert "Next Section 5 item: `5.S3 Obsidian-compatible Vault`" in plan
    assert "5.S3 Obsidian-compatible Vault" in matrix


def test_horizon_non_downgrade_fields_point_to_5_s3():
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
            "Process Section 5 strengthening item 5.S3 Obsidian-compatible Vault only."
        )
        assert payload["not_goal_complete"] is True
