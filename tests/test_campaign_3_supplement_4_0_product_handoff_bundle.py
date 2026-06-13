import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_campaign_3_supplement_4_0_product_handoff_bundle,
    validate_campaign_3_supplement_4_0_product_handoff_bundle,
    write_campaign_3_supplement_4_0_product_handoff_bundle,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "section_5" / "campaign_3_supplement_4_0_product_handoff_bundle"
NEXT_ACTION = "Campaign 3 Supplement 4.0 Acceptance Gate only"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_product_handoff_bundle_builds_all_d_i_stage_contracts():
    report = build_campaign_3_supplement_4_0_product_handoff_bundle(ROOT)
    stages = {item["stage_id"]: item for item in report["stage_status_matrix"]["stages"]}

    assert report["status"] == "passed"
    assert report["implementation_level"] == "bounded industrial-grade implementation"
    assert report["decision_qualifier"] == "product_handoff_contract_bundle_only"
    for required in [
        "4_0d_agent_package",
        "4_0e_workspace_binding",
        "4_0f_memory_isolation",
        "4_0g_single_multi_agent_mode",
        "4_0h_campaign_4_ui_handoff",
        "4_0i_campaign_5_bridge_handoff",
    ]:
        assert stages[required]["status"] == "passed"


def test_product_handoff_bundle_preserves_runtime_and_future_campaign_boundaries():
    report = build_campaign_3_supplement_4_0_product_handoff_bundle(ROOT)
    state = report["campaign_state_after_step"]
    flags = report["boundary_matrix"]["flags"]
    ui_handoff = report["campaign_4_ui_handoff_contract"]
    bridge_handoff = report["campaign_5_bridge_handoff_contract"]
    memory_spec = report["memory_isolation_spec"]
    memory_backend = report["memory_backend_matrix"]

    assert state["campaign_3_supplement_4_0_d_i_bundle_passed"] is True
    assert state["campaign_3_supplement_4_0_acceptance_gate_passed"] is False
    assert state["campaign_4_active"] is False
    assert state["campaign_4_ui_complete"] is False
    assert state["campaign_5_active"] is False
    assert state["bridge_execution_accepted"] is False
    assert state["agent_runtime_ready"] is False
    assert state["agent_executable"] is False
    assert state["redis_runtime_ready"] is False
    assert state["vector_runtime_ready"] is False
    assert state["multi_agent_runtime_ready"] is False
    assert all(value is False for value in flags.values())
    assert ui_handoff["campaign_4_active"] is False
    assert ui_handoff["ui_handoff_is_campaign_4_completion"] is False
    assert bridge_handoff["campaign_5_active"] is False
    assert bridge_handoff["bridge_handoff_is_campaign_5_completion"] is False
    assert bridge_handoff["future_allowlist_candidates_active"] is False
    assert memory_spec["agent_short_term_redis_runtime_ready"] is False
    assert memory_spec["agent_long_term_vector_runtime_ready"] is False
    assert memory_backend["redis_roles"]["runtime_ready"] is False
    assert memory_backend["vector_db_roles"]["runtime_ready"] is False


def test_product_handoff_bundle_ui_and_bridge_contracts_are_display_handoff_only():
    report = build_campaign_3_supplement_4_0_product_handoff_bundle(ROOT)
    cards = {card["card_id"]: card for card in report["ui_task_card_inputs"]["cards"]}
    candidates = report["future_agent_bridge_action_candidates"]
    missing = report["bridge_missing_action_matrix"]

    assert len(report["campaign_4_ui_handoff_contract"]["top_level_navigation"]) <= 7
    assert cards["agent_package"]["primary_button"] == "continue"
    assert cards["multi_agent_workflow"]["current_status"] == "planned_not_active"
    assert cards["memory"]["current_status"] == "display_only"
    assert candidates["implementation_mode"] == "not_integrated"
    assert candidates["current_allowlist_added"] is False
    assert all(item["runtime_active"] is False for item in candidates["candidates"])
    assert missing["bridge_execution_accepted"] is False
    assert "generate-agent-package" in missing["missing_current_actions"]


def test_write_outputs_include_required_product_and_bridge_contracts(tmp_path):
    output = tmp_path / "handoff_bundle"
    report = write_campaign_3_supplement_4_0_product_handoff_bundle(ROOT, output)

    assert report["status"] == "passed"
    for name in [
        "run_manifest.json",
        "run_summary.md",
        "stage_status_matrix.json",
        "boundary_matrix.json",
        "validation_report.json",
        "checkpoint.json",
        "progress_events.jsonl",
    ]:
        assert (output / name).exists()

    for name in [
        "docs/product/AGENT_WORKSPACE_BINDING_SPEC.json",
        "docs/product/AGENT_MEMORY_ISOLATION_SPEC.json",
        "docs/product/AGENT_MODE_SPEC.md",
        "docs/product/CAMPAIGN_4_UI_HANDOFF_CONTRACT.json",
        "docs/bridge/CAMPAIGN_5_BRIDGE_HANDOFF_CONTRACT.json",
        "docs/bridge/FUTURE_AGENT_BRIDGE_ACTION_CANDIDATES.json",
    ]:
        assert (ROOT / name).exists()

    assert _json(output / "checkpoint.json")["next_safe_action"] == NEXT_ACTION


def test_product_handoff_validation_detects_campaign_4_overclaim(tmp_path):
    output = tmp_path / "handoff_bundle"
    write_campaign_3_supplement_4_0_product_handoff_bundle(ROOT, output)
    ui_path = ROOT / "docs" / "product" / "CAMPAIGN_4_UI_HANDOFF_CONTRACT.json"
    ui_handoff = _json(ui_path)
    original = dict(ui_handoff)
    try:
        ui_handoff["campaign_4_active"] = True
        ui_path.write_text(json.dumps(ui_handoff, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        validation = validate_campaign_3_supplement_4_0_product_handoff_bundle(ROOT, output)
    finally:
        ui_path.write_text(json.dumps(original, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    assert validation["status"] == "failed"
    assert "ui_handoff_overclaims_campaign_4" in validation["errors"]


def test_product_handoff_bundle_cli_build_and_validate_are_runnable(tmp_path):
    output = tmp_path / "handoff_bundle"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "campaign-3-supplement-4-0-product-handoff-bundle",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-campaign-3-supplement-4-0-product-handoff-bundle",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "product_handoff_contract_bundle_only" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    assert _json(output / "validation_report.json")["status"] == "passed"


def test_active_product_handoff_audit_outputs_validate_when_present():
    if not AUDIT_DIR.exists():
        return

    validation = validate_campaign_3_supplement_4_0_product_handoff_bundle(ROOT, AUDIT_DIR)

    assert validation["status"] == "passed"
    assert validation["next_safe_action"] == NEXT_ACTION
    assert validation["campaign_3_supplement_4_0_acceptance_gate_passed"] is False
    assert validation["campaign_4_active"] is False
    assert validation["campaign_5_active"] is False
