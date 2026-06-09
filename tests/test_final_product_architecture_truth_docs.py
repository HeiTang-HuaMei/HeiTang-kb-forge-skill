from pathlib import Path
import json


ROOT = Path.cwd()
LATEST_PRE_V4_PROOF = ROOT / "docs" / "audits" / "local_acceptance" / "pre_v4_p0_after_live_llm"


def test_root_final_gate_reports_match_latest_pre_v4_proof():
    for name in ["final_v4_rc_gate_report.json", "v4_rc_final_gate_report.json"]:
        root_gate = json.loads((ROOT / name).read_text(encoding="utf-8"))
        proof_gate = json.loads((LATEST_PRE_V4_PROOF / name).read_text(encoding="utf-8"))

        assert root_gate["ready_for_v4_rc"] == proof_gate["ready_for_v4_rc"]
        assert root_gate["overall_status"] == proof_gate["overall_status"]
        assert root_gate["p0_blockers"] == proof_gate["p0_blockers"]
        assert root_gate["p1_blockers"] == proof_gate["p1_blockers"]
        assert root_gate["llm_provider_readiness"]["status"] == proof_gate["llm_provider_readiness"]["status"]
        assert root_gate["product_architecture_completeness"]["status"] == proof_gate["product_architecture_completeness"]["status"]


def test_final_product_architecture_truth_docs_are_bilingual_and_auditable():
    english = (ROOT / "docs" / "FINAL_PRODUCT_ARCHITECTURE_TRUTH.md").read_text(encoding="utf-8")
    chinese = (ROOT / "docs" / "FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md").read_text(encoding="utf-8")

    for text in [english, chinese]:
        assert "Remaining Core P0:" in text or "剩余 Core P0：" in text
        assert "none in the latest pre-v4 P0 proof" in text or "最新 pre-v4 P0 证明中无剩余 Core P0" in text
        assert "pre_v4_p0_after_live_llm" in text
        assert "Blocking P1: none" in text or "阻断 P1：无" in text
        assert "Latest Core P0 gate" in text or "最新 Core P0 门禁" in text
        assert "final_v4_rc_gate_report.json" in text
        assert "p1_final_gate_rerun" in text
        assert "rag_vector_index_readiness_report.json" in text
        assert "ui_full_operation_readiness_report.json" in text
        assert "ui_full_operation_acceptance_after_core_p0.json" in text
        assert "v4 RC readiness" in text


def test_final_product_truth_docs_do_not_overclaim_blocked_capabilities():
    english = (ROOT / "docs" / "FINAL_PRODUCT_ARCHITECTURE_TRUTH.md").read_text(encoding="utf-8")
    chinese = (ROOT / "docs" / "FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md").read_text(encoding="utf-8")
    combined = english + "\n" + chinese

    assert "v4.0 released from P1 evidence alone" in combined or "仅凭 P1 evidence 发布 v4.0" in combined
    assert "external vector database production readiness" in combined
    assert "v4.0 release from the P1 final gate" in combined or "由 P1 final gate 发布 v4.0" in combined
    assert "stable v4.0.0" in combined
    assert "full autonomous tool-calling Agent Runtime" in combined
    assert "full scanned PDF OCR proof" in combined
    assert "BYO cloud/database implemented" in combined


def test_readmes_link_to_final_product_truth_and_show_current_blockers():
    english = (ROOT / "README.md").read_text(encoding="utf-8")
    chinese = (ROOT / "README.zh-CN.md").read_text(encoding="utf-8")

    assert "docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md" in english
    assert "docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md" in chinese
    for text in [english, chinese]:
        assert "Remaining Core P0:" in text or "剩余 Core P0：" in text
        assert "none" in text or "无剩余" in text
        assert "pre_v4_p0_after_live_llm" in text
        assert "v4.0.0" in text
        assert "stable `v4.0.0`" in text
        assert "CURRENT_TRUTH" in text or "CURRENT_TRUTH.zh-CN" in text
        assert "CAPABILITY_MATRIX" in text or "CAPABILITY_MATRIX.zh-CN" in text
