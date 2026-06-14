from heitang_kb_forge.campaign_3_closure.review_handoff import _external_project_rows
from heitang_kb_forge.content_asset_schema import (
    build_content_asset_schema_library,
    validate_content_asset_schema_library,
)


def _project() -> dict:
    return next(row for row in _external_project_rows() if row["project_name"] == "Jellyfish")


def test_jellyfish_decision_is_reference_only_content_asset_schema(tmp_path):
    output = tmp_path / "content_assets"
    result = build_content_asset_schema_library(output)
    validation = validate_content_asset_schema_library(output)

    assert result["section"] == "5.9"
    assert result["integration_decision"] == "reference_only"
    assert result["integration_mode"] == "content_asset_schema_reference"
    assert result["asset_type_count"] == 6
    assert result["external_project_reference"]["project_id"] == "jellyfish"
    assert result["external_project_reference"]["repository_cloned"] is False
    assert result["external_project_reference"]["external_code_or_content_copied"] is False
    assert result["external_project_reference"]["external_runtime_integrated"] is False
    for field in [
        "short_drama_workbench_runtime",
        "video_generation_runtime",
        "asset_rendering_runtime",
        "media_download_or_upload",
        "crawler_or_scraper",
        "account_operation",
    ]:
        assert result["runtime_boundary"][field] is False
    assert validation["status"] == "passed"


def test_jellyfish_ui_status_is_truthful_and_not_executable(tmp_path):
    result = build_content_asset_schema_library(tmp_path / "content_assets")

    assert result["ui_contract"]["template_library_preview_visible"] is True
    assert result["ui_contract"]["artifact_management_preview_visible"] is True
    assert result["ui_contract"]["runtime_execution_action_available"] is False
    assert result["ui_contract"]["video_generation_action_available"] is False
    assert result["ui_contract"]["short_drama_workbench_action_available"] is False


def test_jellyfish_public_project_row_preserves_reference_boundary():
    project = _project()

    assert project["integration_status"] == "reference_only"
    assert project["implementation_mode"] == "not_integrated"
    assert project["runtime_dependency_added"] is False
    assert "Content asset schema" in project["capability_domain"]
    assert "no media runtime" in project["current_boundary"]


def test_jellyfish_non_downgrade_fields_are_present(tmp_path):
    result = build_content_asset_schema_library(tmp_path / "content_assets")
    validation = validate_content_asset_schema_library(tmp_path / "content_assets")

    for payload in [result, validation]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["not_goal_complete"] is True
