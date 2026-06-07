from __future__ import annotations

import re


def select_evidence(ranked: list[dict], query: str, *, top_k: int = 5, min_coverage: float = 0.25) -> dict:
    query_tokens = set(_tokens(query))
    selected: list[dict] = []
    rejected: list[dict] = []
    used_sources: set[str] = set()
    for item in ranked:
        source = str(item.get("source_path") or item.get("citation") or "")
        reason = []
        if len(selected) >= top_k:
            reason.append("outside_top_k")
        if source and source in used_sources and len(selected) >= max(1, top_k - 1):
            reason.append("source_diversity_limit")
        if not item.get("citation"):
            reason.append("missing_citation")
        if reason:
            rejected.append(_decision(item, reason))
            continue
        selected.append(_decision(item, ["selected_for_relevance", "citation_ready" if item.get("citation") else "citation_missing"]))
        if source:
            used_sources.add(source)
    covered_tokens = set()
    for item in selected:
        covered_tokens.update(query_tokens & set(item.get("keywords") or _tokens(item.get("text", ""))))
    coverage = len(covered_tokens) / len(query_tokens) if query_tokens else 0.0
    insufficient = not selected or coverage < min_coverage or not any(item.get("citation") for item in selected)
    return {
        "evidence_selection_version": "3.8.0-alpha.1",
        "status": "warning" if insufficient else "pass",
        "query": query,
        "top_k": top_k,
        "selected": selected,
        "rejected": rejected,
        "selected_count": len(selected),
        "rejected_count": len(rejected),
        "source_diversity_count": len(used_sources),
        "citation_ready": all(item.get("citation") for item in selected) if selected else False,
        "evidence_coverage_score": round(coverage, 4),
        "insufficient_evidence": insufficient,
        "refusal_recommendation": {
            "should_refuse": insufficient,
            "refusal_reason": "insufficient_or_uncited_evidence" if insufficient else "",
            "missing_evidence": _missing_evidence(query_tokens, covered_tokens),
            "suggested_user_action": "Provide more specific query or trusted verification sources." if insufficient else "",
            "supporting_trace": [item["retrieval_id"] for item in selected],
        },
        "tests_require_real_llm_api_network": False,
    }


def _decision(item: dict, reasons: list[str]) -> dict:
    return {
        "retrieval_id": item.get("retrieval_id", ""),
        "source_path": item.get("source_path", ""),
        "chunk_id": item.get("chunk_id", ""),
        "citation": item.get("citation", ""),
        "text": item.get("text", ""),
        "rerank_score": item.get("rerank_score", item.get("score", 0)),
        "reasons": reasons,
    }


def _missing_evidence(query_tokens: set[str], covered_tokens: set[str]) -> list[str]:
    return sorted(query_tokens - covered_tokens)[:12]


def _tokens(value: str) -> list[str]:
    return [token.lower() for token in re.findall(r"[\w\u4e00-\u9fff]+", str(value)) if len(token) > 1]
