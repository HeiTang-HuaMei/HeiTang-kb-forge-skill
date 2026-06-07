from tests.final_audit_helpers import load_json, run_audit


def test_security_reports_do_not_require_network_or_llm(tmp_path):
    output, _ = run_audit(tmp_path)

    for name in [
        "final_security_privacy_report.json",
        "threat_model_report.json",
        "data_classification_report.json",
        "no_hidden_upload_report.json",
        "network_dependency_audit_report.json",
        "config_secret_handling_report.json",
    ]:
        payload = load_json(output, name)
        assert payload["tests_require_real_llm_api_network"] is False


def test_byo_storage_is_not_overclaimed(tmp_path):
    output, _ = run_audit(tmp_path)

    report = load_json(output, "byo_storage_security_readiness_report.json")
    assert report["byo_storage_supported_now"] is False
    assert report["security_readiness"] == "future_contract_only"
