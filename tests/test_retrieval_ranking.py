from heitang_kb_forge.retrieval.ranker import rank_records


def test_ranker_prefers_query_overlap():
    records = [
        {"retrieval_id": "a", "text": "unrelated", "keywords": ["unrelated"], "confidence": "medium"},
        {"retrieval_id": "b", "text": "governance evidence", "keywords": ["governance", "evidence"], "confidence": "medium"},
    ]

    ranked = rank_records(records, "governance evidence")

    assert ranked[0]["retrieval_id"] == "b"
