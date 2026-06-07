from tests.final_audit_helpers import assert_required_outputs, load_json, run_audit


def test_final_audit_writes_required_outputs_and_truth_matrix(tmp_path):
    output, result = run_audit(tmp_path)

    assert result["overall_status"] == "blocked"
    assert result["ready_for_v4_rc"] is False
    assert_required_outputs(output)

    matrix = load_json(output, "final_functionality_truth_matrix.json")
    assert matrix["capabilities"]
    assert matrix["file_existence_alone_is_pass"] is False if "file_existence_alone_is_pass" in matrix else True
    assert any(item["capability"] == "query_rewrite_and_retrieval_planning" for item in matrix["capabilities"])
    assert all("risk_level" in item for item in matrix["capabilities"])
    assert all(item["tests_require_real_llm_api_network"] is False for item in matrix["capabilities"])


def test_final_gate_contains_corrected_severity_policy(tmp_path):
    output, _ = run_audit(tmp_path)

    gate = load_json(output, "final_v4_rc_gate_report.json")
    assert "All issues must be classified by severity and scope" in gate["severity_policy"]
    assert "only low-risk issues will be fixed" not in gate["severity_policy"]
    assert gate["ready_for_v4_rc"] is False
    assert "p0_blockers" in gate
