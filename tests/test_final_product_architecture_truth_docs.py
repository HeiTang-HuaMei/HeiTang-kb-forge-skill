from pathlib import Path


ROOT = Path.cwd()


def test_final_product_architecture_truth_docs_are_bilingual_and_auditable():
    english = (ROOT / "docs" / "FINAL_PRODUCT_ARCHITECTURE_TRUTH.md").read_text(encoding="utf-8")
    chinese = (ROOT / "docs" / "FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md").read_text(encoding="utf-8")

    for text in [english, chinese]:
        assert "rag_vector_index_industrial_readiness_unproven" in text
        assert "ui_validation_needs_review" in text
        assert "Ready for v4 RC" in text or "是否可进入 v4 RC" in text
        assert "final_v4_rc_gate_report.json" in text
        assert "rag_vector_index_readiness_report.json" in text
        assert "ui_full_operation_readiness_report.json" in text


def test_final_product_truth_docs_do_not_overclaim_blocked_capabilities():
    english = (ROOT / "docs" / "FINAL_PRODUCT_ARCHITECTURE_TRUTH.md").read_text(encoding="utf-8")
    chinese = (ROOT / "docs" / "FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md").read_text(encoding="utf-8")
    combined = english + "\n" + chinese

    assert "v4.0 released or ready" in combined
    assert "production vector database readiness" in combined
    assert "full user-operable local Workbench" in combined
    assert "full autonomous tool-calling Agent Runtime" in combined
    assert "full scanned PDF OCR proof" in combined
    assert "BYO cloud/database implemented" in combined


def test_readmes_link_to_final_product_truth_and_show_current_blockers():
    english = (ROOT / "README.md").read_text(encoding="utf-8")
    chinese = (ROOT / "README.zh-CN.md").read_text(encoding="utf-8")

    assert "docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md" in english
    assert "docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md" in chinese
    for text in [english, chinese]:
        assert "rag_vector_index_industrial_readiness_unproven" in text
        assert "ui_validation_needs_review" in text
        assert "`blocked`" in text
