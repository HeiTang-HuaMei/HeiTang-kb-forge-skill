from __future__ import annotations

import re


def detect_contradictions(cross_check_report: dict) -> dict:
    items = []
    for row in cross_check_report.get("results", []):
        reasons = []
        if row.get("comparison") == "contradiction":
            reasons.append("source_cross_check_contradiction")
        reasons.extend(_simple_mismatch_reasons(row.get("claim_text", ""), row.get("matched_text", "")))
        status = "contradicted" if reasons else "not_detected"
        items.append(
            {
                "claim_id": row.get("claim_id", ""),
                "claim_text": row.get("claim_text", ""),
                "contradiction_status": status,
                "reasons": sorted(set(reasons)),
                "source_path": row.get("source_path", ""),
            }
        )
    contradicted = [item for item in items if item["contradiction_status"] == "contradicted"]
    return {
        "contradiction_map_version": "3.8.0-alpha.1",
        "status": "warning" if contradicted else "pass",
        "contradiction_count": len(contradicted),
        "items": items,
        "source_disagreement_summary": {
            "contradicted_claims": [item["claim_id"] for item in contradicted],
            "has_source_disagreement": bool(contradicted),
        },
        "tests_require_real_llm_api_network": False,
    }


def _simple_mismatch_reasons(claim: str, evidence: str) -> list[str]:
    reasons = []
    claim_numbers = re.findall(r"\d+(?:\.\d+)?", claim)
    evidence_numbers = re.findall(r"\d+(?:\.\d+)?", evidence)
    if claim_numbers and evidence_numbers and claim_numbers[0] != evidence_numbers[0]:
        reasons.append("numeric_mismatch")
    claim_dates = re.findall(r"\b20\d{2}\b", claim)
    evidence_dates = re.findall(r"\b20\d{2}\b", evidence)
    if claim_dates and evidence_dates and claim_dates[0] != evidence_dates[0]:
        reasons.append("date_mismatch")
    if _contains_any(claim, ["enabled", "active", "supported"]) and _contains_any(evidence, ["disabled", "inactive", "unsupported"]):
        reasons.append("status_mismatch")
    if _contains_any(claim, ["must", "required"]) and _contains_any(evidence, ["optional", "not required"]):
        reasons.append("mutually_exclusive_fact")
    if _negated(claim) != _negated(evidence):
        reasons.append("negation_mismatch")
    return reasons


def _contains_any(value: str, needles: list[str]) -> bool:
    lowered = value.lower()
    return any(needle in lowered for needle in needles)


def _negated(value: str) -> bool:
    lowered = value.lower()
    return any(token in lowered for token in [" not ", " never ", " no ", "不", "不是", "没有"])
