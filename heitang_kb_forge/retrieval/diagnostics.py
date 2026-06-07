from __future__ import annotations


def diagnose_retrieval_failure(
    *,
    query: str,
    candidates: list[dict],
    ranked: list[dict],
    evidence_selection: dict,
    purpose: str = "answering",
) -> dict:
    issues = []
    if not candidates:
        issues.append("no_results")
    if ranked and max(float(item.get("query_term_coverage", 0)) for item in ranked) < 0.25:
        issues.append("low_lexical_overlap")
    if ranked and not any(item.get("trusted_source") or item.get("citation") for item in ranked):
        issues.append("missing_trusted_source")
    if any(_freshness(item) == "stale" for item in ranked):
        issues.append("stale_sources")
    if any(item.get("contradiction_status") == "contradicted" for item in ranked):
        issues.append("contradictory_evidence")
    if evidence_selection.get("source_diversity_count", 0) < 2 and len(evidence_selection.get("selected", [])) > 1:
        issues.append("too_few_diverse_sources")
    if len(str(query).split()) <= 2:
        issues.append("query_too_broad_or_ambiguous")
    if purpose == "validation" and not candidates:
        issues.append("validation_source_unavailable")
    if purpose == "validation" and evidence_selection.get("insufficient_evidence"):
        issues.append("requires_user_provided_verification_sources")
    should_refuse = evidence_selection.get("refusal_recommendation", {}).get("should_refuse", False) or bool({"no_results", "contradictory_evidence"} & set(issues))
    return {
        "retrieval_failure_report_version": "3.8.0-alpha.1",
        "status": "warning" if issues else "pass",
        "query": query,
        "retrieval_purpose": purpose,
        "issues": issues,
        "should_refuse": should_refuse,
        "refusal_reason": _refusal_reason(issues, evidence_selection),
        "missing_evidence": evidence_selection.get("refusal_recommendation", {}).get("missing_evidence", []),
        "suggested_user_action": _suggested_action(issues),
        "supporting_trace": {
            "candidate_count": len(candidates),
            "ranked_count": len(ranked),
            "selected_count": evidence_selection.get("selected_count", 0),
        },
        "tests_require_real_llm_api_network": False,
    }


def _freshness(item: dict) -> str:
    metadata = item.get("metadata", {}) if isinstance(item.get("metadata"), dict) else {}
    return str(item.get("freshness_status") or metadata.get("freshness_status") or "")


def _refusal_reason(issues: list[str], evidence_selection: dict) -> str:
    if "no_results" in issues:
        return "no_retrieval_results"
    if "contradictory_evidence" in issues:
        return "contradictory_evidence"
    if evidence_selection.get("insufficient_evidence"):
        return "insufficient_evidence"
    return ""


def _suggested_action(issues: list[str]) -> str:
    if "requires_user_provided_verification_sources" in issues:
        return "Provide local verification sources and rerun verification."
    if "query_too_broad_or_ambiguous" in issues:
        return "Ask a more specific question or enable query planning variants."
    if "missing_trusted_source" in issues:
        return "Add trusted/cited source metadata to the package."
    return ""
