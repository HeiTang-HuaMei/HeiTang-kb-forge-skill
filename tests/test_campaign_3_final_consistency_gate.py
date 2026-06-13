import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_campaign_3_final_consistency_gate,
    validate_campaign_3_final_consistency_gate,
    write_campaign_3_final_consistency_gate,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "campaign_3_final_consistency"
NEXT_ACTION = "Run Campaign 1-3 Stage Test Gate only."


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_final_consistency_accepts_campaign_3_after_required_evidence():
    report = build_campaign_3_final_consistency_gate(ROOT)

    assert report["status"] == "passed"
    assert report["verdict"] == "accepted_for_campaign_1_3_stage_test_gate"
    assert report["implementation_level"] == "bounded industrial-grade final consistency gate"
    assert report["campaign_3_mainline_matrix"]["item_count"] == 17
    assert report["campaign_3_mainline_matrix"]["status"] == "passed"
    assert report["supplement_consistency_matrix"]["status"] == "passed"
    assert report["product_output_surface_matrix"]["status"] == "passed"
    assert report["external_reference_boundary_matrix"]["status"] == "passed"
    assert report["failure_count"] == 0


def test_final_consistency_preserves_product_output_surface_boundaries():
    report = build_campaign_3_final_consistency_gate(ROOT)
    surface = report["product_output_surface_matrix"]
    surface_ids = {item["surface_id"] for item in surface["surfaces"]}

    assert surface_ids == {
        "knowledge_package",
        "document_outputs",
        "skill_outputs",
        "agent_creation_package",
    }
    assert surface["generate_documents_existing_core_capability"] is True
    assert surface["document_output_formats"] == [
        "Markdown",
        "DOCX / Word",
        "PDF",
        "PPTX / PowerPoint",
    ]


def test_final_consistency_keeps_external_references_not_integrated():
    report = build_campaign_3_final_consistency_gate(ROOT)

    for item in report["external_reference_boundary_matrix"]["items"]:
        assert item["status"] == "passed"
        assert item["implementation_mode"] == "not_integrated"
        assert item["integration_status"] in {"needs_verification", "reference_only"}


def test_final_consistency_allows_only_stage_test_next():
    report = build_campaign_3_final_consistency_gate(ROOT)
    state = report["campaign_state_after_gate"]
    next_action = report["next_action_manifest"]
    rules = report["non_substitution_rules"]

    assert state["campaign_3_final_consistency_gate_passed"] is True
    assert state["campaign_3_accepted"] is True
    assert state["campaign_1_3_stage_test_gate_passed"] is False
    assert state["campaign_1_3_integrated_closure_gate_passed"] is False
    assert state["repository_push_succeeded"] is False
    assert state["tag_created"] is False
    assert state["ci_green"] is False
    assert state["campaign_4_active"] is False
    assert state["campaign_5_active"] is False
    assert state["agent_runtime_ready"] is False
    assert state["bridge_execution_accepted"] is False
    assert next_action["next_safe_action"] == NEXT_ACTION
    assert next_action["may_enter_campaign_1_3_stage_test_gate"] is True
    assert next_action["may_enter_integrated_closure"] is False
    assert next_action["may_push"] is False
    assert next_action["may_enter_campaign_4"] is False
    assert rules["final_consistency_starts_stage_test"] is False
    assert rules["final_consistency_starts_campaign_4"] is False


def test_final_consistency_writes_required_audit_outputs(tmp_path):
    output = tmp_path / "final-consistency"
    report = write_campaign_3_final_consistency_gate(ROOT, output)

    assert report["status"] == "passed"
    for name in [
        "run_manifest.json",
        "campaign_3_final_consistency_gate.json",
        "campaign_3_final_consistency_gate.md",
        "campaign_3_final_consistency_matrix.json",
        "campaign_3_mainline_matrix.json",
        "supplement_consistency_matrix.json",
        "product_output_surface_matrix.json",
        "external_reference_boundary_matrix.json",
        "status_boundary_matrix.json",
        "validation_report.json",
        "checkpoint.json",
        "progress_events.jsonl",
        "run_summary.md",
    ]:
        assert (output / name).exists()

    assert _json(output / "run_manifest.json")["scope"] == "CAMPAIGN_3_FINAL_CONSISTENCY_GATE"
    assert _json(output / "checkpoint.json")["checkpoint_id"] == "campaign_3_final_consistency_gate_passed"
    assert _json(output / "checkpoint.json")["next_safe_action"] == NEXT_ACTION


def test_final_consistency_fails_closed_when_output_is_overclaimed(tmp_path):
    output = tmp_path / "final-consistency"
    write_campaign_3_final_consistency_gate(ROOT, output)
    report_path = output / "campaign_3_final_consistency_gate.json"
    report = _json(report_path)
    report["campaign_state_after_gate"]["campaign_4_active"] = True
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    validation = validate_campaign_3_final_consistency_gate(ROOT, output)

    assert validation["status"] == "failed"
    assert "overclaimed_state:campaign_4_active" in validation["errors"]


def test_final_consistency_cli_build_and_validate_are_runnable(tmp_path):
    output = tmp_path / "final-consistency"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "campaign-3-final-consistency-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-campaign-3-final-consistency-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "status=passed" in build.output
    assert "accepted_for_campaign_1_3_stage_test_gate" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    assert _json(output / "validation_report.json")["status"] == "passed"


def test_active_final_consistency_audit_outputs_validate_when_present():
    run_manifest = AUDIT_DIR / "run_manifest.json"
    if not run_manifest.exists():
        return
    if _json(run_manifest).get("scope") != "CAMPAIGN_3_FINAL_CONSISTENCY_GATE":
        return

    validation = validate_campaign_3_final_consistency_gate(ROOT, AUDIT_DIR)

    assert validation["status"] == "passed"
    assert validation["next_safe_action"] == NEXT_ACTION
    assert validation["campaign_3_final_consistency_gate_passed"] is True
    assert validation["campaign_3_accepted"] is True
    assert validation["campaign_4_active"] is False
