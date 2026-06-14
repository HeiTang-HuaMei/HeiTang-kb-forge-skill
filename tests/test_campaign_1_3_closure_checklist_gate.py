import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_closure_checklist_green_gate,
    validate_closure_checklist_green_gate,
    write_closure_checklist_green_gate,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "campaign_1_3_closure_checklist"
NEXT_ACTION = "Campaign 1-3 Integrated Review and New Conversation Handoff Gate only"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_closure_checklist_fails_closed_until_current_reset_push_and_rc4_are_verified():
    report = build_closure_checklist_green_gate(ROOT)

    assert report["status"] in {"passed", "failed"}
    assert report["implementation_level"] == "bounded industrial-grade closure checklist verification"
    assert report["tag_release_matrix"]["status"] == "passed"
    assert report["ci_cl_matrix"]["status"] == "passed"
    if report["status"] == "failed":
        assert "failed_precondition:repository_push_succeeded" in report["failures"]
        assert report["campaign_state_after_gate"]["closure_checklist_green"] is False
        assert report["campaign_state_after_gate"]["campaign_4_active"] is False
    else:
        assert report["verdict"] == "accepted_for_campaign_1_3_integrated_review_handoff_gate"


def test_closure_checklist_preserves_tag_policy_and_later_campaign_boundaries():
    report = build_closure_checklist_green_gate(ROOT)
    state = report["campaign_state_after_gate"]
    next_action = report["next_action_manifest"]

    assert state["closure_checklist_green"] is (report["status"] == "passed")
    assert state["tag_name"] == "campaign-1-3-baseline-rc.3"
    assert state["stable_campaign_baseline_tag_created"] is False
    assert state["github_release_created"] is False
    assert state["campaign_1_3_review_handoff_gate_passed"] is False
    assert state["campaign_4_active"] is False
    assert state["campaign_5_active"] is False
    assert state["final_release_allowed"] is False
    assert next_action["next_safe_action"] in {NEXT_ACTION, "Repair Closure Checklist Green verification"}
    assert next_action["may_run_campaign_1_3_review_handoff"] is (report["status"] == "passed")
    assert next_action["may_create_stable_campaign_baseline_tag"] is False
    assert next_action["may_create_github_release"] is False
    assert next_action["may_enter_campaign_4"] is False


def test_closure_checklist_writes_required_audit_outputs(tmp_path):
    output = tmp_path / "closure-checklist"
    report = write_closure_checklist_green_gate(ROOT, output)

    assert report["status"] in {"passed", "failed"}
    for name in [
        "run_manifest.json",
        "run_summary.md",
        "closure_checklist_report.json",
        "closure_checklist_report.md",
        "precondition_matrix.json",
        "tag_release_matrix.json",
        "ci_cl_matrix.json",
        "boundary_matrix.json",
        "validation_report.json",
        "checkpoint.json",
        "progress_events.jsonl",
        "tag_naming_policy_correction_report_snapshot.json",
    ]:
        assert (output / name).exists()

    assert _json(output / "run_manifest.json")["scope"] == "CAMPAIGN_1_3_CLOSURE_CHECKLIST_GREEN"
    checkpoint = _json(output / "checkpoint.json")
    if report["status"] == "passed":
        assert checkpoint["checkpoint_id"] == "closure_checklist_green_passed"
        assert checkpoint["next_safe_action"] == NEXT_ACTION
    else:
        assert checkpoint["checkpoint_id"] == "closure_checklist_green_failed"


def test_closure_checklist_validation_fails_closed_on_campaign_4_overclaim(tmp_path):
    output = tmp_path / "closure-checklist"
    write_closure_checklist_green_gate(ROOT, output)
    report_path = output / "closure_checklist_report.json"
    report = _json(report_path)
    report["campaign_state_after_gate"]["campaign_4_active"] = True
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    validation = validate_closure_checklist_green_gate(ROOT, output)

    assert validation["status"] == "failed"
    assert "overclaimed_state:campaign_4_active" in validation["errors"]


def test_closure_checklist_cli_build_and_validate_are_runnable(tmp_path):
    output = tmp_path / "closure-checklist"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "closure-checklist-green-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-closure-checklist-green-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "status=" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=" in validate.output


def test_active_closure_checklist_outputs_validate_when_present():
    run_manifest = AUDIT_DIR / "run_manifest.json"
    if not run_manifest.exists():
        return
    if _json(run_manifest).get("scope") != "CAMPAIGN_1_3_CLOSURE_CHECKLIST_GREEN":
        return

    validation = validate_closure_checklist_green_gate(ROOT, AUDIT_DIR)

    assert validation["status"] in {"passed", "failed"}
    if validation["status"] == "failed":
        assert validation["campaign_4_active"] is False
        return
    assert validation["next_safe_action"] == NEXT_ACTION
    assert validation["closure_checklist_green"] is True
    assert validation["campaign_4_active"] is False
