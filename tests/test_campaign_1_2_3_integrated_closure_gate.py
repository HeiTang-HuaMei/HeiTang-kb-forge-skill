import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_campaign_1_2_3_integrated_closure_gate,
    validate_campaign_1_2_3_integrated_closure_gate,
    write_campaign_1_2_3_integrated_closure_gate,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "campaign_1_2_3_integrated_closure"
NEXT_ACTION = "Generate Campaign 1-3 Closure Pack only"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_integrated_closure_accepts_only_after_stage_test_passes():
    report = build_campaign_1_2_3_integrated_closure_gate(ROOT)

    assert report["status"] == "passed"
    assert report["verdict"] == "accepted_for_closure_pack_generation"
    assert report["implementation_level"] == "bounded industrial-grade integrated closure gate"
    assert report["campaign_status_matrix"]["status"] == "passed"
    assert report["real_integration_matrix"]["status"] == "passed"
    assert report["framework_only_matrix"]["status"] == "passed"
    assert report["preflight_only_matrix"]["status"] == "passed"
    assert report["metadata_only_matrix"]["status"] == "passed"
    assert report["reference_only_matrix"]["status"] == "passed"
    assert report["planned_not_active_matrix"]["status"] == "passed"
    assert report["non_runtime_boundary_matrix"]["status"] == "passed"
    assert report["failure_count"] == 0


def test_integrated_closure_allows_only_closure_pack_next():
    report = build_campaign_1_2_3_integrated_closure_gate(ROOT)
    state = report["campaign_state_after_gate"]
    next_action = report["next_action_manifest"]

    assert state["campaign_3_final_consistency_gate_passed"] is True
    assert state["campaign_1_3_stage_test_gate_passed"] is True
    assert state["campaign_1_3_integrated_closure_gate_passed"] is True
    assert state["closure_pack_generated"] is False
    assert state["repository_public_surface_cleanup_gate_passed"] is False
    assert state["repository_push_succeeded"] is False
    assert state["tag_created"] is False
    assert state["ci_green"] is False
    assert state["closure_checklist_green"] is False
    assert state["campaign_4_active"] is False
    assert state["campaign_5_active"] is False
    assert state["full_gate_passed"] is False
    assert state["exe_packaging_done"] is False
    assert next_action["next_safe_action"] == NEXT_ACTION
    assert next_action["may_generate_closure_pack"] is True
    assert next_action["may_run_repository_cleanup"] is False
    assert next_action["may_push"] is False
    assert next_action["may_tag"] is False
    assert next_action["may_check_ci_green"] is False
    assert next_action["may_enter_campaign_4"] is False


def test_integrated_closure_preserves_evidence_classification_boundaries():
    report = build_campaign_1_2_3_integrated_closure_gate(ROOT)

    planned = {item["item_id"]: item for item in report["planned_not_active_matrix"]["items"]}
    reference = {item["item_id"]: item for item in report["reference_only_matrix"]["items"]}
    framework = {item["item_id"]: item for item in report["framework_only_matrix"]["items"]}
    preflight = {item["item_id"]: item for item in report["preflight_only_matrix"]["items"]}

    assert planned["campaign_4_goal_oriented_ui_workbench"]["status"] == "planned_not_active"
    assert planned["campaign_5_chain_level_bridge"]["status"] == "planned_not_active"
    assert planned["redis_vector_memory_store"]["status"] == "planned_not_active"
    assert reference["presenton"]["status"] == "reference_only"
    assert reference["pi_mono"]["status"] == "reference_only"
    assert framework["campaign_4_ui_handoff"]["status"] == "framework_only"
    assert framework["campaign_5_bridge_handoff"]["status"] == "framework_only"
    assert preflight["external_link_import_entry"]["status"] == "preflight_only"


def test_integrated_closure_writes_required_audit_outputs(tmp_path):
    output = tmp_path / "integrated-closure"
    report = write_campaign_1_2_3_integrated_closure_gate(ROOT, output)

    assert report["status"] == "passed"
    for name in [
        "run_manifest.json",
        "run_summary.md",
        "campaign_1_2_3_integrated_closure_gate.json",
        "campaign_status_matrix.json",
        "real_integration_matrix.json",
        "framework_only_matrix.json",
        "preflight_only_matrix.json",
        "metadata_only_matrix.json",
        "reference_only_matrix.json",
        "planned_not_active_matrix.json",
        "non_runtime_boundary_matrix.json",
        "unfinished_items.json",
        "forbidden_misinterpretations.json",
        "changed_files_manifest.json",
        "artifact_manifest.json",
        "test_result_manifest.json",
        "validation_report.json",
        "checkpoint.json",
        "progress_events.jsonl",
        "handoff.md",
    ]:
        assert (output / name).exists()

    assert _json(output / "run_manifest.json")["scope"] == "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_GATE"
    assert _json(output / "checkpoint.json")["checkpoint_id"] == "campaign_1_2_3_integrated_closure_gate_passed"
    assert _json(output / "checkpoint.json")["next_safe_action"] == NEXT_ACTION


def test_integrated_closure_fails_closed_when_output_is_overclaimed(tmp_path):
    output = tmp_path / "integrated-closure"
    write_campaign_1_2_3_integrated_closure_gate(ROOT, output)
    report_path = output / "campaign_1_2_3_integrated_closure_gate.json"
    report = _json(report_path)
    report["campaign_state_after_gate"]["campaign_4_active"] = True
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    validation = validate_campaign_1_2_3_integrated_closure_gate(ROOT, output)

    assert validation["status"] == "failed"
    assert "overclaimed_state:campaign_4_active" in validation["errors"]


def test_integrated_closure_cli_build_and_validate_are_runnable(tmp_path):
    output = tmp_path / "integrated-closure"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "campaign-1-2-3-integrated-closure-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-campaign-1-2-3-integrated-closure-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "status=passed" in build.output
    assert "accepted_for_closure_pack_generation" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    assert _json(output / "validation_report.json")["status"] == "passed"


def test_active_integrated_closure_audit_outputs_validate_when_present():
    run_manifest = AUDIT_DIR / "run_manifest.json"
    if not run_manifest.exists():
        return
    if _json(run_manifest).get("scope") != "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_GATE":
        return

    validation = validate_campaign_1_2_3_integrated_closure_gate(ROOT, AUDIT_DIR)

    assert validation["status"] == "passed"
    assert validation["next_safe_action"] == NEXT_ACTION
    assert validation["campaign_1_3_integrated_closure_gate_passed"] is True
    assert validation["closure_pack_generated"] is False
    assert validation["campaign_4_active"] is False
