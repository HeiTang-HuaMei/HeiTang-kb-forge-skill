from tests.final_audit_helpers import load_json, run_audit


def test_final_scale_reports_simulation_and_limits_claim(tmp_path):
    output, _ = run_audit(tmp_path)

    registry = load_json(output, "registry_scale_report.json")
    final_scale = load_json(output, "final_scale_performance_report.json")
    assert registry["simulated_registry_entries"] == 1500
    assert registry["status"] == "needs_review"
    assert "synthetic" in final_scale["p1_findings"][0].lower()
    assert final_scale["tests_require_real_llm_api_network"] is False
