from heitang_kb_forge.verification.freshness import check_freshness
from heitang_kb_forge.verification.scoring import score_knowledge_accuracy


def test_freshness_unknown_is_honest_when_dates_missing():
    claims = [{"claim_id": "c1", "claim_text": "Pricing is 20 dollars.", "source_path": "x.md"}]

    report = check_freshness(claims, [])

    assert report["items"][0]["freshness_status"] == "unknown"


def test_knowledge_accuracy_score_includes_uncertainty():
    claim_report = {"claim_count": 2, "claims": [{"verification_status": "trusted"}, {"verification_status": "unverified"}]}
    cross = {"results": [{"agreement_score": 1.0}, {"agreement_score": 0.2}]}
    contradictions = {"contradiction_count": 0}
    freshness = {"items": [{"freshness_status": "fresh"}, {"freshness_status": "unknown"}]}

    score = score_knowledge_accuracy(claim_report, cross, contradictions, freshness)

    assert score["overall_accuracy_score"] < 1
    assert score["uncertainty_penalty"] > 0
