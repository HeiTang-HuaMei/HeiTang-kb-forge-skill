from pathlib import Path

from tests.final_audit_helpers import load_json, run_audit
from heitang_kb_forge.final_audit import run_final_pre_v4_audit


def test_final_gate_blocks_until_validation_ci_are_attached(tmp_path):
    output, result = run_audit(tmp_path)

    gate = load_json(output, "final_v4_rc_gate_report.json")
    assert result["ready_for_v4_rc"] is False
    assert gate["overall_status"] == "blocked"
    assert any(item["id"] == "core_full_validation_not_attached" for item in gate["p0_blockers"])
    assert any(item["id"] == "ci_green_not_attached" for item in gate["p0_blockers"])
    assert gate["recommendation"].startswith("blocked")


def test_final_gate_clears_rag_p0_after_local_vector_readiness_is_proven(tmp_path):
    output, result = run_audit(
        tmp_path,
        core_validation={"status": "pass", "focused": "pass", "full": "pass"},
        ui_validation={"status": "pass", "flutter": "pass"},
        ci_status={"status": "pass", "run": "local-test"},
    )

    gate = load_json(output, "final_v4_rc_gate_report.json")
    assert result["ready_for_v4_rc"] is True
    assert gate["overall_status"] == "ready_for_v4_rc"
    assert not any(item["id"] == "rag_vector_index_industrial_readiness_unproven" for item in gate["p0_blockers"])
    assert any(item["id"] == "scanned_pdf_full_ocr_not_proven" for item in gate["issue_checklist"])
    assert gate["recommendation"] == "ready_for_v4_rc"


def test_final_gate_allows_attached_ui_validation_without_sibling_ui_repo(tmp_path):
    output = tmp_path / "audit"
    missing_ui_repo = tmp_path / "missing-ui-repo"

    result = run_final_pre_v4_audit(
        core_repo=Path.cwd(),
        output=output,
        ui_repo=missing_ui_repo,
        core_validation={"status": "pass", "focused": "pass", "full": "pass"},
        ui_validation={"status": "pass", "flutter_analyze": "pass", "flutter_test": "pass", "flutter_build_web": "pass"},
        ci_status={"status": "pass", "run": "local-test"},
    )

    gate = load_json(output, "final_v4_rc_gate_report.json")
    assert result["ready_for_v4_rc"] is True
    assert not any(item["id"] == "ui_contract_runtime_path_not_proven" for item in gate["issue_checklist"])
