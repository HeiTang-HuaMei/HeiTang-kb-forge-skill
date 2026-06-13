import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    SUPPLEMENT_3_0_EVIDENCE,
    build_campaign_3_supplement_3_0_acceptance_gate,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = (
    ROOT
    / "artifacts"
    / "audits"
    / "section_5"
    / "campaign_3_supplement_3_0_acceptance_gate"
)
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
VALIDATION_MANIFEST = ROOT / "docs" / "testing" / "VALIDATION_GATE_MANIFEST.json"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_acceptance_gate_reviews_every_locked_evidence_bundle_and_capability():
    report = build_campaign_3_supplement_3_0_acceptance_gate(ROOT)

    assert report["status"] == "passed"
    assert report["verdict"] == "accepted_for_pre_4_0_workspace_partition_foundation_gate"
    assert report["reviewed_bundle_count"] == len(SUPPLEMENT_3_0_EVIDENCE) == 10
    assert report["failure_count"] == 0
    assert all(item["status"] == "passed" for item in report["bundles"])
    assert all(item["status"] == "passed" for item in report["capability_checks"])
    assert report["test_contract"]["status"] == "passed"


def test_acceptance_gate_stops_before_pre_4_0_and_all_later_campaigns():
    report = build_campaign_3_supplement_3_0_acceptance_gate(ROOT)
    state = report["campaign_state_after_gate"]
    rules = report["non_substitution_rules"]

    assert state["campaign_3_supplement_3_0_acceptance_gate_passed"] is True
    assert state["supplement_3_0_complete"] is True
    assert state["campaign_3_3_0_accepted"] is True
    assert state["pre_4_0_workspace_partition_active"] is False
    assert state["pre_4_0_workspace_partition_complete"] is False
    assert state["campaign_3_4_0_active"] is False
    assert state["campaign_3_accepted"] is False
    assert state["campaign_4_allowed"] is False
    assert state["campaign_4_active"] is False
    assert state["campaign_9_active"] is False
    assert state["final_release_allowed"] is False
    assert state["next_business_item"] == (
        "Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate"
    )
    assert rules["supplement_3_0_acceptance_starts_pre_4_0"] is False
    assert rules["supplement_3_0_acceptance_starts_supplement_4_0"] is False
    assert rules["supplement_3_0_acceptance_opens_campaign_4"] is False
    assert rules["allowlist_registration_is_campaign_5_acceptance"] is False
    assert report["next_required_e2e_step"] == (
        "Run Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate only."
    )
    assert report["not_goal_complete"] is True


def test_acceptance_gate_cli_writes_machine_and_human_reports(tmp_path):
    output = tmp_path / "acceptance"
    result = CliRunner().invoke(
        app,
        [
            "campaign-3-supplement-3-0-acceptance-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert result.exit_code == 0, result.output
    assert "status=passed" in result.output
    assert _json(output / "campaign_3_supplement_3_0_acceptance_gate.json")["status"] == "passed"
    assert _json(output / "campaign_3_supplement_3_0_acceptance_matrix.json")["status"] == "passed"
    assert _json(output / "run_manifest.json")["campaign_state_after_run"][
        "pre_4_0_workspace_partition_active"
    ] is False
    assert (output / "campaign_3_supplement_3_0_acceptance_gate.md").exists()
    assert (output / "run_summary.md").exists()


def test_acceptance_gate_fails_closed_when_evidence_root_is_absent(tmp_path):
    report = build_campaign_3_supplement_3_0_acceptance_gate(tmp_path)

    assert report["status"] == "failed"
    assert report["verdict"] == "failed"
    assert report["failure_count"] > 0
    assert report["campaign_state_after_gate"]["supplement_3_0_complete"] is False
    assert report["campaign_state_after_gate"]["campaign_4_allowed"] is False


def test_generated_acceptance_artifact_preserves_stop_boundary():
    if not RUN_DIR.exists():
        return
    report = _json(RUN_DIR / "campaign_3_supplement_3_0_acceptance_gate.json")
    run = _json(RUN_DIR / "run_manifest.json")

    assert report["status"] == "passed"
    assert run["scope"] == "CAMPAIGN_3_SUPPLEMENT_3_0_ACCEPTANCE_GATE"
    assert run["campaign_state_after_run"]["supplement_3_0_complete"] is True
    assert run["campaign_state_after_run"]["pre_4_0_workspace_partition_active"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False


def test_acceptance_gate_is_indexed_and_routed_to_fast_gate():
    audit = _json(AUDIT_MANIFEST)
    indexed = {
        run["run_id"]: run
        for run in audit["runs"]
        if run["run_id"] == "campaign_3_supplement_3_0_acceptance_gate"
    }
    run = indexed["campaign_3_supplement_3_0_acceptance_gate"]

    assert run["status"] == "passed"
    assert run["verdict"] == "accepted_for_pre_4_0_workspace_partition_foundation_gate"
    assert run["evidence_dir"] == (
        "artifacts/audits/section_5/campaign_3_supplement_3_0_acceptance_gate"
    )
    assert "`campaign_3_supplement_3_0_acceptance_gate`" in AUDIT_INDEX.read_text(
        encoding="utf-8"
    )

    validation = _json(VALIDATION_MANIFEST)
    assert any(
        gate["name"] == "core_fast_campaign_3_supplement_3_0_acceptance_gate"
        for gate in validation["gates"]
    )
    assert any(
        rule["name"] == "campaign_3_supplement_3_0_acceptance_gate"
        for rule in validation["impact_rules"]
    )
