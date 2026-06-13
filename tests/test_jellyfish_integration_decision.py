import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "jellyfish_content_asset_schema"
DECISION = RUN_DIR / "jellyfish_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "jellyfish_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
ASSET_MANIFEST = RUN_DIR / "content_asset_schema" / "content_asset_manifest.json"
VALIDATION = RUN_DIR / "validation" / "content_asset_validation_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
PROJECT_REGISTRY = ROOT / "docs" / "roadmap" / "external_projects" / "external_project_registry.json"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_jellyfish_decision_is_reference_only_content_asset_schema():
    decision = _json(DECISION)
    asset_manifest = _json(ASSET_MANIFEST)
    validation = _json(VALIDATION)

    assert decision["project_id"] == "jellyfish"
    assert decision["section"] == "5.9"
    assert decision["decision"] == "reference_only"
    assert decision["integration_mode"] == "content_asset_schema_reference"
    assert decision["repository_check"]["git_ls_remote_result"] == "accessible"
    assert decision["repository_check"]["git_ls_remote_head"] == "a9678194ddf2d9be3ccbe78d4287d87d5089e123"
    assert decision["repository_check"]["repository_cloned"] is False
    assert decision["repository_check"]["external_code_copied"] is False
    assert decision["repository_check"]["external_content_copied"] is False
    assert decision["runtime_contract"]["jellyfish_runtime_integrated"] is False
    assert decision["runtime_contract"]["local_content_asset_schema_reference_implemented"] is True
    for field in [
        "short_drama_workbench_runtime",
        "video_generation_runtime",
        "asset_rendering_runtime",
        "media_download_or_upload",
        "crawler_or_scraper",
        "account_operation",
    ]:
        assert decision["runtime_contract"][field] is False
    assert asset_manifest["status"] == "passed"
    assert asset_manifest["asset_type_count"] == 6
    assert validation["status"] == "passed"


def test_jellyfish_ui_status_is_truthful_and_not_executable():
    ui = _json(UI_IMPACT)

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["template_library_preview_available"] is True
    assert ui["current_ui_state"]["artifact_management_preview_available"] is True
    assert ui["current_ui_state"]["core_action_available"] is False
    assert ui["current_ui_state"]["runtime_execution_action_available"] is False
    assert ui["current_ui_state"]["video_generation_action_available"] is False
    assert ui["current_ui_state"]["short_drama_workbench_action_available"] is False
    assert "Jellyfish runtime ready" in ui["ui_must_not_show"]
    assert "video generation ready" in ui["ui_must_not_show"]
    assert "Campaign 3 accepted" in ui["ui_must_not_show"]


def test_jellyfish_run_is_governed_and_keeps_sequence_locked():
    run = _json(RUN_MANIFEST)
    manifest = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in manifest["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert run["status"] == "passed"
    assert run["integration_decision"] == "reference_only"
    assert run["campaign_state_after_run"]["campaign_3_item_5_9"] == "advanced_reference_only"
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == "5.10 story-flicks"
    assert runs["jellyfish_content_asset_schema"]["scope"] == "SECTION_5_ITEM_5_9_JELLYFISH"
    assert "jellyfish_content_asset_schema" in index
    assert "Next Section 5 item: `5.13 mattpocock/skills`" in plan
    assert "Campaign 3 accepted: `false`" in plan
    assert "Campaign 4 allowed: `false`" in plan


def test_jellyfish_project_registry_records_schema_evidence_without_runtime_claim():
    registry = _json(PROJECT_REGISTRY)
    project = next(item for item in registry["projects"] if item["project_id"] == "jellyfish")

    assert project["current_repo_status"] == "reference_schema_evidence"
    assert project["implementation_mode"] == "content_asset_schema_reference"
    assert "heitang_kb_forge/content_asset_schema/builder.py" in project["current_evidence_files"]
    assert "tests/test_content_asset_schema.py" in project["current_evidence_files"]
    assert (
        "artifacts/audits/section_5/jellyfish_content_asset_schema/jellyfish_integration_decision_report.json"
        in project["current_evidence_files"]
    )
    assert project["requires_api_key"] is False
    assert project["requires_network"] is False
    assert project["requires_external_runtime"] is False
    assert project["can_be_ready_before_v4"] is False
    assert "full Template Library / Artifact Management UI workflow" in project["reason_not_ready_before_v4"]


def test_jellyfish_non_downgrade_fields_are_present():
    for payload in [_json(DECISION), _json(UI_IMPACT), _json(RUN_MANIFEST), _json(ASSET_MANIFEST), _json(VALIDATION)]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"] == "Process Section 5 item 5.10 story-flicks only."
        assert payload["not_goal_complete"] is True
