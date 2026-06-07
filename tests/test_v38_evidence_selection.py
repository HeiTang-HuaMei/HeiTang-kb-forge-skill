from heitang_kb_forge.retrieval.evidence_selection import select_evidence


def test_evidence_selection_records_selected_and_rejected_reasons():
    ranked = [
        {"retrieval_id": "a", "text": "pricing revenue", "keywords": ["pricing", "revenue"], "source_path": "a.md", "chunk_id": "1", "citation": "a#1", "rerank_score": 10},
        {"retrieval_id": "b", "text": "pricing", "keywords": ["pricing"], "source_path": "a.md", "chunk_id": "2", "citation": "a#2", "rerank_score": 7},
        {"retrieval_id": "c", "text": "margin", "keywords": ["margin"], "source_path": "c.md", "chunk_id": "3", "rerank_score": 1},
    ]

    result = select_evidence(ranked, "pricing revenue", top_k=1)

    assert result["selected_count"] == 1
    assert result["rejected"]
    assert result["selected"][0]["reasons"]
    assert result["evidence_coverage_score"] > 0


def test_insufficient_evidence_triggers_refusal_diagnostics():
    result = select_evidence([], "unknown claim", top_k=3)

    assert result["insufficient_evidence"] is True
    assert result["refusal_recommendation"]["should_refuse"] is True
