import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.prompt_asset_library import (
    build_prompt_asset_library,
    validate_prompt_asset_library,
)
from tests.p0_helpers import write_json


def test_prompt_asset_library_builds_from_skill_suite_without_replacing_factory(tmp_path):
    suite = _write_suite(tmp_path / "suite")
    output = tmp_path / "prompt_assets"

    result = build_prompt_asset_library(suite, output)

    assert result["status"] == "passed"
    assert result["prompt_card_count"] == 2
    assert result["external_project_reference"]["project_id"] == "skill_prompt_generator"
    assert result["external_project_reference"]["external_code_or_prompts_copied"] is False
    assert result["external_project_reference"]["license_gate"] == "pending_no_license_field_in_github_api"
    assert result["skill_factory_boundary"]["enhancer_only"] is True
    assert result["skill_factory_boundary"]["p2_2_skill_factory_replaced"] is False
    assert result["skill_factory_boundary"]["skill_suite_modified"] is False
    assert result["skill_factory_boundary"]["llm_required"] is False
    assert (output / "prompt_asset_manifest.json").exists()
    assert (output / "prompt_cards.jsonl").exists()
    assert (output / "PROMPT_ASSET_INDEX.md").exists()
    assert (suite / "suite.json").exists()


def test_prompt_asset_library_validation_checks_cards_and_boundaries(tmp_path):
    suite = _write_suite(tmp_path / "suite")
    output = tmp_path / "prompt_assets"
    build_prompt_asset_library(suite, output)

    result = validate_prompt_asset_library(output)

    assert result["status"] == "passed"
    assert result["prompt_card_count"] == 2
    assert result["missing_files"] == []
    assert result["card_errors"] == []
    assert result["boundary_errors"] == []
    assert result["external_code_or_prompts_copied"] is False
    assert result["p2_2_skill_factory_replaced"] is False
    assert result["final_target_not_downgraded"] is True
    assert result["not_goal_complete"] is True


def test_prompt_asset_library_cli_builds_and_validates(tmp_path):
    suite = _write_suite(tmp_path / "suite")
    library = tmp_path / "library"
    validation = tmp_path / "validation"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "build-prompt-asset-library",
            "--skill-suite",
            str(suite),
            "--output",
            str(library),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-prompt-asset-library",
            "--library",
            str(library),
            "--output",
            str(validation),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "prompt_cards=2" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    report = json.loads((validation / "prompt_asset_validation_report.json").read_text(encoding="utf-8"))
    assert report["status"] == "passed"


def test_prompt_asset_library_rejects_empty_suite(tmp_path):
    suite = tmp_path / "empty_suite"
    suite.mkdir()
    write_json(suite / "suite.json", {"suite_id": "suite_empty", "skills": []})

    try:
        build_prompt_asset_library(suite, tmp_path / "out")
    except ValueError as exc:
        assert "non-empty suite.json skills" in str(exc)
    else:
        raise AssertionError("empty suite should fail")


def _write_suite(path):
    path.mkdir(parents=True)
    skill_dir = path / "skills" / "planning" / "candidate_plan"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text(
        "# Plan Operations\n\n## Purpose\n\nPlan with cited evidence.\n",
        encoding="utf-8",
    )
    skill_dir_2 = path / "skills" / "functional" / "candidate_execute"
    skill_dir_2.mkdir(parents=True)
    (skill_dir_2 / "SKILL.md").write_text(
        "# Execute Operations\n\n## Purpose\n\nExecute with source boundaries.\n",
        encoding="utf-8",
    )
    write_json(
        path / "suite.json",
        {
            "suite_id": "suite_test",
            "source_package_id": "pkg_test",
            "skill_count": 2,
            "skills": [
                {
                    "skill_id": "candidate_plan",
                    "title": "Plan Operations",
                    "skill_type": "planning",
                    "path": "skills/planning/candidate_plan/SKILL.md",
                    "trigger": "Use when planning is required.",
                    "purpose": "Plan with cited evidence.",
                    "supporting_evidence": ["window_plan"],
                },
                {
                    "skill_id": "candidate_execute",
                    "title": "Execute Operations",
                    "skill_type": "functional",
                    "path": "skills/functional/candidate_execute/SKILL.md",
                    "trigger": "Use when execution is required.",
                    "purpose": "Execute with source boundaries.",
                    "supporting_evidence": ["window_execute"],
                },
            ],
        },
    )
    return path
