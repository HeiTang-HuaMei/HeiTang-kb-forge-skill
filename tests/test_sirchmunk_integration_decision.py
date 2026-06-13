import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "sirchmunk_direct_file_search"
DECISION = RUN_DIR / "sirchmunk_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "sirchmunk_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
SEARCH = RUN_DIR / "search" / "sirchmunk_direct_file_search_manifest.json"
VALIDATION = RUN_DIR / "validation" / "sirchmunk_direct_file_search_validation_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
PROJECT_REGISTRY = ROOT / "docs" / "roadmap" / "external_projects" / "external_project_registry.json"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_sirchmunk_decision_is_bounded_direct_file_search_only():
    decision = _json(DECISION)
    search = _json(SEARCH)
    validation = _json(VALIDATION)

    assert decision["project_id"] == "sirchmunk"
    assert decision["section"] == "5.14"
    assert decision["decision"] == "real_integration"
    assert decision["integration_mode"] == "bounded_direct_file_search_provider"
    assert decision["verification_state"] == "verified_source_local_direct_file_search_only"
    repo = decision["repository_check"]
    assert repo["git_ls_remote_result"] == "accessible"
    assert repo["git_ls_remote_head"] == "1e07ec11953673b601959fc82563e8264b9d5c6a"
    assert repo["latest_release"] == "v0.0.7"
    assert repo["license_spdx"] == "Apache-2.0"
    assert repo["repository_cloned"] is False
    assert repo["external_code_copied"] is False
    runtime = decision["runtime_contract"]
    assert runtime["local_direct_file_search_implemented"] is True
    assert runtime["sirchmunk_runtime_integrated"] is False
    assert runtime["official_runtime_executed"] is False
    assert runtime["llm_required"] is False
    assert runtime["embedding_required"] is False
    assert runtime["vector_database_required"] is False
    assert runtime["network_required"] is False
    assert runtime["external_source_ingestion_implemented"] is False
    assert search["status"] == "passed"
    assert search["search_summary"]["result_count"] == 1
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []


def test_sirchmunk_ui_state_is_status_only_and_not_executable():
    ui = _json(UI_IMPACT)

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["direct_file_search_status_visible"] is True
    assert ui["current_ui_state"]["source_trace_visible"] is True
    assert ui["current_ui_state"]["local_ready"] is True
    assert ui["current_ui_state"]["ready"] is False
    assert ui["current_ui_state"]["executable_action"] is False
    assert ui["current_ui_state"]["vendor_runtime_action_available"] is False
    assert ui["current_ui_state"]["vector_db_action_available"] is False
    assert "Sirchmunk runtime ready" in ui["ui_must_not_show"]
    assert "Build vector DB with Sirchmunk" in ui["ui_must_not_show"]


def test_sirchmunk_registry_and_campaign_sequence_advance_to_5_s1():
    registry = _json(PROJECT_REGISTRY)
    project = next(item for item in registry["projects"] if item["project_id"] == "sirchmunk")
    run = _json(RUN_MANIFEST)
    audit = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in audit["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert project["current_repo_status"] == "real_workflow_evidence"
    assert project["implementation_mode"] == "bounded_direct_file_search_provider"
    assert "heitang_kb_forge/external_retrieval/sirchmunk.py" in project["current_evidence_files"]
    assert "tests/test_sirchmunk_direct_file_search.py" in project["current_evidence_files"]
    assert project["requires_api_key"] is False
    assert project["requires_network"] is False
    assert project["requires_external_runtime"] is False
    assert run["integration_decision"] == "real_integration"
    assert run["campaign_state_after_run"]["campaign_3_item_5_14"] == (
        "advanced_real_integration_direct_file_search_only"
    )
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_3_3_0_active"] is False
    assert run["campaign_state_after_run"]["campaign_3_4_0_active"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == "5.S1 GBrain"
    assert runs["sirchmunk_direct_file_search"]["scope"] == "SECTION_5_ITEM_5_14_SIRCHMUNK"
    assert "sirchmunk_direct_file_search" in index
    assert "Next Section 5 item: `5.S1 GBrain`" in plan


def test_sirchmunk_non_downgrade_fields_point_to_5_s1():
    for payload in [
        _json(DECISION),
        _json(UI_IMPACT),
        _json(RUN_MANIFEST),
        _json(SEARCH),
        _json(VALIDATION),
    ]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"] == (
            "Process Section 5 strengthening item 5.S1 GBrain only."
        )
        assert payload["not_goal_complete"] is True
