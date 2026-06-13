import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "rag_anything_cross_modal_rag_schema"
DECISION = RUN_DIR / "rag_anything_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "rag_anything_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
SCHEMA = RUN_DIR / "schema" / "cross_modal_rag_manifest.json"
VALIDATION = RUN_DIR / "validation" / "cross_modal_rag_validation_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"
PLAN_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
PROJECT_REGISTRY = ROOT / "docs" / "roadmap" / "external_projects" / "external_project_registry.json"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_rag_anything_decision_is_verified_reference_schema_only():
    decision = _json(DECISION)
    schema = _json(SCHEMA)
    validation = _json(VALIDATION)

    assert decision["project_id"] == "rag_anything"
    assert decision["section"] == "5.12"
    assert decision["decision"] == "reference_only"
    assert decision["integration_mode"] == "cross_modal_rag_schema_reference"
    assert decision["verification_state"] == "verified_source_reference_only"
    repo = decision["repository_check"]
    assert repo["git_ls_remote_result"] == "accessible"
    assert repo["git_ls_remote_head"] == "a8538efecc99719538960692745ef0eb90d1a2f9"
    assert repo["latest_release"] == "v1.3.1"
    assert repo["license_spdx"] == "MIT"
    assert repo["repository_cloned"] is False
    assert repo["external_code_copied"] is False
    runtime = decision["runtime_contract"]
    assert runtime["local_schema_reference_implemented"] is True
    assert runtime["rag_anything_runtime_integrated"] is False
    assert runtime["lightrag_runtime_integrated"] is False
    assert runtime["mineru_runtime_executed"] is False
    assert runtime["llm_or_vlm_required"] is False
    assert runtime["embedding_required"] is False
    assert runtime["vector_database_required"] is False
    assert runtime["existing_rag_main_chain_replaced"] is False
    assert runtime["external_source_ingestion_implemented"] is False
    assert schema["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []


def test_rag_anything_ui_state_is_reference_only_and_not_executable():
    ui = _json(UI_IMPACT)

    assert ui["current_ui_state"]["status_visible"] is True
    assert ui["current_ui_state"]["schema_preview_available"] is True
    assert ui["current_ui_state"]["benchmark_profile_preview_available"] is True
    assert ui["current_ui_state"]["local_ready"] is True
    assert ui["current_ui_state"]["ready"] is False
    assert ui["current_ui_state"]["executable_action"] is False
    assert ui["current_ui_state"]["vendor_runtime_action_available"] is False
    assert ui["current_ui_state"]["multimodal_query_action_available"] is False
    assert "RAG-Anything runtime ready" in ui["ui_must_not_show"]
    assert "Run multimodal query" in ui["ui_must_not_show"]


def test_rag_anything_registry_and_campaign_sequence_advance_to_5_13():
    registry = _json(PROJECT_REGISTRY)
    project = next(item for item in registry["projects"] if item["project_id"] == "rag_anything")
    run = _json(RUN_MANIFEST)
    audit = _json(AUDIT_MANIFEST)
    runs = {item["run_id"]: item for item in audit["runs"]}
    plan = PLAN_LOCK.read_text(encoding="utf-8")
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert project["current_repo_status"] == "reference_schema_evidence"
    assert project["implementation_mode"] == "cross_modal_rag_schema_reference"
    assert "heitang_kb_forge/cross_modal_rag_schema/builder.py" in project["current_evidence_files"]
    assert "tests/test_cross_modal_rag_schema.py" in project["current_evidence_files"]
    assert project["requires_api_key"] is False
    assert project["requires_network"] is False
    assert project["requires_external_runtime"] is False
    assert run["integration_decision"] == "reference_only"
    assert run["campaign_state_after_run"]["campaign_3_item_5_12"] == "advanced_reference_only"
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_3_3_0_active"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert run["campaign_state_after_run"]["next_section_5_item"] == "5.13 mattpocock/skills"
    assert runs["rag_anything_cross_modal_rag_schema"]["scope"] == "SECTION_5_ITEM_5_12_RAG_ANYTHING"
    assert "rag_anything_cross_modal_rag_schema" in index
    assert "Next Section 5 item: `5.13 mattpocock/skills`" in plan


def test_rag_anything_non_downgrade_fields_point_to_5_13():
    for payload in [
        _json(DECISION),
        _json(UI_IMPACT),
        _json(RUN_MANIFEST),
        _json(SCHEMA),
        _json(VALIDATION),
    ]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"] == (
            "Process Section 5 item 5.13 mattpocock/skills only."
        )
        assert payload["not_goal_complete"] is True
