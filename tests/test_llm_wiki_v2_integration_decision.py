import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "artifacts" / "audits" / "section_5" / "llm_wiki_v2_knowledge_lifecycle"
DECISION = RUN_DIR / "llm_wiki_v2_integration_decision_report.json"
UI_IMPACT = RUN_DIR / "llm_wiki_v2_ui_impact_note.json"
RUN_MANIFEST = RUN_DIR / "run_manifest.json"
LIFECYCLE_REPORT = RUN_DIR / "knowledge_lifecycle" / "knowledge_lifecycle_report.json"
AUDIT_MANIFEST = ROOT / "docs" / "audits" / "AUDIT_MANIFEST.json"
AUDIT_INDEX = ROOT / "docs" / "audits" / "AUDIT_INDEX.md"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_llm_wiki_v2_decision_is_local_capability_fusion_not_vendor_runtime():
    decision = _json(DECISION)
    lifecycle = _json(LIFECYCLE_REPORT)

    assert decision["project_id"] == "llm_wiki_v2"
    assert decision["section"] == "5.1"
    assert decision["decision"] == "real_integration"
    assert decision["integration_mode"] == "capability_fusion"
    assert decision["vendor_runtime_integrated"] is False
    assert decision["external_code_copied"] is False
    assert decision["external_repository_check"]["result"] == "repository_not_found"
    assert decision["runtime_contract"]["requires_api_key"] is False
    assert decision["runtime_contract"]["requires_network"] is False
    assert decision["runtime_contract"]["requires_external_runtime"] is False
    assert lifecycle["status"] == "passed"
    assert lifecycle["source_trace_preserved"] is True


def test_llm_wiki_v2_outputs_required_decision_and_ui_impact_artifacts():
    decision = _json(DECISION)
    ui = _json(UI_IMPACT)
    run = _json(RUN_MANIFEST)

    assert DECISION.exists()
    assert DECISION.with_suffix(".md").exists()
    assert UI_IMPACT.exists()
    assert UI_IMPACT.with_suffix(".md").exists()
    assert run["status"] == "passed"
    assert run["campaign_state_after_run"]["campaign_3_item_5_1"] == "advanced"
    assert run["campaign_state_after_run"]["campaign_3_accepted"] is False
    assert run["campaign_state_after_run"]["campaign_4_allowed"] is False
    assert ui["core_action"]["command"].startswith("plan-knowledge-lifecycle")
    assert "LLM Wiki v2 runnable external backend" in ui["ui_must_not_show"]
    assert decision["ui_impact_note"] == str(UI_IMPACT.relative_to(ROOT)).replace("\\", "/")


def test_llm_wiki_v2_non_downgrade_fields_are_present():
    for payload in [_json(DECISION), _json(UI_IMPACT), _json(RUN_MANIFEST), _json(LIFECYCLE_REPORT)]:
        assert payload["final_target_not_downgraded"] is True
        assert payload["remaining_gap"].strip()
        assert payload["next_required_e2e_step"].strip()
        assert payload["not_goal_complete"] is True


def test_llm_wiki_v2_run_is_registered_in_audit_manifest_and_index():
    manifest = _json(AUDIT_MANIFEST)
    runs = {run["run_id"]: run for run in manifest["runs"]}
    index = AUDIT_INDEX.read_text(encoding="utf-8")

    assert "llm_wiki_v2_knowledge_lifecycle" in runs
    run = runs["llm_wiki_v2_knowledge_lifecycle"]
    assert run["type"] == "section_5_integration_decision"
    assert run["scope"] == "SECTION_5_ITEM_5_1_LLM_WIKI_V2"
    assert run["status"] == "passed"
    assert run["evidence_dir"] == "artifacts/audits/section_5/llm_wiki_v2_knowledge_lifecycle"
    assert run["run_manifest"].endswith("run_manifest.json")
    assert run["run_summary"].endswith("run_summary.md")
    assert run["keep_in_git"] is True
    assert "llm_wiki_v2_knowledge_lifecycle" in index
