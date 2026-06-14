from tests.v4_2_baseline_evidence import load_baseline_report



def test_conflicting_sources_keep_knowledge_accuracy_in_review():
    report = load_baseline_report("real_input_failure_report.json")
    matching = [item for item in report["blockers"] if item["id"] == "knowledge_accuracy_warning_on_conflict_sources"]

    assert matching
    assert matching[0]["status"] == "accepted_needs_review"
    assert matching[0]["severity"] == "P1"
    assert "warning" in matching[0]["reason"]
