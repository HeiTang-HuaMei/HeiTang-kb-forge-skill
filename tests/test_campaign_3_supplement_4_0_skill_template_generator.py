import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_campaign_3_supplement_4_0_skill_template,
    validate_campaign_3_supplement_4_0_skill_template,
    write_campaign_3_supplement_4_0_skill_template,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "section_5" / "campaign_3_supplement_4_0_skill_template"
NEXT_ACTION = "Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer only"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_skill_template_builds_from_verified_external_source_assets():
    report = build_campaign_3_supplement_4_0_skill_template(ROOT)
    template = report["skill_template"]

    assert report["status"] == "passed"
    assert report["implementation_level"] == "bounded industrial-grade implementation"
    assert report["decision_qualifier"] == "verified_knowledge_to_skill_template_only"
    assert report["preconditions"]["status"] == "passed"
    assert template["state"] == "skill_draft"
    assert template["review_state"] == "skill_generated_from_kb"
    assert template["publication_state"] == "draft"
    assert template["published"] is False
    assert template["source_trace"]["source_count"] > 0
    assert template["source_trace"]["evidence_count"] > 0
    assert template["skill_type"] in report["skill_opportunity_report"]["supported_skill_types"]
    assert report["skill_opportunity_report"]["visual_video_skill_is_subtype_only"] is True


def test_skill_template_contains_required_contract_rules_and_testcases():
    report = build_campaign_3_supplement_4_0_skill_template(ROOT)
    template = report["skill_template"]

    for key in [
        "skill_id",
        "skill_name",
        "skill_type",
        "work_scenario",
        "source_kb_id",
        "source_trace",
        "input_contract",
        "output_contract",
        "methodology",
        "style_profile",
        "workflow_steps",
        "prompt_patterns",
        "quality_checklist",
        "negative_rules",
        "examples",
        "risk_boundaries",
        "evaluation_cases",
    ]:
        assert template[key]

    assert len(report["skill_testcases"]) >= 3
    assert any("draft Skill Template" in rule for rule in template["negative_rules"])
    assert any("Agent runtime" in rule for rule in template["negative_rules"])


def test_skill_template_boundary_does_not_complete_later_items():
    report = build_campaign_3_supplement_4_0_skill_template(ROOT)
    state = report["campaign_state_after_step"]
    validation = report["skill_validation_report"]
    next_action = report["next_action_manifest"]

    assert state["campaign_3_supplement_4_0_skill_template_generated"] is True
    assert state["campaign_3_supplement_4_0_business_implementation_complete"] is False
    assert state["campaign_3_supplement_4_0_acceptance_gate_passed"] is False
    assert state["campaign_3_final_consistency_gate_passed"] is False
    assert state["campaign_4_active"] is False
    assert state["campaign_5_active"] is False
    assert state["agent_runtime_ready"] is False
    assert validation["skill_template_published"] is False
    assert validation["dedicated_skill_composed"] is False
    assert validation["agent_package_generated_by_4_0_b"] is False
    assert next_action["next_safe_action"] == NEXT_ACTION
    assert next_action["may_enter_supplement_4_0_acceptance_gate"] is False
    assert next_action["may_enter_campaign_4"] is False
    assert next_action["may_enter_campaign_5"] is False


def test_unresolved_conflict_blocks_validated_state(tmp_path):
    output = tmp_path / "skill_template"
    write_campaign_3_supplement_4_0_skill_template(ROOT, output)
    conflict_path = output / "conflict_report.json"
    conflict = _json(conflict_path)
    conflict["unresolved_conflict_count"] = 1
    conflict["conflicting_claim_ids"] = ["claim_conflict"]
    conflict_path.write_text(json.dumps(conflict, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    validation = validate_campaign_3_supplement_4_0_skill_template(ROOT, output)

    assert validation["status"] == "failed"
    assert "unresolved_evidence_conflict_blocks_validation" in validation["errors"]


def test_write_outputs_include_required_skill_template_artifacts(tmp_path):
    output = tmp_path / "skill_template"
    report = write_campaign_3_supplement_4_0_skill_template(ROOT, output)

    assert report["status"] == "passed"
    for name in [
        "kb_profile.json",
        "skill_opportunity_report.json",
        "skill_template_draft.json",
        "skill_template_draft.md",
        "methodology_rules.json",
        "style_profile.json",
        "workflow_rules.json",
        "prompt_pattern_library.json",
        "quality_checklist.json",
        "risk_boundaries.json",
        "skill_testcases.json",
        "skill_template.yaml",
        "skill_manifest.yaml",
        "skill_instruction.md",
        "skill_examples.jsonl",
        "skill_quality_checklist.md",
        "skill_risk_boundary.md",
        "skill_source_trace.json",
        "skill_validation_report.json",
        "skill_generation_report.md",
        "run_manifest.json",
        "validation_report.json",
        "checkpoint.json",
    ]:
        assert (output / name).exists()

    manifest_text = (output / "skill_manifest.yaml").read_text(encoding="utf-8")
    assert "publication_state: \"draft\"" in manifest_text
    assert _json(output / "checkpoint.json")["next_safe_action"] == NEXT_ACTION


def test_cli_build_and_validate_are_runnable(tmp_path):
    output = tmp_path / "skill_template"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "campaign-3-supplement-4-0-generate-skill-template",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-campaign-3-supplement-4-0-skill-template",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "verified_knowledge_to_skill_template_only" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    assert _json(output / "validation_report.json")["status"] == "passed"


def test_active_skill_template_audit_outputs_validate_when_present():
    if not AUDIT_DIR.exists():
        return

    validation = validate_campaign_3_supplement_4_0_skill_template(ROOT, AUDIT_DIR)

    assert validation["status"] == "passed"
    assert validation["next_safe_action"] == NEXT_ACTION
    assert validation["campaign_3_supplement_4_0_acceptance_gate_passed"] is False
    assert validation["campaign_4_active"] is False
    assert validation["campaign_5_active"] is False
