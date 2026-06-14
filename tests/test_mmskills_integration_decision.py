import json
from pathlib import Path

from tests.external_registry_helpers import load_external_capability_registry


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "mmskills_multimodal_skill_package"
DECISION = RUN_DIR / "mmskills_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "mmskills_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
MM_MANIFEST = RUN_DIR / "multimodal_skill_package" / "multimodal_skill_manifest.json"
VALIDATION = RUN_DIR / "validation" / "multimodal_skill_validation_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"

def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_mmskills_decision_is_reference_schema_not_runtime_integration():
    decision = _json(DECISION)
    manifest = _json(MM_MANIFEST)
    validation = _json(VALIDATION)

    assert decision["project_id"] == "mmskills"
    assert decision["section"] == "5.5"
    assert decision["decision"] == "reference_only"
    assert decision["integration_mode"] == "schema_package_reference"
    assert decision["repository_check"]["git_ls_remote_result"] == "repository_not_found_or_not_accessible"
    assert decision["repository_check"]["github_api_result"] == "404_not_found"
    assert decision["repository_check"]["external_code_copied"] is False
    assert decision["runtime_contract"]["mmskills_runtime_integrated"] is False
    assert decision["runtime_contract"]["osworld_runtime_integrated"] is False
    assert decision["runtime_contract"]["branch_loaded_agent_runtime_integrated"] is False
    assert manifest["validation_status"] == "passed"
    assert manifest["source_status"] == "text_fallback"
    assert validation["status"] == "passed"


def test_mmskills_ui_status_is_truthful_and_not_executable():
    ui = _json(UI_IMPACT)
    registry = load_external_capability_registry(ROOT)
    project = next(item for item in registry["projects"] if item["project_id"] == "mmskills")

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["multimodal_skill_preview_available"] is True
    assert ui["current_ui_state"]["core_action_available"] is False
    assert ui["current_ui_state"]["runtime_execution_action_available"] is False
    assert "MMSkills runtime ready" in ui["ui_must_not_show"]
    assert project["contract_status"] == [
        "schema_package_reference",
        "reference_only",
        "runtime_not_bundled",
    ]
    assert project["implemented"] is True
    assert project["ready"] is False
    assert project["local_ready"] is True
    assert project["executable_action"] is False
    assert project["ui_visibility"] == "visible_status_only"


def test_mmskills_run_is_governed_and_keeps_sequence_locked():
    run = _json(RUN_MANIFEST)
    manifest = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in manifest["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert run["status"] == "passed"
    assert run["integration_decision"] == "reference_only"
    assert run["campaign_state_after_run"]["campaign_3_item_5_5"] == "advanced_reference_only"
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == "5.6 skill-prompt-generator"
    assert runs["mmskills_multimodal_skill_package"]["scope"] == "SECTION_5_ITEM_5_5_MMSKILLS"
    assert "mmskills_multimodal_skill_package" in index
    assert "Next Section 5 item: `5.13 mattpocock/skills`" in plan
    assert "Campaign 3 accepted: `false`" in plan


def test_mmskills_non_downgrade_fields_are_present():
    for payload in [_json(DECISION), _json(UI_IMPACT), _json(RUN_MANIFEST), _json(MM_MANIFEST), _json(VALIDATION)]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"].strip()
        assert payload["not_goal_complete"] is True
