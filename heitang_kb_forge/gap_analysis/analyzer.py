from heitang_kb_forge.schemas.gap_analysis_schema import GapAnalysisInput, GapAnalysisReport


def analyze_gaps(payload: GapAnalysisInput | dict) -> GapAnalysisReport:
    data = payload if isinstance(payload, GapAnalysisInput) else GapAnalysisInput.model_validate(payload)
    missing_claims = _missing(data.required_claims, data.evidence_claims)
    missing_rules = _missing(data.required_rules, data.evidence_rules)
    missing_sources = _missing(data.required_sources, data.evidence_sources)
    covered_claims = _covered(data.required_claims, data.evidence_claims)
    covered_rules = _covered(data.required_rules, data.evidence_rules)
    covered_sources = _covered(data.required_sources, data.evidence_sources)
    gap_count = len(missing_claims) + len(missing_rules) + len(missing_sources)
    return GapAnalysisReport(
        status="pass" if gap_count == 0 else "gaps_found",
        missing_claims=missing_claims,
        missing_rules=missing_rules,
        missing_sources=missing_sources,
        covered_claims=covered_claims,
        covered_rules=covered_rules,
        covered_sources=covered_sources,
        gap_count=gap_count,
        summary=f"{gap_count} gap(s) found across claims, rules and sources.",
    )


def _missing(required: list[str], evidence: list[str]) -> list[str]:
    evidence_keys = {_key(item) for item in evidence}
    return [item for item in required if _key(item) not in evidence_keys]


def _covered(required: list[str], evidence: list[str]) -> list[str]:
    evidence_keys = {_key(item) for item in evidence}
    return [item for item in required if _key(item) in evidence_keys]


def _key(value: str) -> str:
    return " ".join(str(value).strip().lower().split())
