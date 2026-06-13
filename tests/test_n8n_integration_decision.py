import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "n8n_workflow_export"
DECISION = RUN_DIR / "n8n_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "n8n_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
EXPORT_DIR = RUN_DIR / "export"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
UI_REGISTRY = (
    ROOT.parent
    / "kb-forge-skill-ui"
    / "web"
    / "workbench"
    / "flutter_app"
    / "assets"
    / "external"
    / "external_capability_registry.json"
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_n8n_decision_is_real_export_integration_without_runtime_claims():
    decision = _json(DECISION)
    validation = _json(EXPORT_DIR / "n8n_export_validation.json")
    manifest = _json(EXPORT_DIR / "external_automation_manifest.json")

    assert decision["project_id"] == "n8n"
    assert decision["section"] == "5.4"
    assert decision["decision"] == "real_integration"
    assert decision["integration_mode"] == "workflow_export"
    assert decision["core_export_adapter_implemented"] is True
    assert decision["n8n_runtime_integrated"] is False
    assert decision["n8n_runtime_bundled"] is False
    assert decision["n8n_runtime_started"] is False
    assert decision["external_code_copied"] is False
    assert validation["status"] == "passed"
    assert validation["credentials_embedded"] is False
    assert validation["dangerous_node_types"] == []
    assert validation["n8n_runtime_bundled"] is False
    assert manifest["status"] == "export_ready"
    assert manifest["runtime_model"] == "user_owned_external_runtime"


def test_n8n_required_export_artifacts_are_present_and_safe():
    workflow = _json(EXPORT_DIR / "n8n_workflow.json")
    contract = _json(EXPORT_DIR / "webhook_contract.json")

    for filename in [
        "n8n_workflow.json",
        "webhook_contract.json",
        "sample_event.json",
        "external_automation_manifest.json",
        "n8n_export_validation.json",
        "n8n_export_report.md",
    ]:
        assert (EXPORT_DIR / filename).exists(), filename

    assert workflow["active"] is False
    assert "credentials" not in json.dumps(workflow).lower()
    assert {node["type"] for node in workflow["nodes"]} == {
        "n8n-nodes-base.webhook",
        "n8n-nodes-base.respondToWebhook",
    }
    assert contract["source_trace_required"] is True
    assert contract["authentication"]["credentials_embedded"] is False


def test_n8n_ui_status_is_truthful_and_runtime_execution_remains_unavailable():
    ui = _json(UI_IMPACT)
    registry = _json(UI_REGISTRY)
    project = next(item for item in registry["projects"] if item["project_id"] == "n8n")

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["workflow_export_action_available"] is False
    assert ui["current_ui_state"]["runtime_execution_action_available"] is False
    assert project["contract_status"] == [
        "workflow_export_adapter",
        "export_validation_passed",
        "runtime_not_bundled",
    ]
    assert project["implemented"] is True
    assert project["ready"] is False
    assert project["local_ready"] is True
    assert project["executable_action"] is False
    assert project["requires_external_runtime"] is True
    assert project["blocked_reason"] == "external_runtime_required"


def test_n8n_run_is_governed_and_does_not_accept_campaign_3():
    run = _json(RUN_MANIFEST)
    manifest = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in manifest["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert run["status"] == "passed"
    assert run["integration_decision"] == "real_integration"
    assert run["campaign_state_after_run"]["campaign_3_item_5_4"] == "advanced"
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == "5.5 MMSkills"
    assert runs["n8n_workflow_export"]["scope"] == "SECTION_5_ITEM_5_4_N8N"
    assert "n8n_workflow_export" in index
    assert "Next Section 5 item: `5.13 mattpocock/skills`" in plan
    assert "Campaign 3 accepted: `false`" in plan


def test_n8n_non_downgrade_fields_are_present():
    for payload in [_json(DECISION), _json(UI_IMPACT), _json(RUN_MANIFEST)]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"].strip()
        assert payload["not_goal_complete"] is True
