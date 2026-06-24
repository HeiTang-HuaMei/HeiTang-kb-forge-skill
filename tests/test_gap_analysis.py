from heitang_kb_forge.gap_analysis import analyze_gaps


def test_gap_analysis_reports_missing_claim_rule_and_source():
    report = analyze_gaps(
        {
            "required_claims": ["claim a", "claim b"],
            "evidence_claims": ["claim a"],
            "required_rules": ["rule a"],
            "evidence_rules": [],
            "required_sources": ["source a", "source b"],
            "evidence_sources": ["source b"],
        }
    )

    assert report.status == "gaps_found"
    assert report.missing_claims == ["claim b"]
    assert report.missing_rules == ["rule a"]
    assert report.missing_sources == ["source a"]
    assert report.covered_claims == ["claim a"]
    assert report.gap_count == 3


def test_gap_analysis_passes_when_all_required_items_are_covered():
    report = analyze_gaps(
        {
            "required_claims": ["Claim A"],
            "evidence_claims": [" claim a "],
            "required_rules": ["Rule A"],
            "evidence_rules": ["rule a"],
            "required_sources": ["Source A"],
            "evidence_sources": ["source a"],
        }
    )

    assert report.status == "pass"
    assert report.gap_count == 0
