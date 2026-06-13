import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "story_flicks_video_pipeline_schema"
DECISION = RUN_DIR / "story_flicks_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "story_flicks_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
PIPELINE_MANIFEST = RUN_DIR / "video_pipeline_schema" / "video_pipeline_manifest.json"
VALIDATION = RUN_DIR / "validation" / "video_pipeline_validation_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
PROJECT_REGISTRY = ROOT / "docs" / "roadmap" / "external_projects" / "external_project_registry.json"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_story_flicks_decision_is_reference_only_video_pipeline_schema():
    decision = _json(DECISION)
    pipeline_manifest = _json(PIPELINE_MANIFEST)
    validation = _json(VALIDATION)

    assert decision["project_id"] == "story_flicks"
    assert decision["section"] == "5.10"
    assert decision["decision"] == "reference_only"
    assert decision["integration_mode"] == "aigc_video_pipeline_schema_reference"
    assert decision["repository_check"]["git_ls_remote_result"] == "accessible"
    assert decision["repository_check"]["git_ls_remote_head"] == "4f208380150f9c066867360d7ce760cc3e3ba47e"
    assert decision["repository_check"]["repository_cloned"] is False
    assert decision["repository_check"]["external_code_copied"] is False
    assert decision["repository_check"]["external_content_copied"] is False
    assert decision["runtime_contract"]["story_flicks_runtime_integrated"] is False
    assert decision["runtime_contract"]["local_video_pipeline_schema_reference_implemented"] is True
    for field in [
        "story_to_video_runtime",
        "image_generation_runtime",
        "video_generation_runtime",
        "audio_generation_runtime",
        "voice_cloning_runtime",
        "media_rendering_runtime",
        "media_download_or_upload",
        "provider_execution",
        "account_operation",
    ]:
        assert decision["runtime_contract"][field] is False
    assert pipeline_manifest["status"] == "passed"
    assert pipeline_manifest["stage_count"] == 7
    assert validation["status"] == "passed"


def test_story_flicks_ui_status_is_truthful_and_not_executable():
    ui = _json(UI_IMPACT)

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["pipeline_stage_preview_available"] is True
    assert ui["current_ui_state"]["core_action_available"] is False
    assert ui["current_ui_state"]["runtime_execution_action_available"] is False
    assert ui["current_ui_state"]["story_to_video_action_available"] is False
    assert ui["current_ui_state"]["video_generation_action_available"] is False
    assert ui["current_ui_state"]["render_action_available"] is False
    assert "story-flicks runtime ready" in ui["ui_must_not_show"]
    assert "story-to-video ready" in ui["ui_must_not_show"]
    assert "Campaign 3 accepted" in ui["ui_must_not_show"]


def test_story_flicks_run_is_governed_and_keeps_sequence_locked():
    run = _json(RUN_MANIFEST)
    manifest = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in manifest["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert run["status"] == "passed"
    assert run["integration_decision"] == "reference_only"
    assert run["campaign_state_after_run"]["campaign_3_item_5_10"] == "advanced_reference_only"
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == "5.11 seedance2-skill"
    assert runs["story_flicks_video_pipeline_schema"]["scope"] == "SECTION_5_ITEM_5_10_STORY_FLICKS"
    assert "story_flicks_video_pipeline_schema" in index
    assert "Next Section 5 item: `5.13 mattpocock/skills`" in plan
    assert "Campaign 3 accepted: `false`" in plan
    assert "Campaign 4 allowed: `false`" in plan


def test_story_flicks_project_registry_records_schema_evidence_without_runtime_claim():
    registry = _json(PROJECT_REGISTRY)
    project = next(item for item in registry["projects"] if item["project_id"] == "story_flicks")

    assert project["current_repo_status"] == "reference_schema_evidence"
    assert project["implementation_mode"] == "aigc_video_pipeline_schema_reference"
    assert "heitang_kb_forge/video_pipeline_schema/builder.py" in project["current_evidence_files"]
    assert "tests/test_video_pipeline_schema.py" in project["current_evidence_files"]
    assert (
        "artifacts/audits/section_5/story_flicks_video_pipeline_schema/story_flicks_integration_decision_report.json"
        in project["current_evidence_files"]
    )
    assert project["requires_api_key"] is False
    assert project["requires_network"] is False
    assert project["requires_external_runtime"] is False
    assert project["can_be_ready_before_v4"] is False
    assert "full Template Library / Artifact Management / Document Generation UI workflow" in project["reason_not_ready_before_v4"]


def test_story_flicks_non_downgrade_fields_are_present():
    for payload in [_json(DECISION), _json(UI_IMPACT), _json(RUN_MANIFEST), _json(PIPELINE_MANIFEST), _json(VALIDATION)]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"] == "Process Section 5 item 5.11 seedance2-skill only."
        assert payload["not_goal_complete"] is True
