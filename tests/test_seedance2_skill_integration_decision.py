import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "seedance2_skill_template_metadata"
DECISION = RUN_DIR / "seedance2_skill_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "seedance2_skill_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
METADATA = RUN_DIR / "template_metadata" / "video_skill_template_metadata.json"
VALIDATION = RUN_DIR / "validation" / "video_skill_template_validation_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
PROJECT_REGISTRY = ROOT / "docs" / "roadmap" / "external_projects" / "external_project_registry.json"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_seedance2_decision_is_verified_reference_metadata_only():
    decision = _json(DECISION)
    metadata = _json(METADATA)
    validation = _json(VALIDATION)

    assert decision["project_id"] == "seedance2_skill"
    assert decision["section"] == "5.11"
    assert decision["decision"] == "reference_only"
    assert decision["integration_mode"] == "verified_video_skill_template_metadata"
    assert decision["verification_state"] == "verified_source_reference_only"
    repo = decision["repository_check"]
    assert repo["git_ls_remote_result"] == "accessible"
    assert repo["git_ls_remote_head"] == "e06c7c63a766d623004a2807881c30685ce517af"
    assert repo["license_spdx"] == "MIT"
    assert repo["repository_cloned"] is False
    assert repo["external_prompt_text_copied"] is False
    assert decision["provider_api_check"]["direct_document_access_status"] == "network_timeout"
    assert decision["provider_api_check"]["exact_api_contract_verified"] is False
    assert decision["provider_api_check"]["provider_call_executed"] is False
    runtime = decision["runtime_contract"]
    assert runtime["local_template_metadata_implemented"] is True
    assert runtime["external_prompt_body_included"] is False
    assert runtime["provider_adapter_integrated"] is False
    assert runtime["api_key_collected"] is False
    assert runtime["provider_call_executed"] is False
    assert runtime["video_generation_runtime"] is False
    assert metadata["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []


def test_seedance2_ui_state_is_local_metadata_but_never_executable():
    ui = _json(UI_IMPACT)

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["template_metadata_preview_available"] is True
    assert ui["current_ui_state"]["license_visible"] is True
    assert ui["current_ui_state"]["provider_requirement_visible"] is True
    assert ui["current_ui_state"]["local_ready"] is True
    assert ui["current_ui_state"]["ready"] is False
    assert ui["current_ui_state"]["executable_action"] is False
    assert ui["current_ui_state"]["provider_config_action_available"] is False
    assert ui["current_ui_state"]["video_generation_action_available"] is False
    assert "Seedance runtime ready" in ui["ui_must_not_show"]
    assert "Generate video" in ui["ui_must_not_show"]


def test_seedance2_registry_and_campaign_sequence_advance_to_5_12():
    registry = _json(PROJECT_REGISTRY)
    project = next(
        item for item in registry["projects"] if item["project_id"] == "seedance2_skill"
    )
    run = _json(RUN_MANIFEST)
    audit = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in audit["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert project["current_repo_status"] == "reference_schema_evidence"
    assert project["implementation_mode"] == "verified_video_skill_template_metadata"
    assert "heitang_kb_forge/video_skill_template_metadata/builder.py" in project["current_evidence_files"]
    assert "tests/test_video_skill_template_metadata.py" in project["current_evidence_files"]
    assert project["requires_api_key"] is True
    assert project["requires_network"] is True
    assert project["requires_external_runtime"] is False
    assert run["integration_decision"] == "reference_only"
    assert run["campaign_state_after_run"]["campaign_3_item_5_11"] == "advanced_reference_only"
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_3_3_0_active"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == "5.12 RAG-Anything"
    assert runs["seedance2_skill_template_metadata"]["scope"] == "SECTION_5_ITEM_5_11_SEEDANCE2_SKILL"
    assert "seedance2_skill_template_metadata" in index
    assert "Next Section 5 item: `5.13 mattpocock/skills`" in plan


def test_seedance2_non_downgrade_fields_point_to_5_12():
    for payload in [_json(DECISION), _json(UI_IMPACT), _json(RUN_MANIFEST), _json(METADATA), _json(VALIDATION)]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"] == "Process Section 5 item 5.12 RAG-Anything only."
        assert payload["not_goal_complete"] is True
