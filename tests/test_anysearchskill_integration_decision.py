import json
from pathlib import Path

from tests.external_registry_helpers import load_external_capability_registry


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "anysearchskill_provider_adapter"
DECISION = RUN_DIR / "anysearchskill_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "anysearchskill_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
REAL_SMOKE = RUN_DIR / "real_smoke" / "anysearch_provider_smoke.json"
SOURCE_TRACE = RUN_DIR / "real_smoke" / "source_trace.json"
REAL_RUN = RUN_DIR / "real_run" / "anysearch_retrieval_result.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"

def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_anysearch_decision_preserves_real_smoke_and_strengthening_gaps():
    decision = _json(DECISION)
    smoke = _json(REAL_SMOKE)
    trace = _json(SOURCE_TRACE)
    real_run = _json(REAL_RUN)

    assert decision["project_id"] == "anysearchskill"
    assert decision["section"] == "5.3"
    assert decision["decision"] == "needs_strengthening"
    assert decision["integration_mode"] == "provider_adapter"
    assert decision["core_adapter_implemented"] is True
    assert decision["vendor_runtime_integrated"] is False
    assert decision["external_code_copied"] is False
    assert decision["runtime_contract"]["api_key_optional"] is True
    assert decision["runtime_contract"]["api_key_storage"] == "environment_only"
    assert smoke["status"] == "passed"
    assert smoke["runtime_status"] == "available"
    assert smoke["smoke_status"] == "passed"
    assert smoke["anonymous_mode"] is True
    assert smoke["network_called"] is True
    assert smoke["result_count"] > 0
    assert smoke["secrets_persisted"] is False
    assert trace["source_count"] == smoke["result_count"]
    assert real_run["status"] == "passed"
    assert real_run["runtime_status"] == "available"
    assert real_run["network_called"] is True
    assert real_run["result_count"] > 0
    assert real_run["secrets_persisted"] is False


def test_anysearch_ui_status_is_truthful_and_not_ui_complete():
    ui = _json(UI_IMPACT)
    registry = load_external_capability_registry(ROOT)
    project = next(item for item in registry["projects"] if item["project_id"] == "anysearchskill")

    assert ui["integration_decision"] == "needs_strengthening"
    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["check_action_available"] is False
    assert ui["current_ui_state"]["smoke_action_available"] is False
    assert ui["current_ui_state"]["run_action_available"] is False
    assert ui["current_ui_state"]["blocked_reason"] == "ui_configuration_pending"
    assert project["contract_status"] == [
        "provider_adapter",
        "real_smoke_passed",
        "needs_strengthening",
    ]
    assert project["implemented"] is True
    assert project["ready"] is False
    assert project["local_ready"] is False
    assert project["executable_action"] is False
    assert project["requires_api_key"] is False
    assert project["requires_network"] is True
    assert project["blocked_reason"] == "ui_configuration_pending"


def test_anysearch_run_is_governed_and_does_not_accept_campaign_3():
    run = _json(RUN_MANIFEST)
    manifest = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in manifest["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert run["status"] == "passed"
    assert run["integration_decision"] == "needs_strengthening"
    assert run["campaign_state_after_run"]["campaign_3_item_5_3"] == "advanced_needs_strengthening"
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == "5.4 n8n"
    assert runs["anysearchskill_provider_adapter"]["scope"] == "SECTION_5_ITEM_5_3_ANYSEARCHSKILL"
    assert runs["anysearchskill_provider_adapter"]["integration_decision"] == "needs_strengthening"
    assert "anysearchskill_provider_adapter" in index
    assert "Next Section 5 item: `5.13 mattpocock/skills`" in plan
    assert "Campaign 3 accepted: `false`" in plan


def test_anysearch_non_downgrade_fields_are_present():
    for payload in [_json(DECISION), _json(UI_IMPACT), _json(RUN_MANIFEST)]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"].strip()
        assert payload["not_goal_complete"] is True
