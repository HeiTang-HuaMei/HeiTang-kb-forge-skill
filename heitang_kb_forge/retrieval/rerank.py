from __future__ import annotations

import re


def rerank_candidates(candidates: list[dict], query: str, *, purpose: str = "answering", top_k: int | None = None) -> list[dict]:
    query_tokens = set(_tokens(query))
    source_counts: dict[str, int] = {}
    ranked = []
    for index, candidate in enumerate(candidates):
        text_tokens = set(candidate.get("keywords") or _tokens(candidate.get("text", "")))
        overlap = len(query_tokens & text_tokens)
        coverage = overlap / len(query_tokens) if query_tokens else 0.0
        source = str(candidate.get("source_path") or candidate.get("citation") or "")
        diversity_bonus = 1.0 if source and source_counts.get(source, 0) == 0 else 0.0
        source_counts[source] = source_counts.get(source, 0) + 1
        trust_boost = _trust_boost(candidate)
        risk_penalty = _risk_penalty(candidate)
        validation_boost = _validation_boost(candidate) if purpose == "validation" else 0.0
        lexical_score = overlap * 3.0
        final_score = lexical_score + coverage * 2.0 + diversity_bonus + trust_boost + validation_boost - risk_penalty
        item = dict(candidate)
        item.update(
            {
                "rerank_score": round(final_score, 4),
                "lexical_overlap_score": overlap,
                "query_term_coverage": round(coverage, 4),
                "source_diversity_bonus": diversity_bonus,
                "trusted_source_boost": trust_boost,
                "stale_risky_penalty": risk_penalty,
                "validation_purpose_boost": validation_boost,
                "rerank_reason": _reason(overlap, diversity_bonus, trust_boost, risk_penalty, validation_boost),
            }
        )
        ranked.append((final_score, overlap, -index, str(item.get("retrieval_id", "")), item))
    ranked.sort(key=lambda row: (-row[0], -row[1], row[2], row[3]))
    results = [item for *_prefix, item in ranked]
    return results[:top_k] if top_k is not None else results


def build_rerank_report(ranked: list[dict], *, query: str, purpose: str) -> dict:
    return {
        "rerank_report_version": "3.8.0-alpha.1",
        "status": "pass" if ranked else "warning",
        "query": query,
        "retrieval_purpose": purpose,
        "candidate_count": len(ranked),
        "ranking": [
            {
                "rank": index,
                "retrieval_id": item.get("retrieval_id", ""),
                "source_path": item.get("source_path", ""),
                "rerank_score": item.get("rerank_score", 0),
                "query_term_coverage": item.get("query_term_coverage", 0),
                "reason": item.get("rerank_reason", []),
            }
            for index, item in enumerate(ranked, start=1)
        ],
        "deterministic_local_path": "lexical_overlap + coverage + diversity + trust + risk/freshness modifiers",
        "optional_llm_assist_path": "disabled_by_config",
        "tests_require_real_llm_api_network": False,
    }


def _trust_boost(candidate: dict) -> float:
    confidence = str(candidate.get("confidence", "medium")).lower()
    boost = {"high": 1.5, "medium": 0.5, "low": 0.0}.get(confidence, 0.5)
    if candidate.get("citation"):
        boost += 0.5
    if candidate.get("trusted_source") is True or candidate.get("metadata", {}).get("trusted_source") is True:
        boost += 1.0
    return boost


def _risk_penalty(candidate: dict) -> float:
    penalty = 0.0
    metadata = candidate.get("metadata", {}) if isinstance(candidate.get("metadata"), dict) else {}
    if candidate.get("review_required") or metadata.get("review_required"):
        penalty += 1.0
    if metadata.get("freshness_status") == "stale" or candidate.get("freshness_status") == "stale":
        penalty += 1.5
    if metadata.get("risk") in {"high", "risky"} or candidate.get("risk") in {"high", "risky"}:
        penalty += 1.0
    return penalty


def _validation_boost(candidate: dict) -> float:
    metadata = candidate.get("metadata", {}) if isinstance(candidate.get("metadata"), dict) else {}
    boost = 0.0
    if metadata.get("source_agreement") in {"agreement", "partial_agreement"}:
        boost += 1.0
    if metadata.get("freshness_status") == "fresh" or candidate.get("freshness_status") == "fresh":
        boost += 0.5
    return boost


def _reason(overlap: int, diversity_bonus: float, trust_boost: float, risk_penalty: float, validation_boost: float) -> list[str]:
    reasons = []
    if overlap:
        reasons.append("lexical_overlap")
    if diversity_bonus:
        reasons.append("source_diversity")
    if trust_boost >= 1:
        reasons.append("trusted_or_cited_source")
    if risk_penalty:
        reasons.append("stale_or_risky_penalty")
    if validation_boost:
        reasons.append("validation_metadata_boost")
    return reasons or ["stable_tie_break"]


def _tokens(value: str) -> list[str]:
    return [token.lower() for token in re.findall(r"[\w\u4e00-\u9fff]+", str(value)) if len(token) > 1]
