from tests.final_audit_helpers import load_json, run_audit


def test_external_absorption_maps_are_audited_honestly(tmp_path):
    output, _ = run_audit(tmp_path)

    report = load_json(output, "final_industrial_red_team_report.json")
    assert "Unknown is not pass" in report["red_team_stance"]

    gate = load_json(output, "final_v4_rc_gate_report.json")
    issue_ids = {item["id"] for item in gate["issue_checklist"]}
    assert "v310_external_absorption_map_absent" in issue_ids
