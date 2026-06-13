import json

from typer.testing import CliRunner

from heitang_kb_forge.business_scenario_templates import (
    build_business_scenario_template_library,
    validate_business_scenario_template_library,
)
from heitang_kb_forge.cli import app


def test_business_scenario_template_library_builds_original_scenarios(tmp_path):
    output = tmp_path / "business_scenarios"

    result = build_business_scenario_template_library(output)

    assert result["section"] == "5.8"
    assert result["status"] == "passed"
    assert result["integration_mode"] == "business_scenario_template_library"
    assert result["scenario_count"] == 8
    assert set(result["scenario_ids"]) == {
        "knowledge_product_offer",
        "service_packaging",
        "lead_magnet",
        "course_workshop",
        "consulting_diagnostic",
        "content_to_case_study",
        "community_offer",
        "template_asset_pack",
    }
    assert result["external_project_reference"]["project_id"] == "ai_money_maker_handbook"
    assert result["external_project_reference"]["git_head"] == "e29581de103e0770396a2a5b389c1b41b730ba80"
    assert result["external_project_reference"]["external_code_or_content_copied"] is False
    assert result["external_project_reference"]["external_prompts_copied"] is False
    assert result["external_project_reference"]["external_runtime_integrated"] is False
    assert result["runtime_boundary"]["trading_execution"] is False
    assert result["runtime_boundary"]["payment_processing"] is False
    assert result["runtime_boundary"]["ad_spend_or_paid_media"] is False
    assert result["runtime_boundary"]["crawler_or_scraper"] is False
    assert result["runtime_boundary"]["account_operation"] is False
    assert result["runtime_boundary"]["revenue_guarantee"] is False
    assert result["runtime_boundary"]["money_automation_ready"] is False
    assert result["runtime_boundary"]["financial_advice"] is False
    assert result["ui_contract"]["business_template_library_visible"] is True
    assert result["ui_contract"]["runtime_execution_action_available"] is False
    assert (output / "business_scenario_manifest.json").exists()
    assert (output / "business_scenario_cards.jsonl").exists()
    assert (output / "BUSINESS_SCENARIO_INDEX.md").exists()


def test_business_scenario_template_validation_checks_boundaries(tmp_path):
    library = tmp_path / "library"
    build_business_scenario_template_library(library)

    result = validate_business_scenario_template_library(library)

    assert result["status"] == "passed"
    assert result["scenario_count"] == 8
    assert result["missing_files"] == []
    assert result["card_errors"] == []
    assert result["boundary_errors"] == []
    assert result["external_code_or_content_copied"] is False
    assert result["external_prompts_copied"] is False
    assert result["external_runtime_integrated"] is False
    assert result["final_target_not_downgraded"] is True
    assert result["not_goal_complete"] is True


def test_business_scenario_template_cli_builds_and_validates(tmp_path):
    library = tmp_path / "library"
    validation = tmp_path / "validation"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "build-business-scenario-template-library",
            "--output",
            str(library),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-business-scenario-template-library",
            "--library",
            str(library),
            "--output",
            str(validation),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "scenarios=8" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    report = json.loads((validation / "business_scenario_validation_report.json").read_text(encoding="utf-8"))
    assert report["status"] == "passed"


def test_business_scenario_template_rejects_money_automation_claim(tmp_path):
    library = tmp_path / "library"
    build_business_scenario_template_library(library)
    manifest_path = library / "business_scenario_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["runtime_boundary"]["money_automation_ready"] = True
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    result = validate_business_scenario_template_library(library)

    assert result["status"] == "failed"
    assert "money_automation_ready_must_be_false" in result["boundary_errors"]
