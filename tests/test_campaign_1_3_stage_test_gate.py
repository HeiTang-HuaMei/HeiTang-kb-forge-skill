import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_campaign_1_3_stage_test_gate,
    validate_campaign_1_3_stage_test_gate,
    write_campaign_1_3_stage_test_gate,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "campaign_1_3_stage_test"
NEXT_ACTION = "Campaign 1-3 Integrated Closure Gate only"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_stage_test_gate_accepts_only_after_fast_stage_tests_pass():
    report = build_campaign_1_3_stage_test_gate(ROOT)

    assert report["status"] == "passed"
    assert report["verdict"] == "accepted_for_campaign_1_3_integrated_closure_gate"
    assert report["implementation_level"] == "bounded industrial-grade stage test gate"
    assert report["stage_test_result_matrix"]["status"] == "passed"
    assert report["stage_test_result_matrix"]["passed_count"] > 0
    assert report["stage_test_coverage_matrix"]["status"] == "passed"
    assert report["json_parse_matrix"]["status"] == "passed"
    assert report["git_diff_check_matrix"]["status"] == "passed"
    assert report["failure_count"] == 0


def test_stage_test_gate_allows_only_integrated_closure_next():
    report = build_campaign_1_3_stage_test_gate(ROOT)
    state = report["campaign_state_after_gate"]
    next_action = report["next_action_manifest"]
    rules = report["non_substitution_rules"]

    assert state["campaign_1_3_stage_test_gate_passed"] is True
    assert state["campaign_1_3_integrated_closure_gate_passed"] is False
    assert state["closure_pack_generated"] is False
    assert state["repository_push_succeeded"] is False
    assert state["tag_created"] is False
    assert state["ci_green"] is False
    assert state["campaign_4_active"] is False
    assert state["campaign_5_active"] is False
    assert state["agent_runtime_ready"] is False
    assert state["bridge_execution_accepted"] is False
    assert next_action["next_safe_action"] == NEXT_ACTION
    assert next_action["may_enter_integrated_closure"] is True
    assert next_action["may_generate_closure_pack"] is False
    assert next_action["may_push"] is False
    assert next_action["may_enter_campaign_4"] is False
    assert rules["stage_test_is_full_gate"] is False
    assert rules["stage_test_starts_campaign_4"] is False


def test_stage_test_gate_writes_required_audit_outputs(tmp_path):
    output = tmp_path / "stage-test"
    report = write_campaign_1_3_stage_test_gate(ROOT, output)

    assert report["status"] == "passed"
    for name in [
        "run_manifest.json",
        "campaign_1_3_stage_test_gate.json",
        "campaign_1_3_stage_test_gate.md",
        "stage_test_result_matrix.json",
        "stage_test_coverage_matrix.json",
        "stage_test_boundary_matrix.json",
        "validation_report.json",
        "checkpoint.json",
        "progress_events.jsonl",
        "run_summary.md",
    ]:
        assert (output / name).exists()

    assert _json(output / "run_manifest.json")["scope"] == "CAMPAIGN_1_3_STAGE_TEST_GATE"
    assert _json(output / "checkpoint.json")["checkpoint_id"] == "campaign_1_3_stage_test_gate_passed"
    assert _json(output / "checkpoint.json")["next_safe_action"] == NEXT_ACTION


def test_stage_test_gate_fails_closed_when_output_is_overclaimed(tmp_path):
    output = tmp_path / "stage-test"
    write_campaign_1_3_stage_test_gate(ROOT, output)
    report_path = output / "campaign_1_3_stage_test_gate.json"
    report = _json(report_path)
    report["campaign_state_after_gate"]["campaign_4_active"] = True
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    validation = validate_campaign_1_3_stage_test_gate(ROOT, output)

    assert validation["status"] == "failed"
    assert "overclaimed_state:campaign_4_active" in validation["errors"]


def test_stage_test_gate_cli_build_and_validate_are_runnable(tmp_path):
    output = tmp_path / "stage-test"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "campaign-1-3-stage-test-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-campaign-1-3-stage-test-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "status=passed" in build.output
    assert "accepted_for_campaign_1_3_integrated_closure_gate" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    assert _json(output / "validation_report.json")["status"] == "passed"


def test_active_stage_test_audit_outputs_validate_when_present():
    run_manifest = AUDIT_DIR / "run_manifest.json"
    if not run_manifest.exists():
        return
    if _json(run_manifest).get("scope") != "CAMPAIGN_1_3_STAGE_TEST_GATE":
        return

    validation = validate_campaign_1_3_stage_test_gate(ROOT, AUDIT_DIR)

    assert validation["status"] == "passed"
    assert validation["next_safe_action"] == NEXT_ACTION
    assert validation["campaign_1_3_stage_test_gate_passed"] is True
    assert validation["campaign_1_3_integrated_closure_gate_passed"] is False
    assert validation["campaign_4_active"] is False
