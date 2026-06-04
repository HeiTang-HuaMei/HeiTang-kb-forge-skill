from heitang_kb_forge.agent_rag.scope import parse_scope, record_matches_scope


def test_agent_rag_scope_parses_and_filters_records():
    scope = parse_scope("book_id:demo-book", agent_type="shopping_guide_agent")
    record = {
        "source_path": "input/demo-book.md",
        "metadata": {"agent_type": "shopping_guide_agent"},
    }

    assert scope["book_id"] == "demo-book"
    assert record_matches_scope(record, scope) is True
    assert record_matches_scope(record, {"book_id": "other"}) is False
