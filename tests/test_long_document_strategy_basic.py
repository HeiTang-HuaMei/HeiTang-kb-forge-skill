from heitang_kb_forge.long_document_strategy import build_long_document_strategy


def test_long_document_strategy_schedules_sections_within_budget():
    report = build_long_document_strategy(
        {
            "sections": [
                {"section_id": "intro", "title": "Intro", "text": "a" * 20},
                {"section_id": "body", "title": "Body", "text": "b" * 25},
            ],
            "max_chars_per_pass": 100,
            "required_section_ids": ["intro"],
        }
    )

    assert report.status == "ready"
    assert report.reading_order == ["intro", "body"]
    assert report.remaining_section_ids == []
    assert report.selected_char_count == 45


def test_long_document_strategy_preserves_remaining_sections_when_budget_is_limited():
    report = build_long_document_strategy(
        {
            "sections": [
                {"section_id": "done", "title": "Done", "text": "d" * 15, "already_read": True},
                {"section_id": "next", "title": "Next", "text": "n" * 20},
                {"section_id": "later", "title": "Later", "text": "l" * 20},
            ],
            "max_chars_per_pass": 30,
        }
    )

    assert report.status == "partial"
    assert report.already_read_section_ids == ["done"]
    assert report.reading_order == ["next"]
    assert report.remaining_section_ids == ["later"]


def test_long_document_strategy_reports_missing_required_sections():
    report = build_long_document_strategy(
        {
            "sections": [{"section_id": "intro", "title": "Intro", "text": "hello"}],
            "required_section_ids": ["appendix"],
        }
    )

    assert report.status == "missing_required_sections"
    assert report.missing_required_section_ids == ["appendix"]
    assert report.reading_order == []
