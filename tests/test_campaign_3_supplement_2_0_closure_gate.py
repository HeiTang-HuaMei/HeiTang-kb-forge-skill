import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    CAMPAIGN_3_SUPPLEMENT_2_0_ITEMS,
    build_campaign_3_supplement_2_0_closure_gate,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "campaign_3_supplement_2_0_closure_gate"
REPORT = RUN_DIR / "campaign_3_supplement_2_0_closure_gate.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_campaign_3_supplement_2_0_closure_gate_reviews_required_items():
    report = build_campaign_3_supplement_2_0_closure_gate(ROOT)
    items = {item["item_id"]: item for item in report["items"]}

    assert report["status"] == "passed"
    assert report["verdict"] == "accepted_for_transition_to_campaign_3_3_0_entry_gate"
    assert report["reviewed_item_count"] == 11
    assert report["required_item_count"] == len(CAMPAIGN_3_SUPPLEMENT_2_0_ITEMS)
    assert set(items) == {
        "5.7",
        "5.8",
        "5.9",
        "5.10",
        "5.11",
        "5.12",
        "5.13",
        "5.14",
        "5.S1",
        "5.S2",
        "5.S3",
    }
    assert all(item["status"] == "passed" for item in report["items"])
    assert items["5.S3"]["run_id"] == "obsidian_vault_strengthening"
    assert items["5.S3"]["decision"] == "real_integration"
    assert items["5.S3"]["decision_qualifier"] == "local_vault_adapter_only"


def test_campaign_3_supplement_2_0_closure_gate_does_not_overclaim_later_states():
    report = build_campaign_3_supplement_2_0_closure_gate(ROOT)
    state = report["campaign_state_after_gate"]
    rules = report["non_substitution_rules"]

    assert state["campaign_3_supplement_2_0_closure_gate_passed"] is True
    assert state["campaign_3_accepted"] is False
    assert state["campaign_3_3_0_active"] is False
    assert state["campaign_3_4_0_active"] is False
    assert state["campaign_4_allowed"] is False
    assert state["next_business_item"] == "Campaign 3 Supplement 3.0 Entry Gate"
    assert rules["closure_gate_accepts_campaign_3"] is False
    assert rules["closure_gate_starts_campaign_3_3_0_business_implementation"] is False
    assert rules["closure_gate_starts_campaign_3_4_0"] is False
    assert rules["closure_gate_opens_campaign_4"] is False
    assert rules["focused_tests_substitute_full_gate"] is False
    assert report["final_target_not_downgraded"] is True
    assert report["not_goal_complete"] is True
    assert report["next_required_e2e_step"] == "Run Campaign 3 Supplement 3.0 Entry Gate only."


def test_campaign_3_supplement_2_0_closure_gate_cli_writes_reports(tmp_path):
    output = tmp_path / "closure"
    runner = CliRunner()

    result = runner.invoke(
        app,
        [
            "campaign-3-supplement-2-0-closure-gate",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert result.exit_code == 0, result.output
    assert "status=passed" in result.output
    assert _json(output / "campaign_3_supplement_2_0_closure_gate.json")["status"] == "passed"
    assert _json(output / "run_manifest.json")["status"] == "passed"
    assert (output / "campaign_3_supplement_2_0_closure_gate.md").exists()
    assert (output / "run_summary.md").exists()


def test_campaign_3_supplement_2_0_closure_gate_artifact_is_registered_after_generation():
    if not REPORT.exists():
        return
    report = _json(REPORT)
    run = _json(RUN_MANIFEST)

    assert report["status"] == "passed"
    assert run["scope"] == "CAMPAIGN_3_SUPPLEMENT_2_0_CLOSURE_GATE"
    assert run["campaign_state_after_run"]["campaign_3_supplement_2_0_closure_gate_passed"] is True
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
