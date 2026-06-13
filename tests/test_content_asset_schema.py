import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.content_asset_schema import (
    build_content_asset_schema_library,
    validate_content_asset_schema_library,
)


def test_content_asset_schema_library_builds_original_reference_assets(tmp_path):
    output = tmp_path / "content_assets"

    result = build_content_asset_schema_library(output)

    assert result["section"] == "5.9"
    assert result["status"] == "passed"
    assert result["integration_decision"] == "reference_only"
    assert result["integration_mode"] == "content_asset_schema_reference"
    assert result["asset_type_count"] == 6
    assert set(result["asset_ids"]) == {
        "story_seed",
        "character_card",
        "scene_card",
        "shot_card",
        "continuity_note",
        "production_checkpoint",
    }
    assert result["external_project_reference"]["project_id"] == "jellyfish"
    assert result["external_project_reference"]["git_head"] == "a9678194ddf2d9be3ccbe78d4287d87d5089e123"
    assert result["external_project_reference"]["repository_cloned"] is False
    assert result["external_project_reference"]["external_code_or_content_copied"] is False
    assert result["external_project_reference"]["external_runtime_integrated"] is False
    assert result["runtime_boundary"]["short_drama_workbench_runtime"] is False
    assert result["runtime_boundary"]["video_generation_runtime"] is False
    assert result["runtime_boundary"]["asset_rendering_runtime"] is False
    assert result["ui_contract"]["artifact_management_preview_visible"] is True
    assert result["ui_contract"]["runtime_execution_action_available"] is False
    assert result["ui_contract"]["video_generation_action_available"] is False
    assert (output / "content_asset_manifest.json").exists()
    assert (output / "content_asset_cards.jsonl").exists()
    assert (output / "storyboard_metadata_schema.json").exists()
    assert (output / "CONTENT_ASSET_SCHEMA_INDEX.md").exists()


def test_content_asset_schema_validation_checks_runtime_boundaries(tmp_path):
    library = tmp_path / "library"
    build_content_asset_schema_library(library)

    result = validate_content_asset_schema_library(library)

    assert result["status"] == "passed"
    assert result["asset_type_count"] == 6
    assert result["missing_files"] == []
    assert result["card_errors"] == []
    assert result["boundary_errors"] == []
    assert result["external_code_or_content_copied"] is False
    assert result["external_runtime_integrated"] is False
    assert result["short_drama_workbench_runtime"] is False
    assert result["video_generation_runtime"] is False
    assert result["storyboard_source_trace_required"] is True
    assert result["final_target_not_downgraded"] is True
    assert result["not_goal_complete"] is True


def test_content_asset_schema_cli_builds_and_validates(tmp_path):
    library = tmp_path / "library"
    validation = tmp_path / "validation"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "build-content-asset-schema-library",
            "--output",
            str(library),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-content-asset-schema-library",
            "--library",
            str(library),
            "--output",
            str(validation),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "asset_types=6" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    report = json.loads((validation / "content_asset_validation_report.json").read_text(encoding="utf-8"))
    assert report["status"] == "passed"


def test_content_asset_schema_rejects_video_generation_runtime_claim(tmp_path):
    library = tmp_path / "library"
    build_content_asset_schema_library(library)
    manifest_path = library / "content_asset_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["runtime_boundary"]["video_generation_runtime"] = True
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    result = validate_content_asset_schema_library(library)

    assert result["status"] == "failed"
    assert "video_generation_runtime_must_be_false" in result["boundary_errors"]
