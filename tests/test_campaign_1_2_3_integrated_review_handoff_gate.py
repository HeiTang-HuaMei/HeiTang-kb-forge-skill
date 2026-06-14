import json
import subprocess
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_campaign_1_2_3_integrated_review_handoff_gate,
    validate_campaign_1_2_3_integrated_review_handoff_gate,
    write_closure_checklist_green_gate,
    write_campaign_1_2_3_integrated_review_handoff_gate,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "campaign_1_2_3_review_handoff"
NEXT_ACTION = "Open a new conversation and start Campaign 4 Entry Gate only"
ALLOWED_STATUSES = {
    "real_integration",
    "reference_only",
    "planned_not_active",
    "needs_verification",
    "stopped_or_rejected",
}


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _ensure_closure_checklist_green() -> None:
    write_closure_checklist_green_gate(ROOT, ROOT / "artifacts" / "audits" / "campaign_1_3_closure_checklist")


def test_review_handoff_requires_green_closure_checklist_and_keeps_campaign_4_inactive():
    _ensure_closure_checklist_green()
    report = build_campaign_1_2_3_integrated_review_handoff_gate(ROOT)
    state = report["campaign_state_after_gate"]

    assert report["status"] in {"passed", "failed"}
    if report["status"] == "failed":
        assert "final_commit_not_equal_pushed_baseline_rc_commit" in report["failures"]
        assert state["campaign_4_active"] is False
        assert state["github_release_created"] is False
        return
    assert report["verdict"] == "accepted_for_campaign_4_entry_gate_new_conversation"
    assert report["tag_name"] == "campaign-1-3-baseline-rc.3"
    assert report["ci_status"]["conclusion"] == "success"
    assert report["release_check_status"]["conclusion"] == "success"
    assert state["closure_checklist_green"] is True
    assert state["campaign_1_3_review_handoff_gate_passed"] is True
    assert state["campaign_4_entry_gate_allowed"] is True
    assert state["campaign_4_active"] is False
    assert state["github_release_created"] is False
    assert report["next_action_manifest"]["next_safe_action"] == NEXT_ACTION


def test_review_handoff_external_project_statuses_and_future_boundaries_are_truthful():
    _ensure_closure_checklist_green()
    report = build_campaign_1_2_3_integrated_review_handoff_gate(ROOT)
    rows = {row["project_name"]: row for row in report["external_project_rows"]}

    assert {row["integration_status"] for row in report["external_project_rows"]} <= ALLOWED_STATUSES
    assert rows["LLM Wiki v2"]["integration_status"] == "real_integration"
    assert "Campaign 3 Section 5.1" in rows["LLM Wiki v2"]["campaign_section"]
    assert rows["andrej-karpathy-skills"]["integration_status"] == "reference_only"
    assert rows["andrej-karpathy-skills"]["implementation_mode"] == "not_integrated"
    assert rows["Presenton"]["implementation_mode"] == "not_integrated"
    assert rows["Presenton"]["runtime_dependency_added"] is False
    assert rows["CodeGraph"]["implementation_mode"] == "not_integrated"
    assert rows["Understand Anything"]["implementation_mode"] == "not_integrated"
    assert rows["NVlabs/LongLive"]["integration_status"] == "stopped_or_rejected"
    assert "No current target" in rows["NVlabs/LongLive"]["future_target"]
    assert rows["pi-mono"]["implementation_mode"] == "not_integrated"
    assert rows["claude-plugins-official"]["implementation_mode"] == "not_integrated"
    assert rows["Redis / Vector DB / external database-backed Memory Store Connector"]["integration_status"] == "planned_not_active"
    assert rows["Redis / Vector DB / external database-backed Memory Store Connector"]["future_target"] == "Campaign 8"


def test_review_handoff_capability_matrix_lists_four_product_output_surfaces():
    _ensure_closure_checklist_green()
    report = build_campaign_1_2_3_integrated_review_handoff_gate(ROOT)
    surfaces = {row["surface"]: row for row in report["capability_rows"]}

    assert {"knowledge_package", "document_outputs", "skill_outputs", "agent_creation_package"} <= set(surfaces)
    assert "Markdown / DOCX / PDF / PPTX" in surfaces["document_outputs"]["capability"]
    assert "not covered by Skill Outputs" in surfaces["document_outputs"]["boundary"]
    assert "Agent Runtime" in surfaces["agent_creation_package"]["boundary"]


def test_review_handoff_writes_required_reports_and_current_run_handoff(tmp_path):
    _ensure_closure_checklist_green()
    output = tmp_path / "review-handoff"
    report = write_campaign_1_2_3_integrated_review_handoff_gate(ROOT, output)

    assert report["status"] in {"passed", "failed"}
    for name in [
        "run_manifest.json",
        "run_summary.md",
        "integrated_review_handoff_report.json",
        "validation_report.json",
        "checkpoint.json",
        "progress_events.jsonl",
        "CAMPAIGN_1_2_3_INTEGRATED_REVIEW_REPORT.md",
        "CAMPAIGN_1_2_3_EXTERNAL_PROJECT_INTEGRATION_REVIEW.md",
        "CAMPAIGN_1_2_3_CAPABILITY_REVIEW_MATRIX.md",
        "new_conversation_handoff_prompt.md",
        "campaign_1_2_3_handoff_manifest.json",
    ]:
        assert (output / name).exists()

    assert _json(output / "run_manifest.json")["scope"] == "CAMPAIGN_1_2_3_INTEGRATED_REVIEW_HANDOFF_GATE"
    tracked = subprocess.run(["git", "ls-files"], cwd=ROOT, text=True, capture_output=True, check=True).stdout.splitlines()
    assert not any(path.startswith("docs/governance/") for path in tracked)
    checkpoint = _json(output / "checkpoint.json")
    if report["status"] == "passed":
        assert checkpoint["checkpoint_id"] == "campaign_1_2_3_integrated_review_handoff_gate_passed"
        assert checkpoint["next_safe_action"] == NEXT_ACTION
    else:
        assert checkpoint["checkpoint_id"] == "campaign_1_2_3_integrated_review_handoff_gate_failed"


def test_review_handoff_validation_fails_closed_on_external_runtime_overclaim(tmp_path):
    _ensure_closure_checklist_green()
    output = tmp_path / "review-handoff"
    write_campaign_1_2_3_integrated_review_handoff_gate(ROOT, output)
    report_path = output / "integrated_review_handoff_report.json"
    report = _json(report_path)
    for row in report["external_project_rows"]:
        if row["project_name"] == "Presenton":
            row["runtime_dependency_added"] = True
            break
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    validation = validate_campaign_1_2_3_integrated_review_handoff_gate(ROOT, output)

    assert validation["status"] == "failed"
    assert "external_reference_overclaimed:Presenton" in validation["errors"]


def test_review_handoff_cli_build_and_validate_are_runnable(tmp_path):
    _ensure_closure_checklist_green()
    output = tmp_path / "review-handoff"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "campaign-1-2-3-integrated-review-handoff-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-campaign-1-2-3-integrated-review-handoff-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "status=" in build.output
    if "status=passed" in build.output:
        assert "accepted_for_campaign_4_entry_gate_new_conversation" in build.output
        assert validate.exit_code == 0, validate.output
        assert "status=passed" in validate.output
    else:
        assert "status=failed" in validate.output


def test_active_review_handoff_outputs_validate_when_present():
    run_manifest = AUDIT_DIR / "run_manifest.json"
    if not run_manifest.exists():
        return
    if _json(run_manifest).get("scope") != "CAMPAIGN_1_2_3_INTEGRATED_REVIEW_HANDOFF_GATE":
        return

    validation = validate_campaign_1_2_3_integrated_review_handoff_gate(ROOT, AUDIT_DIR)

    assert validation["status"] in {"passed", "failed"}
    if validation["status"] == "failed":
        assert validation["campaign_4_active"] is False
        return
    assert validation["next_safe_action"] == NEXT_ACTION
    assert validation["campaign_1_3_review_handoff_gate_passed"] is True
    assert validation["campaign_4_entry_gate_allowed"] is True
    assert validation["campaign_4_active"] is False
