import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "mattpocock_skills_engineering_governance"
DECISION = RUN_DIR / "mattpocock_skills_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "mattpocock_skills_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
RULES = RUN_DIR / "rules" / "engineering_governance_manifest.json"
VALIDATION = RUN_DIR / "validation" / "engineering_governance_validation_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
PROJECT_REGISTRY = ROOT / "docs" / "roadmap" / "external_projects" / "external_project_registry.json"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_mattpocock_decision_is_local_engineering_governance_only():
    decision = _json(DECISION)
    rules = _json(RULES)
    validation = _json(VALIDATION)

    assert decision["project_id"] == "mattpocock_skills"
    assert decision["section"] == "5.13"
    assert decision["decision"] == "real_integration"
    assert decision["integration_mode"] == "engineering_governance_rule_pack"
    assert decision["verification_state"] == "verified_source_local_rule_pack_only"
    repo = decision["repository_check"]
    assert repo["git_ls_remote_result"] == "accessible"
    assert repo["git_ls_remote_head"] == "694fa30311e02c2639942308513555e61ee84a6f"
    assert repo["license_spdx"] == "MIT"
    assert repo["repository_cloned"] is False
    assert repo["external_code_copied"] is False
    assert repo["external_prompt_text_copied"] is False
    assert repo["external_skill_files_copied"] is False
    runtime = decision["runtime_contract"]
    assert runtime["local_rule_pack_implemented"] is True
    assert runtime["external_runtime_integrated"] is False
    assert runtime["external_agent_skill_installed"] is False
    assert runtime["business_runtime_created"] is False
    assert runtime["agent_created_or_bound"] is False
    assert runtime["campaign_3_3_0_implemented"] is False
    assert runtime["campaign_3_4_0_implemented"] is False
    assert rules["status"] == "passed"
    assert rules["rule_counts"] == {
        "pre_code": 4,
        "test_gate": 4,
        "review_gate": 3,
        "ai_collaboration": 3,
    }
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []


def test_mattpocock_ui_state_is_status_only_and_not_executable():
    ui = _json(UI_IMPACT)

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["development_rules_report_visible"] is True
    assert ui["current_ui_state"]["local_ready"] is True
    assert ui["current_ui_state"]["ready"] is False
    assert ui["current_ui_state"]["executable_action"] is False
    assert ui["current_ui_state"]["business_workflow_entry"] is False
    assert ui["current_ui_state"]["agent_action_available"] is False
    assert "mattpocock/skills runtime ready" in ui["ui_must_not_show"]
    assert "Create Agent from mattpocock/skills" in ui["ui_must_not_show"]


def test_mattpocock_registry_and_campaign_sequence_advance_to_5_14():
    registry = _json(PROJECT_REGISTRY)
    project = next(item for item in registry["projects"] if item["project_id"] == "mattpocock_skills")
    run = _json(RUN_MANIFEST)
    audit = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in audit["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert project["current_repo_status"] == "real_workflow_evidence"
    assert project["implementation_mode"] == "engineering_governance_rule_pack"
    assert "heitang_kb_forge/engineering_governance_rules/builder.py" in project["current_evidence_files"]
    assert "tests/test_engineering_governance_rules.py" in project["current_evidence_files"]
    assert project["requires_api_key"] is False
    assert project["requires_network"] is False
    assert project["requires_external_runtime"] is False
    assert run["integration_decision"] == "real_integration"
    assert run["campaign_state_after_run"]["campaign_3_item_5_13"] == (
        "advanced_real_integration_rule_pack_only"
    )
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_3_3_0_active"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == "5.14 Sirchmunk"
    assert runs["mattpocock_skills_engineering_governance"]["scope"] == (
        "SECTION_5_ITEM_5_13_MATTPOCOCK_SKILLS"
    )
    assert "mattpocock_skills_engineering_governance" in index
    assert "Next Section 5 item: `5.14 Sirchmunk`" in plan


def test_mattpocock_non_downgrade_fields_point_to_5_14():
    for payload in [
        _json(DECISION),
        _json(UI_IMPACT),
        _json(RUN_MANIFEST),
        _json(RULES),
        _json(VALIDATION),
    ]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"] == (
            "Process Section 5 item 5.14 Sirchmunk only."
        )
        assert payload["not_goal_complete"] is True
