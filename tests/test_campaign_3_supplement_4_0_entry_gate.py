import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_campaign_3_supplement_4_0_entry_gate,
    validate_campaign_3_supplement_4_0_entry_gate,
    write_campaign_3_supplement_4_0_entry_gate,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "section_5" / "campaign_3_supplement_4_0_entry_gate"
NEXT_ACTION = "Campaign 3 Supplement 4.0 Knowledge-to-Skill Template Generator implementation"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_entry_gate_verifies_supplement_3_0_and_pre_4_0_prerequisites():
    report = build_campaign_3_supplement_4_0_entry_gate(ROOT)
    item_ids = {item["item_id"]: item for item in report["precondition_matrix"]["items"]}

    assert report["status"] == "passed"
    assert report["implementation_level"] == "bounded industrial-grade entry gate"
    assert item_ids["supplement_3_0_acceptance_gate_passed"]["status"] == "passed"
    assert item_ids["pre_4_0_workspace_partition_foundation_gate_passed"]["status"] == "passed"
    assert report["campaign_state_after_gate"]["campaign_3_4_0_entry_gate_passed"] is True
    assert report["campaign_state_after_gate"]["campaign_3_4_0_business_implementation_allowed_next"] is True


def test_entry_gate_validates_pre_4_0_contracts_are_parseable():
    report = build_campaign_3_supplement_4_0_entry_gate(ROOT)
    contracts = [
        item
        for item in report["precondition_matrix"]["items"]
        if item["item_id"].startswith("contract_exists_and_parseable:")
    ]

    assert contracts
    assert {item["status"] for item in contracts} == {"passed"}
    assert all(item["parsed"] is True for item in contracts)
    assert any("WORKSPACE_MANIFEST_SCHEMA.json" in item["item_id"] for item in contracts)
    assert any("WORKSPACE_REGISTRY_SCHEMA.json" in item["item_id"] for item in contracts)
    assert any("KNOWLEDGE_BASE_PARTITION_SCHEMA.json" in item["item_id"] for item in contracts)
    assert any("KNOWLEDGE_BASE_ACCESS_SCOPE_MATRIX.json" in item["item_id"] for item in contracts)
    assert any("WORKSPACE_PATH_BOUNDARY_POLICY.md" in item["item_id"] for item in contracts)
    assert any("WORKSPACE_PARTITION_UI_HANDOFF_CONTRACT.json" in item["item_id"] for item in contracts)
    assert any("WORKSPACE_BOUNDARY_BRIDGE_HANDOFF_CONTRACT.json" in item["item_id"] for item in contracts)


def test_entry_gate_reconciles_external_source_kb_skill_and_agent_assets():
    report = build_campaign_3_supplement_4_0_entry_gate(ROOT)
    evidence = "\n".join(report["reviewed_evidence"])

    for marker in [
        "unified_source_trace.json",
        "unified_evidence_map.json",
        "claim_verification_report.json",
        "knowledge_correctness_report.json",
        "answer_grounding_report.json",
        "knowledge_base/manifest.json",
        "knowledge_base/evidence_map.json",
        "knowledge_package/artifact_inventory.json",
        "heitang_kb_forge/skill/generator.py",
        "heitang_kb_forge/agent_package/generator.py",
        "heitang_kb_forge/knowledge_bound_factory/__init__.py",
        "heitang_kb_forge/agent_compat/__init__.py",
        "generate-agent",
        "generate-bound-agent",
    ]:
        assert marker in evidence or any(marker in item["item_id"] for item in report["precondition_matrix"]["items"])

    assert report["agent_state_facts"] == {
        "agent_package_ready": True,
        "agent_runtime_ready": False,
        "agent_executable_platform_ready": False,
        "agent_product_workbench_ready": False,
        "agent_memory_runtime_ready": False,
        "multi_agent_runtime_ready": False,
    }


def test_entry_gate_boundary_matrix_forbids_business_and_later_campaign_overclaims():
    report = build_campaign_3_supplement_4_0_entry_gate(ROOT)
    boundaries = {item["item_id"]: item for item in report["boundary_matrix"]["items"]}
    state = report["campaign_state_after_gate"]
    non_substitution = report["non_substitution_rules"]

    for forbidden in [
        "entry_gate_is_4_0_business_implementation",
        "kb_profiler_run",
        "skill_generator_run",
        "skill_validator_run",
        "skill_testcase_generator_run",
        "campaign_3_final_consistency_gate_passed",
        "campaign_4_active",
        "campaign_5_active",
        "stage_test_gate_passed",
        "closure_pack_generated",
        "upload_done",
        "tag_created",
        "ci_green",
    ]:
        assert boundaries[forbidden]["actual_value"] is False

    assert state["campaign_3_4_0_business_implementation_complete"] is False
    assert state["campaign_3_4_0_accepted"] is False
    assert state["campaign_3_final_consistency_gate_passed"] is False
    assert state["campaign_4_active"] is False
    assert state["campaign_5_active"] is False
    assert non_substitution["entry_gate_is_4_0_business_implementation"] is False
    assert non_substitution["entry_gate_is_campaign_3_final_consistency_gate"] is False
    assert non_substitution["entry_gate_opens_campaign_4"] is False


def test_entry_gate_writes_required_audit_outputs_and_governance_reports(tmp_path):
    output = tmp_path / "entry_gate"
    report = write_campaign_3_supplement_4_0_entry_gate(ROOT, output)

    assert report["status"] == "passed"
    for name in [
        "precondition_matrix.json",
        "boundary_matrix.json",
        "entry_reconciliation_report.json",
        "entry_reconciliation_report.md",
        "next_action_manifest.json",
        "run_manifest.json",
        "checkpoint.json",
        "validation_report.json",
        "run_summary.md",
    ]:
        assert (output / name).exists()

    assert _json(output / "next_action_manifest.json")["next_safe_action"] == NEXT_ACTION
    assert _json(output / "run_manifest.json")["decision_qualifier"] == (
        "bounded_industrial_grade_entry_gate_only"
    )
    assert (ROOT / "docs" / "governance" / "CAMPAIGN_3_4_0_ENTRY_RECONCILIATION.md").exists()
    assert (ROOT / "docs" / "governance" / "CAMPAIGN_3_4_0_ENTRY_RECONCILIATION.json").exists()


def test_entry_gate_cli_build_and_validate_are_runnable(tmp_path):
    output = tmp_path / "entry_gate"
    runner = CliRunner()
    build = runner.invoke(
        app,
        [
            "campaign-3-supplement-4-0-entry-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "status=passed" in build.output
    assert _json(output / "precondition_matrix.json")["status"] == "passed"

    validate = runner.invoke(
        app,
        [
            "validate-campaign-3-supplement-4-0-entry-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    assert _json(output / "validation_report.json")["status"] == "passed"


def test_active_entry_gate_audit_outputs_validate_when_present():
    if not AUDIT_DIR.exists():
        return

    validation = validate_campaign_3_supplement_4_0_entry_gate(ROOT, AUDIT_DIR)

    assert validation["status"] == "passed"
    assert validation["next_safe_action"] == NEXT_ACTION
    assert validation["campaign_4_active"] is False
    assert validation["campaign_5_active"] is False
    assert validation["campaign_3_final_consistency_gate_passed"] is False
