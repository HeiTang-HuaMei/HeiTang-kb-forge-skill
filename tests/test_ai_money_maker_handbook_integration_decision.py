import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "ai_money_maker_handbook_business_scenario_library"
DECISION = RUN_DIR / "ai_money_maker_handbook_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "ai_money_maker_handbook_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
SCENARIO_MANIFEST = RUN_DIR / "business_scenario_library" / "business_scenario_manifest.json"
VALIDATION = RUN_DIR / "validation" / "business_scenario_validation_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
PROJECT_REGISTRY = ROOT / "docs" / "roadmap" / "external_projects" / "external_project_registry.json"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_ai_money_maker_handbook_decision_is_limited_local_template_library():
    decision = _json(DECISION)
    scenario_manifest = _json(SCENARIO_MANIFEST)
    validation = _json(VALIDATION)

    assert decision["project_id"] == "ai_money_maker_handbook"
    assert decision["section"] == "5.8"
    assert decision["decision"] == "real_integration"
    assert decision["decision_qualifier"] == "limited_real_integration"
    assert decision["integration_mode"] == "business_scenario_template_library"
    assert decision["repository_check"]["git_ls_remote_result"] == "accessible"
    assert decision["repository_check"]["git_ls_remote_head"] == "e29581de103e0770396a2a5b389c1b41b730ba80"
    assert decision["repository_check"]["external_code_copied"] is False
    assert decision["repository_check"]["external_content_copied"] is False
    assert decision["repository_check"]["external_prompts_copied"] is False
    assert decision["runtime_contract"]["ai_money_maker_handbook_runtime_integrated"] is False
    assert decision["runtime_contract"]["local_business_scenario_template_library_implemented"] is True
    for field in [
        "trading_execution",
        "payment_processing",
        "ad_spend_or_paid_media",
        "crawler_or_scraper",
        "account_operation",
        "revenue_guarantee",
        "money_automation_ready",
        "financial_advice",
    ]:
        assert decision["runtime_contract"][field] is False
    assert scenario_manifest["status"] == "passed"
    assert scenario_manifest["scenario_count"] == 8
    assert validation["status"] == "passed"


def test_ai_money_maker_handbook_ui_status_is_truthful_and_not_executable():
    ui = _json(UI_IMPACT)

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["business_scenario_template_preview_available"] is True
    assert ui["current_ui_state"]["skill_factory_template_picker_visible"] is True
    assert ui["current_ui_state"]["core_action_available"] is False
    assert ui["current_ui_state"]["runtime_execution_action_available"] is False
    assert ui["current_ui_state"]["money_automation_action_available"] is False
    assert "ai-money-maker-handbook runtime ready" in ui["ui_must_not_show"]
    assert "money automation ready" in ui["ui_must_not_show"]
    assert "revenue guaranteed" in ui["ui_must_not_show"]
    assert "Campaign 3 accepted" in ui["ui_must_not_show"]


def test_ai_money_maker_handbook_run_is_governed_and_keeps_sequence_locked():
    run = _json(RUN_MANIFEST)
    manifest = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in manifest["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert run["status"] == "passed"
    assert run["integration_decision"] == "real_integration"
    assert run["decision_qualifier"] == "limited_real_integration"
    assert run["campaign_state_after_run"]["campaign_3_item_5_8"] == "advanced"
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == "5.9 Jellyfish"
    assert runs["ai_money_maker_handbook_business_scenario_library"]["scope"] == "SECTION_5_ITEM_5_8_AI_MONEY_MAKER_HANDBOOK"
    assert "ai_money_maker_handbook_business_scenario_library" in index
    assert "Next Section 5 item: `5.13 mattpocock/skills`" in plan
    assert "Campaign 3 accepted: `false`" in plan
    assert "Campaign 4 allowed: `false`" in plan


def test_ai_money_maker_handbook_project_registry_records_local_evidence_without_runtime_claim():
    registry = _json(PROJECT_REGISTRY)
    project = next(item for item in registry["projects"] if item["project_id"] == "ai_money_maker_handbook")

    assert project["current_repo_status"] == "real_workflow_evidence"
    assert project["implementation_mode"] == "business_scenario_template_library"
    assert "heitang_kb_forge/business_scenario_templates/builder.py" in project["current_evidence_files"]
    assert "tests/test_business_scenario_templates.py" in project["current_evidence_files"]
    assert (
        "artifacts/audits/section_5/ai_money_maker_handbook_business_scenario_library/ai_money_maker_handbook_integration_decision_report.json"
        in project["current_evidence_files"]
    )
    assert project["requires_api_key"] is False
    assert project["requires_network"] is False
    assert project["requires_external_runtime"] is False
    assert project["can_be_ready_before_v4"] is False
    assert "full Template Library UI workflow" in project["reason_not_ready_before_v4"]


def test_ai_money_maker_handbook_non_downgrade_fields_are_present():
    for payload in [_json(DECISION), _json(UI_IMPACT), _json(RUN_MANIFEST), _json(SCENARIO_MANIFEST), _json(VALIDATION)]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"] == "Process Section 5 item 5.9 Jellyfish only."
        assert payload["not_goal_complete"] is True
