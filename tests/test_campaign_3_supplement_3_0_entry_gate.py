import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_campaign_3_supplement_3_0_entry_gate,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "campaign_3_supplement_3_0_entry_gate"
REPORT = RUN_DIR / "campaign_3_supplement_3_0_entry_gate.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
VALIDATION_MANIFEST = ROOT / "docs" / "testing" / "VALIDATION_GATE_MANIFEST.json"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_campaign_3_supplement_3_0_entry_gate_checks_closure_and_plan_scope():
    report = build_campaign_3_supplement_3_0_entry_gate(ROOT)

    assert report["status"] == "passed"
    assert report["verdict"] == "accepted_for_campaign_3_3_0_p0_framework_start"
    assert report["failure_count"] == 0
    assert "artifacts/audits/section_5/campaign_3_supplement_2_0_closure_gate/campaign_3_supplement_2_0_closure_gate.json" in report["reviewed_evidence"]
    assert "External Source Memory & Verification framework" in report["p0_required_markers"]
    assert "Generic Web URL Ingestion" in report["p0_required_markers"]
    assert "OpenCLI External Search Verification" in report["p0_required_markers"]
    assert "Manual Evidence Upload" in report["p0_required_markers"]
    assert "Authenticated Browser Connector Alpha" in report["p1_required_markers"]
    assert "Do not bypass login." in report["safety_markers"]
    assert "Do not save or upload user cookies." in report["safety_markers"]


def test_campaign_3_supplement_3_0_entry_gate_does_not_overclaim_later_states():
    report = build_campaign_3_supplement_3_0_entry_gate(ROOT)
    state = report["campaign_state_after_gate"]
    rules = report["non_substitution_rules"]

    assert state["campaign_3_supplement_2_0_closure_gate_passed"] is True
    assert state["campaign_3_3_0_entry_gate_passed"] is True
    assert state["campaign_3_3_0_business_implementation_active"] is False
    assert state["campaign_3_3_0_accepted"] is False
    assert state["campaign_3_4_0_active"] is False
    assert state["campaign_3_4_0_accepted"] is False
    assert state["campaign_3_accepted"] is False
    assert state["campaign_4_allowed"] is False
    assert state["next_business_item"] == (
        "Campaign 3 Supplement 3.0 P0 External Source Memory & Verification framework"
    )
    assert rules["entry_gate_accepts_campaign_3"] is False
    assert rules["entry_gate_accepts_campaign_3_3_0"] is False
    assert rules["entry_gate_starts_campaign_3_4_0"] is False
    assert rules["entry_gate_opens_campaign_4"] is False
    assert rules["plan_registration_substitutes_business_implementation"] is False
    assert report["final_target_not_downgraded"] is True
    assert report["not_goal_complete"] is True
    assert report["next_required_e2e_step"] == (
        "Run Campaign 3 Supplement 3.0 P0 External Source Memory & Verification framework only."
    )


def test_campaign_3_supplement_3_0_entry_gate_cli_writes_reports(tmp_path):
    output = tmp_path / "entry_gate"
    runner = CliRunner()

    result = runner.invoke(
        app,
        [
            "campaign-3-supplement-3-0-entry-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert result.exit_code == 0, result.output
    assert "status=passed" in result.output
    assert _json(output / "campaign_3_supplement_3_0_entry_gate.json")["status"] == "passed"
    assert _json(output / "run_manifest.json")["status"] == "passed"
    assert (output / "campaign_3_supplement_3_0_entry_gate.md").exists()
    assert (output / "run_summary.md").exists()


def test_campaign_3_supplement_3_0_entry_gate_artifact_is_registered_after_generation():
    if not REPORT.exists():
        return
    report = _json(REPORT)
    run = _json(RUN_MANIFEST)

    assert report["status"] == "passed"
    assert run["scope"] == "CAMPAIGN_3_SUPPLEMENT_3_0_ENTRY_GATE"
    assert run["campaign_state_after_run"]["campaign_3_3_0_entry_gate_passed"] is True
    assert run["campaign_state_after_run"]["campaign_3_3_0_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False


def test_campaign_3_supplement_3_0_entry_gate_is_indexed_and_routed():
    audit_manifest = _json(AUDIT_MANIFEST)
    indexed = {
        run["run_id"]: run
        for run in audit_manifest["runs"]
        if run["run_id"] == "campaign_3_supplement_3_0_entry_gate"
    }
    run = indexed["campaign_3_supplement_3_0_entry_gate"]

    assert run["status"] == "passed"
    assert run["verdict"] == "accepted_for_campaign_3_3_0_p0_framework_start"
    assert run["evidence_dir"] == "artifacts/audits/section_5/campaign_3_supplement_3_0_entry_gate"
    assert "does not accept Supplement 3.0" in run["summary"]

    audit_index = AUDIT_INDEX.read_text(encoding="utf-8")
    assert "`campaign_3_supplement_3_0_entry_gate`" in audit_index
    assert "accepted_for_campaign_3_3_0_p0_framework_start" in audit_index

    validation_manifest = _json(VALIDATION_MANIFEST)
    assert any(
        gate["name"] == "core_fast_campaign_3_supplement_3_0_entry_gate"
        for gate in validation_manifest["gates"]
    )
    assert any(
        rule["name"] == "campaign_3_supplement_3_0_entry_gate"
        for rule in validation_manifest["impact_rules"]
    )
