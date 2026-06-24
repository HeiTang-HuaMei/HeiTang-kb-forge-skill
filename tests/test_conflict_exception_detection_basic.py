from heitang_kb_forge.conflict_exception import detect_conflict_exceptions


def test_conflict_exception_detection_reports_conflict_and_exception():
    report = detect_conflict_exceptions(
        {
            "statements": [
                {"statement_id": "allow-1", "topic": "external source validation", "polarity": "allow", "text": "Allow public source validation."},
                {"statement_id": "deny-1", "topic": "external source validation", "polarity": "deny", "text": "Do not validate restricted sources."},
                {
                    "statement_id": "exception-1",
                    "topic": "external source validation",
                    "polarity": "allow",
                    "text": "Allow only owner approved public sources.",
                    "exception_of": "deny-1",
                },
            ]
        }
    )

    assert report.status == "conflicts_with_exceptions_found"
    assert report.conflict_count == 1
    assert report.exception_count == 1
    assert report.conflicts[0].positive_statement_ids == ["allow-1", "exception-1"]
    assert report.conflicts[0].negative_statement_ids == ["deny-1"]
    assert report.exceptions[0].exception_of == "deny-1"


def test_conflict_exception_detection_passes_without_opposing_polarity():
    report = detect_conflict_exceptions(
        {
            "statements": [
                {"statement_id": "allow-1", "topic": "citation", "polarity": "allow", "text": "Allow citation trace."},
                {"statement_id": "allow-2", "topic": "citation", "polarity": "supports", "text": "Supports source trace."},
            ]
        }
    )

    assert report.status == "pass"
    assert report.conflict_count == 0
    assert report.exception_count == 0


def test_conflict_exception_detection_reports_exception_without_conflict():
    report = detect_conflict_exceptions(
        {
            "statements": [
                {
                    "statement_id": "exception-1",
                    "topic": "delete test object",
                    "polarity": "allow",
                    "text": "Allow deletion only for test marked objects.",
                    "exception_of": "general-delete-ban",
                }
            ]
        }
    )

    assert report.status == "exceptions_found"
    assert report.conflict_count == 0
    assert report.exception_count == 1
