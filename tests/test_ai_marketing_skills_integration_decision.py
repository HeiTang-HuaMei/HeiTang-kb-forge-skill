import json
from pathlib import Path

from tests.external_registry_helpers import load_external_capability_registry


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "ai_marketing_skills_pattern_library"
DECISION = RUN_DIR / "ai_marketing_skills_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "ai_marketing_skills_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
PATTERN_MANIFEST = RUN_DIR / "marketing_pattern_library" / "marketing_pattern_manifest.json"
VALIDATION = RUN_DIR / "validation" / "marketing_pattern_validation_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"

def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_ai_marketing_skills_decision_is_local_pattern_library_not_external_runtime():
    decision = _json(DECISION)
    pattern_manifest = _json(PATTERN_MANIFEST)
    validation = _json(VALIDATION)

    assert decision["project_id"] == "ai_marketing_skills"
    assert decision["section"] == "5.7"
    assert decision["decision"] == "real_integration"
    assert decision["integration_mode"] == "marketing_skill_pattern_library"
    assert decision["repository_check"]["git_ls_remote_result"] == "accessible"
    assert decision["repository_check"]["git_ls_remote_head"] == "a9f11007aca31cc85f231698e22b64412f847b76"
    assert decision["repository_check"]["external_code_copied"] is False
    assert decision["repository_check"]["external_prompts_copied"] is False
    assert decision["repository_check"]["external_skill_files_copied"] is False
    assert decision["runtime_contract"]["ai_marketing_skills_runtime_integrated"] is False
    assert decision["runtime_contract"]["local_marketing_pattern_library_implemented"] is True
    assert decision["runtime_contract"]["crawler_or_scraper_marketing"] is False
    assert decision["runtime_contract"]["paid_media_execution"] is False
    assert decision["runtime_contract"]["account_operation"] is False
    assert decision["runtime_contract"]["revenue_guarantee"] is False
    assert pattern_manifest["status"] == "passed"
    assert pattern_manifest["pattern_count"] == 8
    assert validation["status"] == "passed"


def test_ai_marketing_skills_ui_status_is_truthful_and_not_executable():
    ui = _json(UI_IMPACT)
    registry = load_external_capability_registry(ROOT)
    project = next(item for item in registry["projects"] if item["project_id"] == "ai_marketing_skills")

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["marketing_skill_pattern_preview_available"] is True
    assert ui["current_ui_state"]["topic_radar_future_slot_visible"] is True
    assert ui["current_ui_state"]["core_action_available"] is False
    assert ui["current_ui_state"]["runtime_execution_action_available"] is False
    assert "ai-marketing-skills runtime ready" in ui["ui_must_not_show"]
    assert "Campaign 3 accepted" in ui["ui_must_not_show"]
    assert project["contract_status"] == [
        "marketing_skill_pattern_library",
        "real_integration",
        "runtime_not_bundled",
    ]
    assert project["implemented"] is True
    assert project["ready"] is False
    assert project["local_ready"] is True
    assert project["executable_action"] is False
    assert project["ui_visibility"] == "visible_status_only"
    assert "template_library" in {page["page_id"] for page in project["related_workbench_pages"]}
    assert "skill_factory" in {page["page_id"] for page in project["related_workbench_pages"]}


def test_ai_marketing_skills_run_is_governed_and_keeps_sequence_locked():
    run = _json(RUN_MANIFEST)
    manifest = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in manifest["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert run["status"] == "passed"
    assert run["integration_decision"] == "real_integration"
    assert run["campaign_state_after_run"]["campaign_3_item_5_7"] == "advanced"
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == "5.8 ai-money-maker-handbook"
    assert runs["ai_marketing_skills_pattern_library"]["scope"] == "SECTION_5_ITEM_5_7_AI_MARKETING_SKILLS"
    assert "ai_marketing_skills_pattern_library" in index
    assert "Next Section 5 item: `5.13 mattpocock/skills`" in plan
    assert "Campaign 3 accepted: `false`" in plan
    assert "Campaign 4 allowed: `false`" in plan


def test_ai_marketing_skills_non_downgrade_fields_are_present():
    for payload in [_json(DECISION), _json(UI_IMPACT), _json(RUN_MANIFEST), _json(PATTERN_MANIFEST), _json(VALIDATION)]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"] == "Process Section 5 item 5.8 ai-money-maker-handbook only."
        assert payload["not_goal_complete"] is True
