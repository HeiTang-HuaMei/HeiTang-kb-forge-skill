from heitang_kb_forge.schemas.citation_verification_schema import (
    CitationSourceTraceEntry,
    CitationVerificationInput,
    CitationVerificationReport,
)


def verify_citations(payload: CitationVerificationInput | dict) -> CitationVerificationReport:
    data = payload if isinstance(payload, CitationVerificationInput) else CitationVerificationInput.model_validate(payload)
    trace_by_citation = {_key(entry.citation): entry for entry in data.source_trace if entry.citation.strip()}
    source_trace_citations = [entry.citation for entry in data.source_trace if entry.citation.strip()]
    allowed_scope_ids = {_key(scope_id) for scope_id in data.allowed_scope_ids if scope_id.strip()}

    resolved_claim_ids: list[str] = []
    missing_citation_claim_ids: list[str] = []
    unresolved_citation_claim_ids: list[str] = []
    out_of_scope_claim_ids: list[str] = []

    for claim in data.claims:
        citation = claim.citation.strip()
        if not citation:
            missing_citation_claim_ids.append(claim.claim_id)
            continue

        entry = trace_by_citation.get(_key(citation))
        if entry is None:
            unresolved_citation_claim_ids.append(claim.claim_id)
            continue

        claim_allowed_scope_ids = {_key(scope_id) for scope_id in claim.allowed_scope_ids if scope_id.strip()}
        scope_allowlist = claim_allowed_scope_ids or allowed_scope_ids
        if scope_allowlist and _key(entry.scope_id) not in scope_allowlist:
            out_of_scope_claim_ids.append(claim.claim_id)
            continue

        resolved_claim_ids.append(claim.claim_id)

    checked_claim_count = len(data.claims)
    cited_claim_count = checked_claim_count - len(missing_citation_claim_ids)
    resolved_claim_count = len(resolved_claim_ids)
    coverage = resolved_claim_count / checked_claim_count if checked_claim_count else 1.0
    gap_count = len(missing_citation_claim_ids) + len(unresolved_citation_claim_ids) + len(out_of_scope_claim_ids)

    return CitationVerificationReport(
        status="pass" if gap_count == 0 else "citation_gaps_found",
        checked_claim_count=checked_claim_count,
        cited_claim_count=cited_claim_count,
        resolved_claim_count=resolved_claim_count,
        citation_coverage=round(coverage, 4),
        resolved_claim_ids=resolved_claim_ids,
        missing_citation_claim_ids=missing_citation_claim_ids,
        unresolved_citation_claim_ids=unresolved_citation_claim_ids,
        out_of_scope_claim_ids=out_of_scope_claim_ids,
        source_trace_citations=source_trace_citations,
        summary=f"{gap_count} citation gap(s) found across {checked_claim_count} claim(s).",
    )


def _key(value: str) -> str:
    return " ".join(str(value).strip().lower().split())
