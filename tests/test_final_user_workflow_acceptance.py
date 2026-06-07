from tests.final_audit_helpers import load_json, run_audit


def test_final_user_workflows_are_explicit_and_not_auto_passed(tmp_path):
    output, _ = run_audit(tmp_path)

    report = load_json(output, "final_user_workflow_acceptance_report.json")
    workflow_ids = {item["workflow_id"] for item in report["workflows"]}
    assert "workflow_a_raw_material_to_package" in workflow_ids
    assert "workflow_h_golden_demo" in workflow_ids
    assert any(item["status"] == "needs_review" for item in report["workflows"])
    assert all(item["proof_level"] != "file_exists_only" for item in report["workflows"])
