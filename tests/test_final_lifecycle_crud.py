from tests.final_audit_helpers import load_json, run_audit


def test_lifecycle_crud_gap_is_classified_not_ignored(tmp_path):
    output, _ = run_audit(tmp_path)

    gate = load_json(output, "final_v4_rc_gate_report.json")
    issue_ids = {item["id"] for item in gate["issue_checklist"]}
    assert "lifecycle_crud_update_archive_delete_partial" in issue_ids
    issue = next(item for item in gate["issue_checklist"] if item["id"] == "lifecycle_crud_update_archive_delete_partial")
    assert issue["severity"] == "P1"
    assert issue["status"] == "needs_review"
