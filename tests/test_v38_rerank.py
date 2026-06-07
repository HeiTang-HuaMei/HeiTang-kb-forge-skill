from heitang_kb_forge.retrieval.rerank import rerank_candidates


def test_rerank_ordering_is_deterministic_and_uses_trust_and_risk():
    candidates = [
        {"retrieval_id": "stale", "text": "pricing revenue", "source_path": "old.md", "chunk_id": "c1", "citation": "old", "confidence": "high", "metadata": {"freshness_status": "stale"}},
        {"retrieval_id": "trusted", "text": "pricing revenue", "source_path": "new.md", "chunk_id": "c2", "citation": "new", "confidence": "high", "trusted_source": True},
        {"retrieval_id": "weak", "text": "pricing", "source_path": "weak.md", "chunk_id": "c3", "confidence": "low"},
    ]

    ranked = rerank_candidates(candidates, "pricing revenue")

    assert [item["retrieval_id"] for item in ranked] == ["trusted", "stale", "weak"]
    assert ranked[0]["trusted_source_boost"] > ranked[2]["trusted_source_boost"]
    assert ranked[1]["stale_risky_penalty"] > 0
