from heitang_kb_forge.classification_reasoning import classify_items


def test_classification_reasoning_classifies_policy_evidence_claim_and_task():
    report = classify_items(
        {
            "candidates": [
                {"item_id": "policy-1", "text": "Answers must cite package evidence.", "labels": ["policy"]},
                {"item_id": "evidence-1", "text": "source_path=guide.md chunk=chunk-1 citation=[1]"},
                {"item_id": "claim-1", "text": "The document states a supported fact."},
                {"item_id": "task-1", "text": "Next step: owner review after blocked gate is fixed."},
            ]
        }
    )

    assert report.status == "classified"
    assert report.decision_count == 4
    assert [decision.category for decision in report.decisions] == ["policy", "evidence", "claim", "task"]
    assert report.category_counts == {"policy": 1, "evidence": 1, "claim": 1, "task": 1}
    assert report.decisions[0].reason_codes[0] == "matched_policy_terms"


def test_classification_reasoning_honors_allowed_categories():
    report = classify_items(
        {
            "allowed_categories": ["evidence"],
            "candidates": [
                {"item_id": "policy-1", "text": "Answers must follow this rule."},
                {"item_id": "evidence-1", "text": "source_path=guide.md chunk=chunk-1 citation=[1]"},
            ],
        }
    )

    assert report.status == "classification_gaps_found"
    assert [decision.category for decision in report.decisions] == ["unknown", "evidence"]
    assert report.unresolved_item_ids == ["policy-1"]


def test_classification_reasoning_reports_unknown_items():
    report = classify_items({"candidates": [{"item_id": "plain", "text": "neutral paragraph"}]})

    assert report.status == "classification_gaps_found"
    assert report.decisions[0].category == "unknown"
    assert report.unresolved_item_ids == ["plain"]
