import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.marketing_skill_patterns import (
    build_marketing_skill_pattern_library,
    validate_marketing_skill_pattern_library,
)


def test_marketing_skill_pattern_library_builds_original_patterns(tmp_path):
    output = tmp_path / "marketing_patterns"

    result = build_marketing_skill_pattern_library(output)

    assert result["section"] == "5.7"
    assert result["status"] == "passed"
    assert result["integration_mode"] == "marketing_skill_pattern_library"
    assert result["pattern_count"] == 8
    assert set(result["pattern_ids"]) == {
        "growth_experiment",
        "content_ops",
        "outbound_sequence",
        "seo_brief",
        "conversion_audit",
        "sales_playbook",
        "revenue_intelligence",
        "campaign_review",
    }
    assert result["external_project_reference"]["project_id"] == "ai_marketing_skills"
    assert result["external_project_reference"]["git_head"] == "a9f11007aca31cc85f231698e22b64412f847b76"
    assert result["external_project_reference"]["external_code_or_prompts_copied"] is False
    assert result["external_project_reference"]["external_skill_files_copied"] is False
    assert result["external_project_reference"]["external_runtime_integrated"] is False
    assert result["dedup_boundary"]["overlap_checked"] is True
    assert result["dedup_boundary"]["horizon_handled_as_strengthening"] is True
    assert result["runtime_boundary"]["crawler_or_scraper_marketing"] is False
    assert result["runtime_boundary"]["paid_media_execution"] is False
    assert result["runtime_boundary"]["account_operation"] is False
    assert result["runtime_boundary"]["revenue_guarantee"] is False
    assert result["ui_contract"]["marketing_skill_pattern_preview"] is True
    assert result["ui_contract"]["runtime_execution_action_available"] is False
    assert (output / "marketing_pattern_manifest.json").exists()
    assert (output / "marketing_pattern_cards.jsonl").exists()
    assert (output / "MARKETING_PATTERN_INDEX.md").exists()


def test_marketing_skill_pattern_validation_checks_boundaries(tmp_path):
    library = tmp_path / "library"
    build_marketing_skill_pattern_library(library)

    result = validate_marketing_skill_pattern_library(library)

    assert result["status"] == "passed"
    assert result["pattern_count"] == 8
    assert result["missing_files"] == []
    assert result["card_errors"] == []
    assert result["boundary_errors"] == []
    assert result["external_code_or_prompts_copied"] is False
    assert result["external_skill_files_copied"] is False
    assert result["external_runtime_integrated"] is False
    assert result["final_target_not_downgraded"] is True
    assert result["not_goal_complete"] is True


def test_marketing_skill_pattern_cli_builds_and_validates(tmp_path):
    library = tmp_path / "library"
    validation = tmp_path / "validation"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "build-marketing-skill-pattern-library",
            "--output",
            str(library),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-marketing-skill-pattern-library",
            "--library",
            str(library),
            "--output",
            str(validation),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "patterns=8" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    report = json.loads((validation / "marketing_pattern_validation_report.json").read_text(encoding="utf-8"))
    assert report["status"] == "passed"


def test_marketing_skill_pattern_rejects_external_runtime_claim(tmp_path):
    library = tmp_path / "library"
    build_marketing_skill_pattern_library(library)
    manifest_path = library / "marketing_pattern_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["external_project_reference"]["external_runtime_integrated"] = True
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    result = validate_marketing_skill_pattern_library(library)

    assert result["status"] == "failed"
    assert "external_runtime_integrated_must_be_false" in result["boundary_errors"]
