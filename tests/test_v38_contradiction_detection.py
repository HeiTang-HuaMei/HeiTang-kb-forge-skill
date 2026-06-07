from heitang_kb_forge.verification.contradiction import detect_contradictions
from heitang_kb_forge.verification.source_cross_check import cross_check_claims


def test_contradiction_detection_for_numeric_and_negation_mismatch():
    claims = [{"claim_id": "c1", "claim_text": "Pricing is 20 dollars and support is enabled."}]
    sources = [{"source_id": "s1", "source_path": "verify.md", "text": "Pricing is 15 dollars and support is disabled."}]
    cross = cross_check_claims(claims, sources)

    report = detect_contradictions(cross)

    assert report["contradiction_count"] == 1
    reasons = report["items"][0]["reasons"]
    assert "numeric_mismatch" in reasons
    assert "status_mismatch" in reasons
