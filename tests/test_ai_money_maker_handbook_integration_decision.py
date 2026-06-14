from heitang_kb_forge.business_scenario_templates import (
    build_business_scenario_template_library,
    validate_business_scenario_template_library,
)
from heitang_kb_forge.campaign_3_closure.review_handoff import _external_project_rows


def _project() -> dict:
    return next(row for row in _external_project_rows() if row["project_name"] == "ai-money-maker-handbook")


def test_ai_money_maker_handbook_decision_is_limited_local_template_library(tmp_path):
    output = tmp_path / "business_scenarios"
    result = build_business_scenario_template_library(output)
    validation = validate_business_scenario_template_library(output)

    assert result["section"] == "5.8"
    assert result["status"] == "passed"
    assert result["integration_mode"] == "business_scenario_template_library"
    assert result["scenario_count"] == 8
    assert result["external_project_reference"]["project_id"] == "ai_money_maker_handbook"
    assert result["external_project_reference"]["external_code_or_content_copied"] is False
    assert result["external_project_reference"]["external_prompts_copied"] is False
    assert result["external_project_reference"]["external_runtime_integrated"] is False
    for field in [
        "trading_execution",
        "payment_processing",
        "ad_spend_or_paid_media",
        "crawler_or_scraper",
        "account_operation",
        "revenue_guarantee",
        "money_automation_ready",
        "financial_advice",
    ]:
        assert result["runtime_boundary"][field] is False
    assert validation["status"] == "passed"


def test_ai_money_maker_handbook_ui_status_is_truthful_and_not_executable(tmp_path):
    result = build_business_scenario_template_library(tmp_path / "business_scenarios")

    assert result["ui_contract"]["business_template_library_visible"] is True
    assert result["ui_contract"]["skill_factory_template_picker_visible"] is True
    assert result["ui_contract"]["runtime_execution_action_available"] is False
    assert result["ui_contract"]["money_automation_action_available"] is False
    assert result["runtime_boundary"]["money_automation_ready"] is False


def test_ai_money_maker_handbook_public_project_row_preserves_boundary():
    project = _project()

    assert project["integration_status"] == "real_integration"
    assert project["implementation_mode"] == "local_original_library"
    assert project["runtime_dependency_added"] is False
    assert "Business scenario templates" in project["capability_domain"]
    assert "no financial automation" in project["current_boundary"]
    assert project["future_target"] == "Business workflow templates"


def test_ai_money_maker_handbook_non_downgrade_fields_are_present(tmp_path):
    result = build_business_scenario_template_library(tmp_path / "business_scenarios")
    validation = validate_business_scenario_template_library(tmp_path / "business_scenarios")

    for payload in [result, validation]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["not_goal_complete"] is True
