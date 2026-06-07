from heitang_kb_forge.verification.source_cross_check import cross_check_claims


def test_source_cross_check_marks_agreement_and_missing_evidence():
    claims = [
        {"claim_id": "c1", "claim_text": "Pricing is 20 dollars."},
        {"claim_id": "c2", "claim_text": "Support is available in Europe."},
    ]
    sources = [{"source_id": "s1", "source_path": "verify.md", "text": "Pricing is 20 dollars."}]

    report = cross_check_claims(claims, sources)

    comparisons = {row["claim_id"]: row["comparison"] for row in report["results"]}
    assert comparisons["c1"] == "agreement"
    assert comparisons["c2"] == "missing_external_evidence"
