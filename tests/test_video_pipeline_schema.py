import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.video_pipeline_schema import (
    build_video_pipeline_schema_library,
    validate_video_pipeline_schema_library,
)


def test_video_pipeline_schema_builds_original_reference_contracts(tmp_path):
    output = tmp_path / "video_pipeline"

    result = build_video_pipeline_schema_library(output)

    assert result["section"] == "5.10"
    assert result["status"] == "passed"
    assert result["integration_decision"] == "reference_only"
    assert result["integration_mode"] == "aigc_video_pipeline_schema_reference"
    assert result["stage_count"] == 7
    assert result["stage_ids"] == [
        "source_brief",
        "script_plan",
        "storyboard_plan",
        "visual_asset_plan",
        "audio_plan",
        "subtitle_timeline",
        "delivery_checkpoint",
    ]
    assert result["external_project_reference"]["project_id"] == "story_flicks"
    assert result["external_project_reference"]["git_head"] == "4f208380150f9c066867360d7ce760cc3e3ba47e"
    assert result["external_project_reference"]["repository_cloned"] is False
    assert result["external_project_reference"]["external_code_or_content_copied"] is False
    assert result["external_project_reference"]["external_runtime_integrated"] is False
    assert result["runtime_boundary"]["story_to_video_runtime"] is False
    assert result["runtime_boundary"]["image_generation_runtime"] is False
    assert result["runtime_boundary"]["video_generation_runtime"] is False
    assert result["runtime_boundary"]["audio_generation_runtime"] is False
    assert result["runtime_boundary"]["media_rendering_runtime"] is False
    assert result["runtime_boundary"]["provider_execution"] is False
    assert result["ui_contract"]["pipeline_stage_preview_visible"] is True
    assert result["ui_contract"]["runtime_execution_action_available"] is False
    assert (output / "video_pipeline_manifest.json").exists()
    assert (output / "video_pipeline_stages.jsonl").exists()
    assert (output / "asset_handoff_schema.json").exists()
    assert (output / "timeline_schema.json").exists()
    assert (output / "VIDEO_PIPELINE_SCHEMA_INDEX.md").exists()


def test_video_pipeline_schema_validation_checks_runtime_boundaries(tmp_path):
    library = tmp_path / "library"
    build_video_pipeline_schema_library(library)

    result = validate_video_pipeline_schema_library(library)

    assert result["status"] == "passed"
    assert result["stage_count"] == 7
    assert result["missing_files"] == []
    assert result["stage_errors"] == []
    assert result["boundary_errors"] == []
    assert result["external_code_or_content_copied"] is False
    assert result["external_runtime_integrated"] is False
    assert result["story_to_video_runtime"] is False
    assert result["video_generation_runtime"] is False
    assert result["media_rendering_runtime"] is False
    assert result["timeline_source_trace_required"] is True
    assert result["final_target_not_downgraded"] is True
    assert result["not_goal_complete"] is True


def test_video_pipeline_schema_cli_builds_and_validates(tmp_path):
    library = tmp_path / "library"
    validation = tmp_path / "validation"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "build-video-pipeline-schema-library",
            "--output",
            str(library),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-video-pipeline-schema-library",
            "--library",
            str(library),
            "--output",
            str(validation),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "stages=7" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    report = json.loads(
        (validation / "video_pipeline_validation_report.json").read_text(encoding="utf-8")
    )
    assert report["status"] == "passed"


def test_video_pipeline_schema_rejects_story_to_video_runtime_claim(tmp_path):
    library = tmp_path / "library"
    build_video_pipeline_schema_library(library)
    manifest_path = library / "video_pipeline_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["runtime_boundary"]["story_to_video_runtime"] = True
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    result = validate_video_pipeline_schema_library(library)

    assert result["status"] == "failed"
    assert "story_to_video_runtime_must_be_false" in result["boundary_errors"]
