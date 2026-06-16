import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.workbench.campaign5_bridge_acceptance import (
    CAMPAIGN5_FORBIDDEN_PRODUCT_RUNTIME_ACTIONS,
    CAMPAIGN5_REPORT_FILES,
    CAMPAIGN5_STATUS_VALUES,
    build_campaign5_workbench_bridge_evidence,
)


def test_campaign5_bridge_evidence_filters_future_runtime_actions():
    evidence = build_campaign5_workbench_bridge_evidence()

    assert evidence["final_status"] == "campaign5_workbench_bridge_production_grade_accepted_ui_bound"
    assert evidence["accepted"] is True
    assert evidence["core_matrix"]["status"] == "pass"
    assert set(evidence["status_matrix"]["status_values"]) == set(CAMPAIGN5_STATUS_VALUES)

    product_ids = {item["action_id"] for item in evidence["product_enabled_actions"]}
    diagnostic_ids = {item["action_id"] for item in evidence["diagnostic_only_actions"]}
    boundary_ids = {item["action_id"] for item in evidence["explicit_boundary_actions"]}

    assert not (product_ids & CAMPAIGN5_FORBIDDEN_PRODUCT_RUNTIME_ACTIONS)
    assert CAMPAIGN5_FORBIDDEN_PRODUCT_RUNTIME_ACTIONS <= diagnostic_ids
    assert {
        "llm_provider_validate",
        "vector_db_validate",
        "vector_upsert_query_smoke",
        "provider_redaction_check",
        "offline_fallback_status",
    } <= boundary_ids
    assert all(item["ui_state"] == "enabled_real" for item in evidence["product_enabled_actions"])
    assert all(item["ui_state"] == "display_only_diagnostic" for item in evidence["diagnostic_only_actions"])
    assert all(item["ui_state"] == "disabled_boundary" for item in evidence["explicit_boundary_actions"])
    assert evidence["safety_boundaries"]["status"] == "pass"


def test_campaign5_bridge_acceptance_cli_writes_reports(tmp_path):
    output = tmp_path / "campaign5"

    result = CliRunner().invoke(
        app,
        ["campaign5-workbench-bridge-acceptance", "--output", str(output)],
    )

    assert result.exit_code == 0, result.output
    evidence = json.loads((output / "campaign5_workbench_bridge_evidence.json").read_text(encoding="utf-8"))
    assert evidence["final_status"] == "campaign5_workbench_bridge_production_grade_accepted_ui_bound"
    for filename in CAMPAIGN5_REPORT_FILES:
        assert (output / filename).exists(), filename
