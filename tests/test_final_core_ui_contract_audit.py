from tests.final_audit_helpers import load_json, run_audit


def test_core_ui_contract_audit_requires_ui_validation_for_pass(tmp_path):
    output, _ = run_audit(tmp_path)

    report = load_json(output, "core_ui_contract_drift_final_report.json")
    assert report["core_contracts_present"] is True
    assert report["status"] == "needs_review"
    assert report["tests_require_real_llm_api_network"] is False
