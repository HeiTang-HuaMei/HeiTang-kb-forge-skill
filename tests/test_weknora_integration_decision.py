import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "weknora_auto_wiki"
DECISION = RUN_DIR / "weknora_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "weknora_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
FUSION_REPORT = RUN_DIR / "weknora_capability_fusion_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_weknora_decision_is_local_capability_fusion_not_vendor_runtime():
    decision = _json(DECISION)
    fusion = _json(FUSION_REPORT)

    assert decision["project_id"] == "weknora"
    assert decision["section"] == "5.2"
    assert decision["decision"] == "real_integration"
    assert decision["integration_mode"] == "capability_fusion"
    assert decision["vendor_runtime_integrated"] is False
    assert decision["external_code_copied"] is False
    assert decision["external_repository_check"]["result"] == "repository_accessible"
    assert decision["runtime_contract"]["requires_api_key"] is False
    assert decision["runtime_contract"]["requires_network"] is False
    assert decision["runtime_contract"]["requires_external_runtime"] is False
    assert fusion["status"] == "passed"
    assert fusion["auto_wiki_page_count"] > 0
    assert fusion["graph_entity_count"] > 0
    assert fusion["rag_trace_record_count"] > 0
    assert fusion["visual_trace_available"] is True
    assert fusion["source_trace_preserved"] is True


def test_weknora_outputs_required_decision_and_ui_impact_artifacts():
    decision = _json(DECISION)
    ui = _json(UI_IMPACT)
    run = _json(RUN_MANIFEST)

    assert DECISION.with_suffix(".md").exists()
    assert UI_IMPACT.with_suffix(".md").exists()
    assert run["status"] == "passed"
    assert run["campaign_state_after_run"]["campaign_3_item_5_1"] == "advanced"
    assert run["campaign_state_after_run"]["campaign_3_item_5_2"] == "advanced"
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert ui["core_action"]["command"].startswith("build-auto-wiki")
    assert "WeKnora runnable external backend" in ui["ui_must_not_show"]
    assert "WeKnora agentic RAG runtime ready" in ui["ui_must_not_show"]
    assert decision["ui_impact_note"] == str(UI_IMPACT.relative_to(ROOT)).replace("\\", "/")


def test_weknora_non_downgrade_fields_are_present():
    for payload in [_json(DECISION), _json(UI_IMPACT), _json(RUN_MANIFEST), _json(FUSION_REPORT)]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"].strip()
        assert payload["not_goal_complete"] is True


def test_weknora_run_is_registered_in_audit_manifest_and_index():
    manifest = _json(AUDIT_MANIFEST)
    runs = {run["run_id"]: run for run in manifest["runs"]}
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert "weknora_auto_wiki" in runs
    run = runs["weknora_auto_wiki"]
    assert run["type"] == "section_5_integration_decision"
    assert run["scope"] == "SECTION_5_ITEM_5_2_WEKNORA"
    assert run["status"] == "passed"
    assert run["evidence_dir"] == "artifacts/audits/section_5/weknora_auto_wiki"
    assert run["run_manifest"].endswith("run_manifest.json")
    assert run["run_summary"].endswith("run_summary.md")
    assert run["keep_in_git"] is True
    assert "weknora_auto_wiki" in index
