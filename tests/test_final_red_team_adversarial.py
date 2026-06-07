from tests.final_audit_helpers import load_json, run_audit


def test_red_team_report_keeps_p0_examples_and_no_bypass_policy(tmp_path):
    output, _ = run_audit(tmp_path)

    report = load_json(output, "final_industrial_red_team_report.json")
    assert "secret leakage" in report["p0_attack_cases"]
    assert "v4 gate says ready while P0 exists" in report["p0_attack_cases"]
    assert "high-risk issues must not be ignored" in report["severity_policy"]
