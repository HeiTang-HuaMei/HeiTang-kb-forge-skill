from __future__ import annotations


def score_knowledge_accuracy(claim_report: dict, cross_check_report: dict, contradiction_map: dict, freshness_report: dict) -> dict:
    claim_count = max(1, claim_report.get("claim_count", 0))
    verified = len([item for item in claim_report.get("claims", []) if item.get("verification_status") == "trusted"])
    evidence_coverage_score = verified / claim_count
    agreement_scores = [item.get("agreement_score", 0) for item in cross_check_report.get("results", [])]
    source_agreement_score = sum(agreement_scores) / len(agreement_scores) if agreement_scores else 0.0
    contradiction_risk_score = contradiction_map.get("contradiction_count", 0) / claim_count
    freshness_items = freshness_report.get("items", [])
    freshness_score = _freshness_score(freshness_items)
    overall = (
        evidence_coverage_score * 0.35
        + source_agreement_score * 0.3
        + (1 - contradiction_risk_score) * 0.2
        + freshness_score * 0.15
    )
    uncertainty = len([item for item in claim_report.get("claims", []) if item.get("verification_status") in {"unverified", "weak", "needs_review"}]) / claim_count
    adjusted = max(0.0, overall - uncertainty * 0.2)
    return {
        "knowledge_accuracy_report_version": "3.8.0-alpha.1",
        "status": "warning" if adjusted < 0.7 or contradiction_risk_score else "pass",
        "evidence_coverage_score": round(evidence_coverage_score, 4),
        "source_agreement_score": round(source_agreement_score, 4),
        "contradiction_risk_score": round(contradiction_risk_score, 4),
        "freshness_score": round(freshness_score, 4),
        "overall_accuracy_score": round(adjusted, 4),
        "uncertainty_penalty": round(uncertainty * 0.2, 4),
        "review_required": adjusted < 0.7 or contradiction_risk_score > 0,
        "tests_require_real_llm_api_network": False,
    }


def _freshness_score(items: list[dict]) -> float:
    if not items:
        return 0.0
    score_map = {"fresh": 1.0, "unknown": 0.45, "needs_review": 0.3, "stale": 0.0}
    return sum(score_map.get(item.get("freshness_status"), 0.3) for item in items) / len(items)
