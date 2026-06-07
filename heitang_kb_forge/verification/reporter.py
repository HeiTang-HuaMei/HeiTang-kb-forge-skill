from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.verification.claim_extractor import extract_claims
from heitang_kb_forge.verification.contradiction import detect_contradictions
from heitang_kb_forge.verification.freshness import check_freshness
from heitang_kb_forge.verification.scoring import score_knowledge_accuracy
from heitang_kb_forge.verification.source_cross_check import cross_check_claims, load_verification_sources


VERIFICATION_OUTPUT_FILES = [
    "claim_verification_report.json",
    "source_cross_check_report.json",
    "contradiction_map.json",
    "freshness_check_report.json",
    "knowledge_accuracy_report.json",
    "verification_retrieval_trace.json",
]


def run_claim_verification(package: Path, output: Path, verification_sources: list[Path] | None = None) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    claims = extract_claims(package)
    sources = load_verification_sources(package, verification_sources)
    cross_check = cross_check_claims(claims, sources)
    contradiction_map = detect_contradictions(cross_check)
    freshness = check_freshness(claims, sources)
    claim_report = _claim_report(claims, cross_check, contradiction_map, freshness)
    accuracy = score_knowledge_accuracy(claim_report, cross_check, contradiction_map, freshness)
    accuracy["external_absorption_map_file"] = "v38_external_absorption_map.json"
    trace = {
        "verification_retrieval_trace_version": "3.8.0-alpha.1",
        "package": str(package).replace("\\", "/"),
        "verification_source_count": len(sources),
        "claim_count": len(claims),
        "steps": [
            {"name": "extract_claims", "status": "pass", "count": len(claims)},
            {"name": "load_local_verification_sources", "status": "pass", "count": len(sources)},
            {"name": "source_cross_check", "status": cross_check["status"]},
            {"name": "contradiction_detection", "status": contradiction_map["status"]},
            {"name": "freshness_verification", "status": freshness["status"]},
            {"name": "knowledge_accuracy_scoring", "status": accuracy["status"]},
        ],
        "allow_external_network": False,
        "llm_used": False,
        "tests_require_real_llm_api_network": False,
    }
    write_json(output / "claim_verification_report.json", claim_report)
    write_json(output / "source_cross_check_report.json", cross_check)
    write_json(output / "contradiction_map.json", contradiction_map)
    write_json(output / "freshness_check_report.json", freshness)
    write_json(output / "knowledge_accuracy_report.json", accuracy)
    write_json(output / "verification_retrieval_trace.json", trace)
    return {
        "status": "warning" if accuracy["review_required"] else "pass",
        "claim_count": len(claims),
        "verification_source_count": len(sources),
        "output_files": VERIFICATION_OUTPUT_FILES,
        "accuracy": accuracy,
    }


def _claim_report(claims: list[dict], cross_check: dict, contradiction_map: dict, freshness: dict) -> dict:
    cross_by_id = {item["claim_id"]: item for item in cross_check.get("results", [])}
    contradiction_by_id = {item["claim_id"]: item for item in contradiction_map.get("items", [])}
    freshness_by_id = {item["claim_id"]: item for item in freshness.get("items", [])}
    rows = []
    for claim in claims:
        cross = cross_by_id.get(claim["claim_id"], {})
        contradiction = contradiction_by_id.get(claim["claim_id"], {})
        fresh = freshness_by_id.get(claim["claim_id"], {})
        status = _verification_status(cross, contradiction, fresh)
        rows.append(
            {
                **claim,
                "verification_status": status,
                "source_cross_check": cross.get("comparison", "missing_external_evidence"),
                "freshness_status": fresh.get("freshness_status", "unknown"),
                "contradiction_status": contradiction.get("contradiction_status", "not_detected"),
                "user_facing_explanation": _explanation(status),
            }
        )
    return {
        "claim_verification_report_version": "3.8.0-alpha.1",
        "status": "warning" if any(row["verification_status"] != "trusted" for row in rows) else "pass",
        "claim_count": len(rows),
        "claims": rows,
        "tests_require_real_llm_api_network": False,
    }


def _verification_status(cross: dict, contradiction: dict, freshness: dict) -> str:
    if contradiction.get("contradiction_status") == "contradicted" or cross.get("comparison") == "contradiction":
        return "contradicted"
    if freshness.get("freshness_status") == "stale":
        return "stale"
    if cross.get("comparison") == "agreement" and freshness.get("freshness_status") in {"fresh", "unknown"}:
        return "trusted"
    if cross.get("comparison") == "partial_agreement":
        return "weak"
    if cross.get("comparison") == "missing_external_evidence":
        return "unverified"
    return "needs_review"


def _explanation(status: str) -> str:
    return {
        "trusted": "The claim is supported by local verification evidence.",
        "weak": "The claim has partial local support and should be reviewed.",
        "contradicted": "Local verification evidence conflicts with this claim.",
        "stale": "The claim appears outdated based on available date metadata.",
        "unverified": "No sufficient local verification evidence was found.",
        "needs_review": "The claim requires human review before promotion.",
    }.get(status, "The claim requires review.")
