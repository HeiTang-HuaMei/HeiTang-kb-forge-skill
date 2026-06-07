import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_conflicting_sources_keep_knowledge_accuracy_in_review():
    report = json.loads((PROOF / "real_input_failure_report.json").read_text(encoding="utf-8"))
    matching = [item for item in report["blockers"] if item["id"] == "knowledge_accuracy_warning_on_conflict_sources"]

    assert matching
    assert matching[0]["status"] == "accepted_needs_review"
    assert matching[0]["severity"] == "P1"
    assert "warning" in matching[0]["reason"]
