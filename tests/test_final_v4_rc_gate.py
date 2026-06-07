from tests.final_audit_helpers import load_json, run_audit


def test_final_gate_blocks_until_validation_ci_and_p1_reviews_are_attached(tmp_path):
    output, result = run_audit(
        tmp_path,
        core_validation={"status": "pass", "focused": "pass", "full": "pass"},
        ui_validation={"status": "pass", "flutter": "pass"},
        ci_status={"status": "pass", "run": "local-test"},
    )

    gate = load_json(output, "final_v4_rc_gate_report.json")
    assert result["ready_for_v4_rc"] is False
    assert gate["overall_status"] == "blocked"
    assert any(item["severity"] == "P0" for item in gate["p0_blockers"])
    assert gate["recommendation"].startswith("blocked")
