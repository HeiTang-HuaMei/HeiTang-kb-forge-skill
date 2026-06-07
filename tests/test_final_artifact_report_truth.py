from tests.final_audit_helpers import load_json, run_audit


def test_artifact_reports_are_non_empty_and_parseable(tmp_path):
    output, _ = run_audit(tmp_path)

    non_empty = load_json(output, "report_non_empty_validation_report.json")
    assert non_empty["status"] == "pass"
    assert non_empty["empty_reports"] == []

    artifact = load_json(output, "artifact_openability_report.json")
    assert artifact["artifacts"]
    assert any(item["status"] == "needs_review" for item in artifact["artifacts"])
