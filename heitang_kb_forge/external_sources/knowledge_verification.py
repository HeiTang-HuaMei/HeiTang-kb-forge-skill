from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit
from uuid import uuid4

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


KNOWLEDGE_VERIFICATION_FILES = [
    "claim_verification_report.json",
    "claim_verification_report.md",
    "knowledge_correctness_report.json",
    "knowledge_correctness_report.md",
    "answer_grounding_report.json",
    "answer_grounding_report.md",
    "knowledge_verification_dashboard.json",
    "verification_source_trace.json",
    "verification_evidence_map.json",
    "knowledge_verification_validation_report.json",
    "progress_events.jsonl",
    "run_manifest.json",
    "run_summary.md",
]

VERIFICATION_STATES = {
    "verified",
    "partially_verified",
    "unsupported",
    "outdated",
    "conflicting",
    "low_confidence",
    "needs_human_review",
}


def verify_claims(
    output: Path,
    *,
    claim: list[str] | None = None,
    claim_file: list[Path] | None = None,
    evidence_file: list[Path] | None = None,
    answer: str | None = None,
    answer_file: Path | None = None,
    created_at: str | None = None,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    created_at = created_at or _now()
    progress: list[dict[str, Any]] = []

    claims = _load_claims(claim or [], claim_file or [])
    answer_text = _load_answer(answer, answer_file)
    if answer_text:
        claims.extend(_claims_from_text(answer_text, source="answer"))
    evidence = _load_evidence(evidence_file or [], created_at=created_at)
    _progress(progress, "claim_extraction", "passed" if claims else "failed", f"Extracted {len(claims)} claims.")
    _progress(progress, "external_evidence_loading", "passed" if evidence else "skipped", f"Loaded {len(evidence)} evidence records.")

    rows = [_verify_one_claim(item, evidence, created_at=created_at) for item in claims]
    _progress(progress, "claim_verification", "passed" if rows else "failed", f"Verified {len(rows)} claim records.")
    source_trace = _source_trace(evidence, created_at=created_at)
    evidence_map = _evidence_map(rows, evidence, created_at=created_at)
    claim_report = _claim_report(rows, created_at=created_at)
    correctness = _knowledge_correctness_report(rows, evidence, created_at=created_at)
    grounding = _answer_grounding_report(answer_text, rows, created_at=created_at)
    dashboard = _dashboard(correctness, grounding, rows, created_at=created_at)
    validation = _validate_payloads(
        claim_report=claim_report,
        correctness=correctness,
        grounding=grounding,
        dashboard=dashboard,
        source_trace=source_trace,
        evidence_map=evidence_map,
    )
    _write_outputs(
        output,
        claim_report=claim_report,
        correctness=correctness,
        grounding=grounding,
        dashboard=dashboard,
        source_trace=source_trace,
        evidence_map=evidence_map,
        validation=validation,
        progress=progress,
    )
    return claim_report


def verify_knowledge_base(
    output: Path,
    *,
    knowledge_file: list[Path] | None = None,
    evidence_file: list[Path] | None = None,
    created_at: str | None = None,
) -> dict[str, Any]:
    claims: list[str] = []
    for path in knowledge_file or []:
        claims.extend(item["text"] for item in _claims_from_text(_read_text(Path(path)), source=Path(path).name))
    return verify_claims(output, claim=claims, evidence_file=evidence_file, created_at=created_at)


def verify_answer(
    output: Path,
    *,
    answer: str | None = None,
    answer_file: Path | None = None,
    evidence_file: list[Path] | None = None,
    created_at: str | None = None,
) -> dict[str, Any]:
    return verify_claims(
        output,
        answer=answer,
        answer_file=answer_file,
        evidence_file=evidence_file,
        created_at=created_at,
    )


def generate_correctness_report(
    output: Path,
    *,
    claim_report: Path,
    created_at: str | None = None,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    report = _read_json(claim_report)
    rows = report.get("claims", [])
    correctness = _knowledge_correctness_report(rows, [], created_at=created_at or _now())
    write_json(output / "knowledge_correctness_report.json", correctness)
    (output / "knowledge_correctness_report.md").write_text(
        _render_correctness_report(correctness),
        encoding="utf-8",
    )
    return correctness


def validate_knowledge_verification(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [name for name in KNOWLEDGE_VERIFICATION_FILES if not (library / name).exists()]
    errors = [f"missing_file:{name}" for name in missing]
    if not missing:
        errors.extend(
            _validate_payloads(
                claim_report=_read_json(library / "claim_verification_report.json"),
                correctness=_read_json(library / "knowledge_correctness_report.json"),
                grounding=_read_json(library / "answer_grounding_report.json"),
                dashboard=_read_json(library / "knowledge_verification_dashboard.json"),
                source_trace=_read_json(library / "verification_source_trace.json"),
                evidence_map=_read_json(library / "verification_evidence_map.json"),
            )["boundary_errors"]
        )
    return {
        "schema_version": "knowledge_verification_validation_report.v1",
        "status": "passed" if not errors else "failed",
        "boundary_errors": errors,
        "missing_files": missing,
        "knowledge_verification_engine_foundations_complete": not errors,
        "knowledge_verification_dashboard_foundation_complete": not errors,
        "supplement_3_0_complete": False,
        "campaign_3_3_0_acceptance_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "bridge_execution_accepted": False,
        "not_goal_complete": True,
    }


def write_knowledge_verification_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_knowledge_verification(library)
    write_json(output / "knowledge_verification_validation_report.json", result)
    return result


def _load_claims(inline_claims: list[str], claim_files: list[Path]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for text in inline_claims:
        rows.extend(_claims_from_text(text, source="inline_claim"))
    for path in claim_files:
        rows.extend(_claims_from_text(_read_text(Path(path)), source=Path(path).name))
    deduped: dict[str, dict[str, Any]] = {}
    for row in rows:
        deduped.setdefault(row["claim_id"], row)
    return list(deduped.values())


def _claims_from_text(text: str, *, source: str) -> list[dict[str, Any]]:
    rows = []
    for sentence in _sentences(text):
        if not _claim_like(sentence):
            continue
        normalized = _normalize(sentence)
        rows.append(
            {
                "claim_id": _stable_id("claim", normalized),
                "text": normalized,
                "source": source,
                "content_hash": _hash(normalized),
            }
        )
    return rows


def _load_answer(answer: str | None, answer_file: Path | None) -> str:
    if answer_file:
        return _read_text(Path(answer_file))
    return answer or ""


def _load_evidence(paths: list[Path], *, created_at: str) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for path in paths:
        path = Path(path)
        if not path.exists():
            rows.append(_failed_evidence(path, "evidence_file_missing", created_at))
            continue
        if path.suffix.lower() == ".jsonl":
            for item in _read_jsonl(path):
                rows.append(_evidence_record(item, path, created_at=created_at))
        elif path.suffix.lower() == ".json":
            payload = _read_json(path)
            for item in _items_from_json(payload):
                rows.append(_evidence_record(item, path, created_at=created_at))
        else:
            rows.append(
                _evidence_record(
                    {"text": _read_text(path), "title": path.name, "source_type": "text_file"},
                    path,
                    created_at=created_at,
                )
            )
    return rows


def _items_from_json(payload: dict[str, Any]) -> list[dict[str, Any]]:
    for key in ["evidence", "candidates", "sources", "blocks", "claims", "records", "segments", "images"]:
        value = payload.get(key)
        if isinstance(value, list):
            return [item for item in value if isinstance(item, dict)]
    return [payload]


def _evidence_record(item: dict[str, Any], path: Path, *, created_at: str) -> dict[str, Any]:
    text = _normalize(
        str(
            item.get("text")
            or item.get("ocr_text")
            or item.get("transcript")
            or item.get("content")
            or item.get("snippet")
            or item.get("title")
            or ""
        )
    )
    source_url = str(item.get("source_url") or item.get("url") or "")
    source_type = str(item.get("source_type") or item.get("chunk_type") or path.suffix.lower().lstrip(".") or "evidence")
    evidence_id = str(item.get("evidence_id") or item.get("source_id") or _stable_id("evidence", f"{path}:{text}:{source_url}"))
    status = str(item.get("status") or ("accepted" if text else "failed"))
    return {
        "evidence_id": evidence_id,
        "source_id": str(item.get("source_id") or _stable_id("source", source_url or path.name)),
        "source_type": source_type,
        "source_url": source_url,
        "title": str(item.get("title") or path.name),
        "text": text,
        "published_at": str(item.get("published_at") or ""),
        "retrieved_at": str(item.get("retrieved_at") or created_at),
        "content_hash": str(item.get("content_hash") or _hash(text)),
        "backlink": str(item.get("backlink") or source_url or path.as_posix()),
        "artifact_path": path.as_posix(),
        "status": status,
        "failure_reason": str(item.get("failure_reason") or ("" if text else "empty_evidence_text")),
        "repair_suggestion": str(item.get("repair_suggestion") or ("" if text else "Provide evidence text or manual evidence.")),
    }


def _failed_evidence(path: Path, reason: str, created_at: str) -> dict[str, Any]:
    return {
        "evidence_id": _stable_id("evidence", path.as_posix()),
        "source_id": _stable_id("source", path.as_posix()),
        "source_type": "missing_evidence_file",
        "source_url": "",
        "title": path.name,
        "text": "",
        "published_at": "",
        "retrieved_at": created_at,
        "content_hash": "",
        "backlink": path.as_posix(),
        "artifact_path": path.as_posix(),
        "status": "failed",
        "failure_reason": reason,
        "repair_suggestion": "Use an existing evidence file with readable text.",
    }


def _verify_one_claim(claim: dict[str, Any], evidence: list[dict[str, Any]], *, created_at: str) -> dict[str, Any]:
    normalized = _normalize(claim["text"])
    claim_negative = bool(_negative_tokens(normalized))
    positive = _negative_tokens(normalized) if claim_negative else _positive_tokens(normalized)
    supported = []
    conflicting = []
    for item in evidence:
        text = _normalize(item.get("text", ""))
        if not text:
            continue
        text_positive = _positive_tokens(text)
        text_negative = _negative_tokens(text)
        evidence_negative = bool(text_negative)
        evidence_tokens = text_negative if evidence_negative else text_positive
        if _overlap_score(positive, evidence_tokens) < 0.72:
            continue
        if claim_negative == evidence_negative:
            supported.append(_evidence_ref(item, "supporting"))
        else:
            conflicting.append(_evidence_ref(item, "conflicting"))
    freshness_status = _freshness_status(claim, supported)
    status = _verification_status(supported, conflicting, freshness_status)
    confidence = _confidence(status, supported, conflicting)
    return {
        **claim,
        "verification_status": status,
        "confidence": confidence,
        "supporting_sources": supported,
        "conflicting_sources": conflicting,
        "freshness_status": freshness_status,
        "verified_at": created_at,
        "source_trace": [item["source_id"] for item in supported + conflicting],
        "evidence_ids": [item["evidence_id"] for item in supported + conflicting],
        "failure_reason": "" if status in {"verified", "partially_verified"} else _failure_reason(status),
        "repair_suggestion": _repair_suggestion(status),
    }


def _verification_status(
    supported: list[dict[str, Any]],
    conflicting: list[dict[str, Any]],
    freshness_status: str,
) -> str:
    if conflicting and len(conflicting) >= max(1, len(supported)):
        return "conflicting"
    if freshness_status == "outdated":
        return "outdated"
    if len(supported) >= 2:
        return "verified"
    if len(supported) == 1:
        return "partially_verified"
    return "unsupported"


def _confidence(status: str, supported: list[dict[str, Any]], conflicting: list[dict[str, Any]]) -> float:
    if status == "verified":
        return min(0.95, 0.72 + 0.1 * len(supported))
    if status == "partially_verified":
        return 0.62
    if status == "conflicting":
        return max(0.15, 0.4 - 0.08 * len(conflicting))
    if status == "outdated":
        return 0.45
    return 0.2


def _freshness_status(claim: dict[str, Any], supported: list[dict[str, Any]]) -> str:
    text_years = [int(year) for year in re.findall(r"\b(20\d{2}|19\d{2})\b", claim.get("text", ""))]
    source_years = [
        int(year)
        for item in supported
        for year in re.findall(r"\b(20\d{2}|19\d{2})\b", f"{item.get('published_at', '')} {item.get('text', '')}")
    ]
    if text_years and source_years and max(source_years) > max(text_years):
        return "outdated"
    return "fresh" if supported else "unknown"


def _claim_report(rows: list[dict[str, Any]], *, created_at: str) -> dict[str, Any]:
    counts = _status_counts(rows)
    return {
        "schema_version": "claim_verification_report.v1",
        "section": "5.3.0-P1",
        "campaign": "Campaign 3",
        "supplement": "3.0 External Source Memory & Verification",
        "step": "P1 Knowledge Verification Engine and dashboard foundations",
        "status": "passed" if rows else "failed",
        "integration_decision": "real_integration",
        "decision_qualifier": "knowledge_verification_foundations_only",
        "integration_mode": "local_claim_to_external_evidence_verification",
        "generated_at": created_at,
        "claim_count": len(rows),
        "status_counts": counts,
        "claims": rows,
        "runtime_boundary": _runtime_boundary(),
        "safety_boundary": _safety_boundary(),
        "tests_require_real_llm_api_network": False,
        "not_goal_complete": True,
    }


def _knowledge_correctness_report(
    rows: list[dict[str, Any]],
    evidence: list[dict[str, Any]],
    *,
    created_at: str,
) -> dict[str, Any]:
    counts = _status_counts(rows)
    claim_count = max(len(rows), 1)
    correctness = round((counts["verified"] + 0.5 * counts["partially_verified"]) / claim_count, 4)
    coverage = round(
        (counts["verified"] + counts["partially_verified"] + counts["conflicting"] + counts["outdated"]) / claim_count,
        4,
    )
    risk_items = [
        {"claim_id": row["claim_id"], "status": row["verification_status"], "repair_suggestion": row["repair_suggestion"]}
        for row in rows
        if row["verification_status"] not in {"verified", "partially_verified"}
    ]
    return {
        "schema_version": "knowledge_correctness_report.v1",
        "status": "passed" if rows else "failed",
        "generated_at": created_at,
        "claim_count": len(rows),
        "evidence_source_count": len([item for item in evidence if item.get("status") != "failed"]),
        "verified_claims": counts["verified"],
        "partially_verified_claims": counts["partially_verified"],
        "unsupported_claims": counts["unsupported"],
        "outdated_claims": counts["outdated"],
        "conflicting_claims": counts["conflicting"],
        "low_confidence_claims": counts["low_confidence"],
        "needs_human_review_claims": counts["needs_human_review"],
        "overall_correctness": correctness,
        "citation_coverage": coverage,
        "risk_items": risk_items,
        "knowledge_verification_engine_foundations_complete": True,
        "supplement_3_0_complete": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "not_goal_complete": True,
    }


def _answer_grounding_report(answer_text: str, rows: list[dict[str, Any]], *, created_at: str) -> dict[str, Any]:
    answer_rows = [row for row in rows if row.get("source") == "answer"]
    scoped = answer_rows or rows
    counts = _status_counts(scoped)
    claim_count = max(len(scoped), 1)
    grounding = round((counts["verified"] + 0.5 * counts["partially_verified"]) / claim_count, 4)
    return {
        "schema_version": "answer_grounding_report.v1",
        "status": "passed" if scoped else "skipped",
        "generated_at": created_at,
        "answer_present": bool(_normalize(answer_text)),
        "answer_claim_count": len(answer_rows),
        "grounded_claims": counts["verified"] + counts["partially_verified"],
        "unsupported_claims": counts["unsupported"],
        "conflicting_claims": counts["conflicting"],
        "answer_grounding_score": grounding,
        "claims": scoped,
        "supplement_3_0_complete": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "not_goal_complete": True,
    }


def _dashboard(
    correctness: dict[str, Any],
    grounding: dict[str, Any],
    rows: list[dict[str, Any]],
    *,
    created_at: str,
) -> dict[str, Any]:
    return {
        "schema_version": "knowledge_verification_dashboard.v1",
        "status": "passed" if rows else "failed",
        "generated_at": created_at,
        "dashboard_foundation_only": True,
        "not_campaign_4_ui": True,
        "metrics": {
            "overall_correctness": correctness["overall_correctness"],
            "citation_coverage": correctness["citation_coverage"],
            "answer_grounding_score": grounding["answer_grounding_score"],
            "verified_claims": correctness["verified_claims"],
            "unsupported_claims": correctness["unsupported_claims"],
            "outdated_claims": correctness["outdated_claims"],
            "conflicting_claims": correctness["conflicting_claims"],
            "needs_human_review": len(correctness["risk_items"]),
        },
        "status_filters": sorted(VERIFICATION_STATES),
        "human_review_items": correctness["risk_items"],
        "supplement_3_0_complete": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "not_goal_complete": True,
    }


def _source_trace(evidence: list[dict[str, Any]], *, created_at: str) -> dict[str, Any]:
    return {
        "schema_version": "verification_source_trace.v1",
        "generated_at": created_at,
        "source_count": len(evidence),
        "sources": [
            {
                "source_id": item["source_id"],
                "evidence_id": item["evidence_id"],
                "source_type": item["source_type"],
                "source_url": item["source_url"],
                "backlink": item["backlink"],
                "artifact_path": item["artifact_path"],
                "content_hash": item["content_hash"],
                "status": item["status"],
                "failure_reason": item["failure_reason"],
                "repair_suggestion": item["repair_suggestion"],
            }
            for item in evidence
        ],
    }


def _evidence_map(rows: list[dict[str, Any]], evidence: list[dict[str, Any]], *, created_at: str) -> dict[str, Any]:
    return {
        "schema_version": "verification_evidence_map.v1",
        "generated_at": created_at,
        "claim_count": len(rows),
        "evidence_source_count": len(evidence),
        "evidence": [
            {
                "claim_id": row["claim_id"],
                "claim_text": row["text"],
                "verification_status": row["verification_status"],
                "source_ids": row["source_trace"],
                "evidence_ids": row["evidence_ids"],
                "content_hash": row["content_hash"],
                "integration_mode": "external_source_verification_foundation",
                "confidence": row["confidence"],
            }
            for row in rows
        ],
        "knowledge_verification_engine_foundations_complete": True,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "supplement_3_0_complete": False,
    }


def _validate_payloads(
    *,
    claim_report: dict[str, Any],
    correctness: dict[str, Any],
    grounding: dict[str, Any],
    dashboard: dict[str, Any],
    source_trace: dict[str, Any],
    evidence_map: dict[str, Any],
) -> dict[str, Any]:
    errors: list[str] = []
    if claim_report.get("decision_qualifier") != "knowledge_verification_foundations_only":
        errors.append("decision_qualifier_must_be_knowledge_verification_foundations_only")
    if claim_report.get("runtime_boundary", {}).get("supplement_3_0_complete") is not False:
        errors.append("supplement_3_0_must_remain_false")
    if claim_report.get("runtime_boundary", {}).get("campaign_4_active") is not False:
        errors.append("campaign_4_must_remain_false")
    if claim_report.get("runtime_boundary", {}).get("campaign_5_active") is not False:
        errors.append("campaign_5_must_remain_false")
    if claim_report.get("safety_boundary", {}).get("no_arbitrary_shell_execution") is not True:
        errors.append("no_arbitrary_shell_execution_required")
    if dashboard.get("not_campaign_4_ui") is not True:
        errors.append("dashboard_must_not_claim_campaign_4_ui")
    if evidence_map.get("knowledge_verification_engine_foundations_complete") is not True:
        errors.append("evidence_map_must_record_foundation_completion")
    if "sources" not in source_trace:
        errors.append("source_trace_sources_required")
    if correctness.get("supplement_3_0_complete") is not False or grounding.get("supplement_3_0_complete") is not False:
        errors.append("reports_must_not_accept_supplement_3_0")
    for row in claim_report.get("claims", []):
        if row.get("verification_status") not in VERIFICATION_STATES:
            errors.append(f"invalid_verification_status:{row.get('verification_status')}")
        if row.get("verification_status") not in {"verified", "partially_verified"} and not row.get("failure_reason"):
            errors.append(f"failed_claim_requires_failure_reason:{row.get('claim_id')}")
    return {
        "schema_version": "knowledge_verification_validation_report.v1",
        "status": "passed" if not errors else "failed",
        "boundary_errors": errors,
        "claim_count": claim_report.get("claim_count", 0),
        "knowledge_verification_engine_foundations_complete": not errors,
        "knowledge_verification_dashboard_foundation_complete": not errors,
        "supplement_3_0_complete": False,
        "campaign_3_3_0_acceptance_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "bridge_execution_accepted": False,
        "not_goal_complete": True,
    }


def _write_outputs(
    output: Path,
    *,
    claim_report: dict[str, Any],
    correctness: dict[str, Any],
    grounding: dict[str, Any],
    dashboard: dict[str, Any],
    source_trace: dict[str, Any],
    evidence_map: dict[str, Any],
    validation: dict[str, Any],
    progress: list[dict[str, Any]],
) -> None:
    write_json(output / "claim_verification_report.json", claim_report)
    (output / "claim_verification_report.md").write_text(_render_claim_report(claim_report), encoding="utf-8")
    write_json(output / "knowledge_correctness_report.json", correctness)
    (output / "knowledge_correctness_report.md").write_text(_render_correctness_report(correctness), encoding="utf-8")
    write_json(output / "answer_grounding_report.json", grounding)
    (output / "answer_grounding_report.md").write_text(_render_grounding_report(grounding), encoding="utf-8")
    write_json(output / "knowledge_verification_dashboard.json", dashboard)
    write_json(output / "verification_source_trace.json", source_trace)
    write_json(output / "verification_evidence_map.json", evidence_map)
    write_json(output / "knowledge_verification_validation_report.json", validation)
    write_jsonl(output / "progress_events.jsonl", progress)
    run_manifest = {
        "schema_version": "audit_run_manifest.v1",
        "run_id": "external_source_knowledge_verification_foundations",
        "generated_at": claim_report["generated_at"],
        "type": "section_5_supplement_3_0_p1_knowledge_verification_foundations",
        "scope": "CAMPAIGN_3_SUPPLEMENT_3_0_P1_KNOWLEDGE_VERIFICATION_FOUNDATIONS",
        "status": validation["status"],
        "integration_decision": claim_report["integration_decision"],
        "decision_qualifier": claim_report["decision_qualifier"],
        "evidence_files": KNOWLEDGE_VERIFICATION_FILES,
        "next_business_item": "Campaign 3 Supplement 3.0 Acceptance Gate",
        "supplement_3_0_complete": False,
        "campaign_3_3_0_acceptance_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "bridge_execution_accepted": False,
        "not_goal_complete": True,
    }
    write_json(output / "run_manifest.json", run_manifest)
    (output / "run_summary.md").write_text(_render_summary(run_manifest), encoding="utf-8")


def _runtime_boundary() -> dict[str, Any]:
    return {
        "knowledge_verification_engine_foundations_implemented": True,
        "knowledge_verification_dashboard_foundation_implemented": True,
        "external_network_required": False,
        "llm_required": False,
        "opencli_runtime_invoked_by_this_step": False,
        "browser_connector_invoked_by_this_step": False,
        "video_ocr_runtime_invoked_by_this_step": False,
        "supplement_3_0_complete": False,
        "campaign_3_3_0_acceptance_gate_passed": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "bridge_execution_accepted": False,
    }


def _safety_boundary() -> dict[str, Any]:
    return {
        "no_arbitrary_shell_execution": True,
        "no_cookie_import": True,
        "no_login_bypass": True,
        "no_paywall_bypass": True,
        "no_captcha_bypass": True,
        "no_unlimited_crawler": True,
        "user_supplied_or_approved_evidence_only": True,
    }


def _evidence_ref(item: dict[str, Any], match_type: str) -> dict[str, Any]:
    return {
        "source_id": item["source_id"],
        "evidence_id": item["evidence_id"],
        "source_type": item["source_type"],
        "source_url": item["source_url"],
        "title": item["title"],
        "backlink": item["backlink"],
        "content_hash": item["content_hash"],
        "published_at": item["published_at"],
        "text": item["text"],
        "match_type": match_type,
    }


def _status_counts(rows: list[dict[str, Any]]) -> dict[str, int]:
    return {state: len([row for row in rows if row.get("verification_status") == state]) for state in sorted(VERIFICATION_STATES)}


def _failure_reason(status: str) -> str:
    return {
        "unsupported": "No supporting external evidence was found.",
        "outdated": "Newer evidence appears to supersede the claim date.",
        "conflicting": "External evidence conflicts with the claim.",
        "low_confidence": "Available evidence has low confidence.",
        "needs_human_review": "The claim requires manual review.",
    }.get(status, "")


def _repair_suggestion(status: str) -> str:
    return {
        "verified": "No repair required.",
        "partially_verified": "Add another independent source to strengthen verification.",
        "unsupported": "Add approved source evidence or mark the claim for human review.",
        "outdated": "Refresh the claim with newer source evidence.",
        "conflicting": "Resolve the conflict or split the claim by source and date.",
        "low_confidence": "Add stronger source evidence.",
        "needs_human_review": "Review the claim and evidence manually.",
    }.get(status, "Review the claim manually.")


def _positive_tokens(text: str) -> set[str]:
    return {
        token
        for token in re.findall(r"[a-zA-Z0-9_\\-]+", text.lower())
        if len(token) > 2 and token not in {"the", "and", "for", "with", "from", "must", "into", "that", "this", "not"}
    }


def _negative_tokens(text: str) -> set[str]:
    replacements = {
        "does not": "",
        "do not": "",
        "must not": "",
        "cannot": "",
        "can't": "",
        "false": "",
    }
    lowered = text.lower()
    if not any(key in lowered for key in replacements):
        return set()
    for key, value in replacements.items():
        lowered = lowered.replace(key, value)
    return _positive_tokens(lowered)


def _overlap_score(left: set[str], right: set[str]) -> float:
    if not left or not right:
        return 0.0
    return len(left & right) / len(left)


def _sentences(text: str) -> list[str]:
    parts = re.split(r"(?<=[.!?。！？])\s+|\n+", text or "")
    return [_normalize(part) for part in parts if _normalize(part)]


def _claim_like(sentence: str) -> bool:
    lowered = sentence.lower()
    if len(lowered) < 8:
        return False
    return any(
        marker in lowered
        for marker in [
            " is ",
            " are ",
            " must ",
            " should ",
            " supports ",
            " requires ",
            " can ",
            " cannot ",
            " does ",
            " do ",
            " verified",
            "完整",
            "必须",
            "支持",
            "不能",
        ]
    )


def _normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text or "").strip()


def _hash(text: str) -> str:
    return hashlib.sha256(_normalize(text).encode("utf-8")).hexdigest()


def _stable_id(prefix: str, value: str) -> str:
    return f"{prefix}_{hashlib.sha256(value.encode('utf-8')).hexdigest()[:16]}"


def _read_text(path: Path) -> str:
    return Path(path).read_text(encoding="utf-8")


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _progress(events: list[dict[str, Any]], stage: str, status: str, message: str) -> None:
    events.append(
        {
            "event_id": f"evt_{uuid4().hex[:12]}",
            "stage": stage,
            "status": status,
            "timestamp": _now(),
            "message": message,
            "artifact_path": "",
        }
    )


def _now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _render_claim_report(report: dict[str, Any]) -> str:
    rows = "\n".join(
        f"- `{row['verification_status']}` {row['text']}" for row in report.get("claims", [])
    ) or "- No claims"
    return (
        "# Claim Verification Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Decision: `{report['integration_decision']} / {report['decision_qualifier']}`\n"
        f"- Claim count: `{report['claim_count']}`\n\n"
        "## Claims\n\n"
        f"{rows}\n"
    )


def _render_correctness_report(report: dict[str, Any]) -> str:
    return (
        "# Knowledge Correctness Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Overall correctness: `{report['overall_correctness']}`\n"
        f"- Citation coverage: `{report['citation_coverage']}`\n"
        f"- Unsupported claims: `{report['unsupported_claims']}`\n"
        f"- Conflicting claims: `{report['conflicting_claims']}`\n"
    )


def _render_grounding_report(report: dict[str, Any]) -> str:
    return (
        "# Answer Grounding Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Answer grounding score: `{report['answer_grounding_score']}`\n"
        f"- Grounded claims: `{report['grounded_claims']}`\n"
        f"- Unsupported claims: `{report['unsupported_claims']}`\n"
    )


def _render_summary(run_manifest: dict[str, Any]) -> str:
    return (
        "# Knowledge Verification Foundations Summary\n\n"
        f"- Status: `{run_manifest['status']}`\n"
        f"- Decision: `{run_manifest['integration_decision']} / {run_manifest['decision_qualifier']}`\n"
        f"- Next business item: `{run_manifest['next_business_item']}`\n"
        "- This is a Campaign 3 Supplement 3.0 internal foundation, not Supplement 3.0 acceptance, Campaign 4 UI, or Campaign 5 Bridge acceptance.\n"
    )
