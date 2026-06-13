import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_campaign_3_supplement_4_0_acceptance_gate,
    validate_campaign_3_supplement_4_0_acceptance_gate,
    write_campaign_3_supplement_4_0_acceptance_gate,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "campaign_3_4_0"
NEXT_ACTION = "Campaign 3 Final Consistency Gate only"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_acceptance_gate_accepts_only_after_4_0_a_b_c_d_i_evidence_passes():
    report = build_campaign_3_supplement_4_0_acceptance_gate(ROOT)
    components = {item["item_id"]: item for item in report["component_reviews"]}
    stages = {item["stage_id"]: item for item in report["stage_reviews"]["stages"]}

    assert report["status"] == "passed"
    assert report["verdict"] == "accepted_for_campaign_3_final_consistency_gate"
    assert report["implementation_level"] == "bounded industrial-grade acceptance gate"
    for required in [
        "4_0a_entry_gate",
        "4_0b_verified_knowledge_to_skill_template",
        "4_0c_skill_import_and_dedicated_skill_composer",
        "4_0d_skill_to_agent_package",
        "4_0d_i_product_handoff_contract_bundle",
    ]:
        assert components[required]["status"] == "passed"
    for required in [
        "4_0d_agent_package",
        "4_0e_workspace_binding",
        "4_0f_memory_isolation",
        "4_0g_single_multi_agent_mode",
        "4_0h_campaign_4_ui_handoff",
        "4_0i_campaign_5_bridge_handoff",
    ]:
        assert stages[required]["status"] == "passed"


def test_acceptance_gate_does_not_start_later_gates_or_campaigns():
    report = build_campaign_3_supplement_4_0_acceptance_gate(ROOT)
    state = report["campaign_state_after_gate"]
    rules = report["non_substitution_rules"]
    next_action = report["next_action_manifest"]

    assert state["campaign_3_supplement_4_0_acceptance_gate_passed"] is True
    assert state["campaign_3_supplement_4_0_accepted"] is True
    assert state["campaign_3_4_0_accepted"] is True
    assert state["campaign_3_final_consistency_gate_passed"] is False
    assert state["campaign_3_accepted"] is False
    assert state["campaign_4_active"] is False
    assert state["campaign_5_active"] is False
    assert state["campaign_6_active"] is False
    assert state["campaign_9_active"] is False
    assert state["repository_push_succeeded"] is False
    assert state["tag_created"] is False
    assert state["ci_green"] is False
    assert state["final_release_allowed"] is False
    assert rules["supplement_4_0_acceptance_starts_final_consistency_gate"] is False
    assert rules["supplement_4_0_acceptance_starts_stage_test_gate"] is False
    assert rules["supplement_4_0_acceptance_starts_campaign_4"] is False
    assert next_action["next_safe_action"] == NEXT_ACTION
    assert next_action["may_enter_campaign_3_final_consistency_gate"] is True
    assert next_action["may_enter_stage_test_gate"] is False
    assert next_action["may_enter_campaign_4"] is False
    assert next_action["may_enter_campaign_5"] is False


def test_acceptance_gate_preserves_ui_bridge_agent_and_memory_boundaries():
    report = build_campaign_3_supplement_4_0_acceptance_gate(ROOT)
    boundaries = {
        item["item_id"]: item
        for item in report["status_boundary_matrix"]["items"]
    }
    state = report["campaign_state_after_gate"]

    for required_false in [
        "campaign_4_active",
        "campaign_4_ui_complete",
        "campaign_5_active",
        "bridge_execution_accepted",
        "agent_runtime_ready",
        "agent_executable",
        "redis_runtime_ready",
        "vector_runtime_ready",
        "multi_agent_runtime_ready",
    ]:
        assert boundaries[required_false]["actual_value"] is False
    assert state["agent_package_ready"] is True
    assert state["agent_runtime_ready"] is False
    assert state["agent_executable"] is False
    assert state["redis_runtime_ready"] is False
    assert state["vector_runtime_ready"] is False
    assert state["multi_agent_runtime_ready"] is False
    assert report["status_boundary_matrix"]["status"] == "passed"


def test_acceptance_gate_writes_required_audit_outputs(tmp_path):
    output = tmp_path / "acceptance"
    report = write_campaign_3_supplement_4_0_acceptance_gate(ROOT, output)

    assert report["status"] == "passed"
    for name in [
        "campaign_3_supplement_4_0_acceptance_gate.json",
        "campaign_3_supplement_4_0_acceptance_gate.md",
        "campaign_3_supplement_4_0_acceptance_matrix.json",
        "status_boundary_matrix.json",
        "skill_generation_report.json",
        "agent_package_reconciliation_report.json",
        "agent_workspace_binding_report.json",
        "agent_memory_isolation_report.json",
        "multi_agent_workflow_spec_report.json",
        "campaign_4_ui_handoff_report.json",
        "campaign_5_bridge_handoff_report.json",
        "validation_report.json",
        "run_manifest.json",
        "checkpoint.json",
        "progress_events.jsonl",
        "run_summary.md",
    ]:
        assert (output / name).exists()

    assert _json(output / "run_manifest.json")["scope"] == "CAMPAIGN_3_SUPPLEMENT_4_0_ACCEPTANCE_GATE"
    assert _json(output / "checkpoint.json")["next_safe_action"] == NEXT_ACTION


def test_acceptance_gate_fails_closed_when_boundary_is_overclaimed(tmp_path):
    output = tmp_path / "acceptance"
    write_campaign_3_supplement_4_0_acceptance_gate(ROOT, output)
    boundary_path = output / "status_boundary_matrix.json"
    boundary = _json(boundary_path)
    boundary["items"][0]["actual_value"] = True
    boundary["items"][0]["status"] = "failed"
    boundary["status"] = "failed"
    boundary_path.write_text(json.dumps(boundary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    validation = validate_campaign_3_supplement_4_0_acceptance_gate(ROOT, output)

    assert validation["status"] == "failed"
    assert "boundary_matrix_not_passed" in validation["errors"]


def test_acceptance_gate_cli_build_and_validate_are_runnable(tmp_path):
    output = tmp_path / "acceptance"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "campaign-3-supplement-4-0-acceptance-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-campaign-3-supplement-4-0-acceptance-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "status=passed" in build.output
    assert "accepted_for_campaign_3_final_consistency_gate" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    assert _json(output / "validation_report.json")["status"] == "passed"


def test_active_acceptance_gate_audit_outputs_validate_when_present():
    run_manifest = AUDIT_DIR / "run_manifest.json"
    if not run_manifest.exists():
        return
    if _json(run_manifest).get("scope") != "CAMPAIGN_3_SUPPLEMENT_4_0_ACCEPTANCE_GATE":
        return

    validation = validate_campaign_3_supplement_4_0_acceptance_gate(ROOT, AUDIT_DIR)

    assert validation["status"] == "passed"
    assert validation["next_safe_action"] == NEXT_ACTION
    assert validation["campaign_3_supplement_4_0_acceptance_gate_passed"] is True
    assert validation["campaign_3_final_consistency_gate_passed"] is False
    assert validation["campaign_4_active"] is False
    assert validation["campaign_5_active"] is False
