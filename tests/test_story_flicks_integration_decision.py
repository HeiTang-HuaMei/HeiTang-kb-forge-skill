from heitang_kb_forge.campaign_3_closure.review_handoff import _external_project_rows
from heitang_kb_forge.video_pipeline_schema import (
    build_video_pipeline_schema_library,
    validate_video_pipeline_schema_library,
)


def _project() -> dict:
    return next(row for row in _external_project_rows() if row["project_name"] == "story-flicks")


def test_story_flicks_decision_is_reference_only_video_pipeline_schema(tmp_path):
    output = tmp_path / "video_pipeline"
    result = build_video_pipeline_schema_library(output)
    validation = validate_video_pipeline_schema_library(output)

    assert result["section"] == "5.10"
    assert result["integration_decision"] == "reference_only"
    assert result["integration_mode"] == "aigc_video_pipeline_schema_reference"
    assert result["stage_count"] == 7
    assert result["external_project_reference"]["project_id"] == "story_flicks"
    assert result["external_project_reference"]["repository_cloned"] is False
    assert result["external_project_reference"]["external_code_or_content_copied"] is False
    assert result["external_project_reference"]["external_runtime_integrated"] is False
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
        assert result["runtime_boundary"][field] is False
    assert validation["status"] == "passed"


def test_story_flicks_ui_status_is_truthful_and_not_executable(tmp_path):
    result = build_video_pipeline_schema_library(tmp_path / "video_pipeline")

    assert result["ui_contract"]["pipeline_stage_preview_visible"] is True
    assert result["ui_contract"]["runtime_execution_action_available"] is False
    assert result["ui_contract"]["video_generation_action_available"] is False
    assert result["ui_contract"]["render_action_available"] is False


def test_story_flicks_public_project_row_preserves_reference_boundary():
    project = _project()

    assert project["integration_status"] == "reference_only"
    assert project["implementation_mode"] == "not_integrated"
    assert project["runtime_dependency_added"] is False
    assert "AIGC video pipeline schema" in project["capability_domain"]
    assert "no provider execution" in project["current_boundary"]


def test_story_flicks_non_downgrade_fields_are_present(tmp_path):
    result = build_video_pipeline_schema_library(tmp_path / "video_pipeline")
    validation = validate_video_pipeline_schema_library(tmp_path / "video_pipeline")

    for payload in [result, validation]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["not_goal_complete"] is True
