import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "skill_prompt_generator_prompt_asset_library"
DECISION = RUN_DIR / "skill_prompt_generator_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "skill_prompt_generator_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
PROMPT_MANIFEST = RUN_DIR / "prompt_asset_library" / "prompt_asset_manifest.json"
VALIDATION = RUN_DIR / "validation" / "prompt_asset_validation_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
UI_REGISTRY = (
    ROOT.parent
    / "kb-forge-skill-ui"
    / "web"
    / "workbench"
    / "flutter_app"
    / "assets"
    / "external"
    / "external_capability_registry.json"
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_skill_prompt_generator_decision_is_local_enhancer_not_external_runtime():
    decision = _json(DECISION)
    prompt_manifest = _json(PROMPT_MANIFEST)
    validation = _json(VALIDATION)

    assert decision["project_id"] == "skill_prompt_generator"
    assert decision["section"] == "5.6"
    assert decision["decision"] == "real_integration"
    assert decision["integration_mode"] == "prompt_asset_library_enhancer"
    assert decision["repository_check"]["git_ls_remote_result"] == "accessible"
    assert decision["repository_check"]["github_api_result"] == "accessible"
    assert decision["repository_check"]["license_gate"] == "pending_no_license_field_in_github_api"
    assert decision["repository_check"]["external_code_copied"] is False
    assert decision["repository_check"]["external_prompts_copied"] is False
    assert decision["runtime_contract"]["skill_prompt_generator_runtime_integrated"] is False
    assert decision["runtime_contract"]["local_prompt_asset_library_implemented"] is True
    assert decision["runtime_contract"]["p2_2_skill_factory_replaced"] is False
    assert prompt_manifest["status"] == "passed"
    assert prompt_manifest["prompt_card_count"] == 3
    assert validation["status"] == "passed"


def test_skill_prompt_generator_ui_status_is_truthful_and_not_executable():
    ui = _json(UI_IMPACT)
    registry = _json(UI_REGISTRY)
    project = next(item for item in registry["projects"] if item["project_id"] == "skill_prompt_generator")

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["prompt_asset_preview_available"] is True
    assert ui["current_ui_state"]["core_action_available"] is False
    assert ui["current_ui_state"]["runtime_execution_action_available"] is False
    assert "skill-prompt-generator runtime ready" in ui["ui_must_not_show"]
    assert project["contract_status"] == [
        "prompt_asset_library_enhancer",
        "real_integration",
        "runtime_not_bundled",
        "license_gate_pending",
    ]
    assert project["implemented"] is True
    assert project["ready"] is False
    assert project["local_ready"] is True
    assert project["executable_action"] is False
    assert project["ui_visibility"] == "visible_status_only"


def test_skill_prompt_generator_run_is_governed_and_keeps_sequence_locked():
    run = _json(RUN_MANIFEST)
    manifest = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in manifest["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert run["status"] == "passed"
    assert run["integration_decision"] == "real_integration"
    assert run["campaign_state_after_run"]["campaign_3_item_5_6"] == "advanced"
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == "5.7 ai-marketing-skills"
    assert runs["skill_prompt_generator_prompt_asset_library"]["scope"] == "SECTION_5_ITEM_5_6_SKILL_PROMPT_GENERATOR"
    assert "skill_prompt_generator_prompt_asset_library" in index
    assert "Next Section 5 item: `5.13 mattpocock/skills`" in plan
    assert "Campaign 3 item 5.7 advanced: `true`" in plan
    assert "Campaign 3 accepted: `false`" in plan


def test_skill_prompt_generator_non_downgrade_fields_are_present():
    for payload in [_json(DECISION), _json(UI_IMPACT), _json(RUN_MANIFEST), _json(PROMPT_MANIFEST), _json(VALIDATION)]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"].strip()
        assert payload["not_goal_complete"] is True
