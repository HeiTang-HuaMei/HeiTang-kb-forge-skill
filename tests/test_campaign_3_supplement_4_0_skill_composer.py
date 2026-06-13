import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_campaign_3_supplement_4_0_skill_composer,
    validate_campaign_3_supplement_4_0_skill_composer,
    write_campaign_3_supplement_4_0_skill_composer,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "section_5" / "campaign_3_supplement_4_0_skill_composer"
NEXT_ACTION = "Campaign 3 Supplement 4.0D Skill-to-Agent Package Unification only"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_skill_composer_builds_dedicated_skill_from_generated_and_imported_sources():
    report = build_campaign_3_supplement_4_0_skill_composer(ROOT)
    dedicated = report["dedicated_skill"]
    imported = report["imported_skill_manifest"]

    assert report["status"] == "passed"
    assert report["implementation_level"] == "bounded industrial-grade implementation"
    assert report["decision_qualifier"] == "skill_import_and_dedicated_skill_composer_only"
    assert report["preconditions"]["status"] == "passed"
    assert dedicated["composition_state"] == "composed_dedicated_skill"
    assert dedicated["lifecycle_state"] == "dedicated_skill_draft"
    assert dedicated["validation_state"] == "validated"
    assert dedicated["publication_state"] == "draft"
    assert dedicated["published"] is False
    assert dedicated["source_trace"]["source_count"] > 0
    assert imported["distinction"] == "imported_skill"
    assert imported["source_known"] is True
    assert imported["trust_state"] == "needs_review"
    assert imported["execution_state"] == "not_executable"


def test_skill_composer_distinguishes_skill_types_and_document_outputs_boundary():
    report = build_campaign_3_supplement_4_0_skill_composer(ROOT)
    distinctions = {
        item["distinction"]: item
        for item in report["skill_distinction_matrix"]["items"]
    }
    document_boundary = report["document_output_boundary"]

    for required in [
        "generated_from_knowledge_base",
        "imported_skill",
        "composed_dedicated_skill",
        "reference_only_skill",
        "planned_skill",
        "document_outputs_existing_core_capability",
    ]:
        assert required in distinctions

    assert distinctions["document_outputs_existing_core_capability"]["asset_id"] == "generate-documents"
    assert distinctions["document_outputs_existing_core_capability"]["covered_by_skill_outputs"] is False
    assert document_boundary["document_outputs_current_recognition"] == "existing_core_capability"
    assert set(document_boundary["formats"]) == {"Markdown", "DOCX / Word", "PDF", "PPTX / PowerPoint"}
    assert document_boundary["document_outputs_written_as_skill_outputs"] is False
    assert document_boundary["presenton_runtime_integrated"] is False
    assert document_boundary["no_npm_install"] is True


def test_skill_composer_boundaries_do_not_publish_or_enter_later_gates():
    report = build_campaign_3_supplement_4_0_skill_composer(ROOT)
    state = report["campaign_state_after_step"]
    validation = report["dedicated_skill_validation_report"]
    next_action = report["next_action_manifest"]

    assert state["campaign_3_supplement_4_0c_passed"] is True
    assert state["dedicated_skill_composed"] is True
    assert state["dedicated_skill_package_generated"] is True
    assert state["composed_skill_published"] is False
    assert state["agent_package_generated_by_4_0c"] is False
    assert state["campaign_3_supplement_4_0_acceptance_gate_passed"] is False
    assert state["campaign_3_final_consistency_gate_passed"] is False
    assert state["campaign_4_active"] is False
    assert state["campaign_5_active"] is False
    assert validation["composed_skill_published"] is False
    assert validation["agent_package_generated_by_4_0c"] is False
    assert validation["skill_without_known_source_may_enter_agent_package"] is False
    assert next_action["next_safe_action"] == NEXT_ACTION
    assert next_action["may_enter_4_0d_skill_to_agent_package"] is True
    assert next_action["may_enter_supplement_4_0_acceptance_gate"] is False
    assert next_action["may_enter_campaign_4"] is False
    assert next_action["may_enter_campaign_5"] is False


def test_unresolved_skill_conflict_blocks_validation(tmp_path):
    output = tmp_path / "skill_composer"
    write_campaign_3_supplement_4_0_skill_composer(ROOT, output)
    conflict_path = output / "skill_conflict_report.json"
    conflict = _json(conflict_path)
    conflict["unresolved_conflict_count"] = 1
    conflict["conflicts"] = [{"conflict_id": "forced_conflict", "blocking": True}]
    conflict_path.write_text(json.dumps(conflict, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    validation = validate_campaign_3_supplement_4_0_skill_composer(ROOT, output)

    assert validation["status"] == "failed"
    assert "unresolved_skill_conflict_blocks_validation" in validation["errors"]


def test_write_outputs_include_required_dedicated_skill_artifacts(tmp_path):
    output = tmp_path / "skill_composer"
    report = write_campaign_3_supplement_4_0_skill_composer(ROOT, output)

    assert report["status"] == "passed"
    for name in [
        "dedicated_skill_package/manifest.json",
        "dedicated_skill_package/SKILL.md",
        "dedicated_skill_package/skill_contract.json",
        "dedicated_skill_package/source_trace.json",
        "dedicated_skill_package/quality_checklist.json",
        "dedicated_skill_package/risk_boundaries.json",
        "dedicated_skill_package/evaluation_cases.jsonl",
        "composed_skill_manifest.yaml",
        "imported_skill_manifest.json",
        "skill_distinction_matrix.json",
        "skill_source_binding.json",
        "skill_conflict_report.json",
        "document_output_boundary.json",
        "skill_composition_report.md",
        "dedicated_skill_validation_report.json",
        "validation_report.json",
        "run_manifest.json",
        "checkpoint.json",
    ]:
        assert (output / name).exists()

    manifest_text = (output / "composed_skill_manifest.yaml").read_text(encoding="utf-8")
    assert "publication_state: \"draft\"" in manifest_text
    assert _json(output / "checkpoint.json")["next_safe_action"] == NEXT_ACTION


def test_cli_build_and_validate_are_runnable(tmp_path):
    output = tmp_path / "skill_composer"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "campaign-3-supplement-4-0-compose-dedicated-skill",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-campaign-3-supplement-4-0-dedicated-skill",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "skill_import_and_dedicated_skill_composer_only" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    assert _json(output / "validation_report.json")["status"] == "passed"


def test_active_skill_composer_audit_outputs_validate_when_present():
    if not AUDIT_DIR.exists():
        return

    validation = validate_campaign_3_supplement_4_0_skill_composer(ROOT, AUDIT_DIR)

    assert validation["status"] == "passed"
    assert validation["next_safe_action"] == NEXT_ACTION
    assert validation["campaign_3_supplement_4_0_acceptance_gate_passed"] is False
    assert validation["campaign_4_active"] is False
    assert validation["campaign_5_active"] is False
