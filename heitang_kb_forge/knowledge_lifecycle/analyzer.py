from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json


KNOWLEDGE_LIFECYCLE_OUTPUT_FILES = [
    "knowledge_lifecycle_report.json",
    "knowledge_lifecycle_report.md",
    "confidence_report.json",
    "stale_evidence_report.json",
    "refresh_suggestions.json",
    "forgetting_retention_plan.json",
    "source_trace.json",
]


def analyze_knowledge_lifecycle(
    package_dir: Path,
    *,
    max_age_days: int = 180,
    min_confidence: float = 0.65,
    now: datetime | None = None,
) -> dict[str, Any]:
    package_dir = Path(package_dir)
    if not package_dir.exists():
        raise FileNotFoundError(f"knowledge package does not exist: {package_dir}")
    if not package_dir.is_dir():
        raise NotADirectoryError(f"knowledge package must be a directory: {package_dir}")

    now_utc = (now or datetime.now(timezone.utc)).astimezone(timezone.utc)
    manifest = _read_json(package_dir / "manifest.json", default={})
    chunks = _read_jsonl(package_dir / "chunks.jsonl")
    evidence_map = _read_json(package_dir / "evidence_map.json", default={"chunks": {}})
    quality = _read_json(package_dir / "quality_report.json", default={})
    source_inventory = _read_json(package_dir / "source_inventory.json", default={})
    package_created_at = _parse_datetime(manifest.get("created_at") or manifest.get("generated_at"))
    package_age_days = _age_days(package_created_at, now_utc)

    confidence_items = [
        _confidence_item(chunk, evidence_map.get("chunks", {}), quality)
        for chunk in chunks
    ]
    stale_items = [
        _stale_item(item, package_age_days, max_age_days)
        for item in confidence_items
        if package_age_days is not None and package_age_days > max_age_days
    ]
    refresh_suggestions = [
        _refresh_suggestion(item, package_age_days, max_age_days)
        for item in confidence_items
        if item["confidence"] < min_confidence
        or (package_age_days is not None and package_age_days > max_age_days)
    ]
    retention_items = [
        _retention_item(item, min_confidence, package_age_days, max_age_days)
        for item in confidence_items
    ]
    source_trace = {
        "source_trace_version": "knowledge_lifecycle.v1",
        "source_trace_preserved": all(item["source_file"] for item in confidence_items) if confidence_items else False,
        "package_dir": str(package_dir),
        "source_count": manifest.get("source_count", len(_source_paths(confidence_items))),
        "chunk_count": len(chunks),
        "source_inventory_present": bool(source_inventory),
        "sources": sorted(_source_paths(confidence_items)),
    }
    confidence_report = {
        "schema_version": "knowledge_confidence_report.v1",
        "status": "passed" if confidence_items else "warning",
        "min_confidence": min_confidence,
        "average_confidence": _average(item["confidence"] for item in confidence_items),
        "low_confidence_count": sum(1 for item in confidence_items if item["confidence"] < min_confidence),
        "items": confidence_items,
    }
    stale_report = {
        "schema_version": "stale_evidence_report.v1",
        "status": "passed" if not stale_items else "needs_refresh",
        "max_age_days": max_age_days,
        "package_age_days": package_age_days,
        "stale_count": len(stale_items),
        "items": stale_items,
    }
    refresh_report = {
        "schema_version": "refresh_suggestions.v1",
        "status": "passed" if refresh_suggestions else "none",
        "suggestion_count": len(refresh_suggestions),
        "suggestions": refresh_suggestions,
    }
    retention_plan = {
        "schema_version": "forgetting_retention_plan.v1",
        "status": "passed" if retention_items else "warning",
        "policy": {
            "min_confidence": min_confidence,
            "max_age_days": max_age_days,
            "llm_required": False,
            "network_required": False,
            "external_runtime_required": False,
        },
        "items": retention_items,
    }
    lifecycle_report = {
        "schema_version": "knowledge_lifecycle_report.v1",
        "status": "passed" if chunks else "failed",
        "project_source": "llm_wiki_v2",
        "integration_mode": "capability_fusion",
        "vendor_runtime_integrated": False,
        "external_code_copied": False,
        "llm_required": False,
        "network_required": False,
        "external_runtime_required": False,
        "knowledge_package": str(package_dir),
        "package_id": manifest.get("package_id"),
        "generated_at": now_utc.isoformat(),
        "chunk_count": len(chunks),
        "source_count": manifest.get("source_count", len(_source_paths(confidence_items))),
        "confidence_status": confidence_report["status"],
        "stale_evidence_status": stale_report["status"],
        "refresh_suggestion_count": refresh_report["suggestion_count"],
        "retention_item_count": len(retention_items),
        "source_trace_preserved": source_trace["source_trace_preserved"],
        "outputs": KNOWLEDGE_LIFECYCLE_OUTPUT_FILES,
        "final_target_not_downgraded": True,
        "remaining_gap": "This proves local knowledge lifecycle analysis for one accepted knowledge package, not Campaign 3 completion, full UI workflow, Core Bridge acceptance, configuration, Full Gate, or EXE delivery.",
        "next_required_e2e_step": "Process Section 5 item 5.2 WeKnora only after the LLM Wiki v2 integration decision and UI impact evidence are accepted.",
        "not_goal_complete": True,
    }
    return {
        "knowledge_lifecycle_report": lifecycle_report,
        "confidence_report": confidence_report,
        "stale_evidence_report": stale_report,
        "refresh_suggestions": refresh_report,
        "forgetting_retention_plan": retention_plan,
        "source_trace": source_trace,
    }


def write_knowledge_lifecycle_outputs(
    package_dir: Path,
    output: Path,
    *,
    max_age_days: int = 180,
    min_confidence: float = 0.65,
    now: datetime | None = None,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    payload = analyze_knowledge_lifecycle(
        package_dir,
        max_age_days=max_age_days,
        min_confidence=min_confidence,
        now=now,
    )
    write_json(output / "knowledge_lifecycle_report.json", payload["knowledge_lifecycle_report"])
    write_json(output / "confidence_report.json", payload["confidence_report"])
    write_json(output / "stale_evidence_report.json", payload["stale_evidence_report"])
    write_json(output / "refresh_suggestions.json", payload["refresh_suggestions"])
    write_json(output / "forgetting_retention_plan.json", payload["forgetting_retention_plan"])
    write_json(output / "source_trace.json", payload["source_trace"])
    (output / "knowledge_lifecycle_report.md").write_text(
        render_knowledge_lifecycle_report(payload),
        encoding="utf-8",
    )
    return {
        "status": payload["knowledge_lifecycle_report"]["status"],
        "output_files": KNOWLEDGE_LIFECYCLE_OUTPUT_FILES,
        **payload,
    }


def render_knowledge_lifecycle_report(payload: dict[str, Any]) -> str:
    report = payload["knowledge_lifecycle_report"]
    confidence = payload["confidence_report"]
    stale = payload["stale_evidence_report"]
    retention = payload["forgetting_retention_plan"]
    return f"""# Knowledge Lifecycle Report

- Status: {report['status']}
- Integration mode: {report['integration_mode']}
- Vendor runtime integrated: {report['vendor_runtime_integrated']}
- LLM required: {report['llm_required']}
- Network required: {report['network_required']}
- Chunk count: {report['chunk_count']}
- Source trace preserved: {report['source_trace_preserved']}
- Average confidence: {confidence['average_confidence']}
- Stale evidence count: {stale['stale_count']}
- Retention items: {len(retention['items'])}

This report is a local capability-fusion analysis inspired by LLM Wiki v2 patterns. It does not vendor, bundle, or execute an external LLM Wiki runtime.
"""


def _read_json(path: Path, *, default: Any) -> Any:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8-sig").splitlines()
        if line.strip()
    ]


def _confidence_item(chunk: dict[str, Any], evidence_chunks: dict[str, Any], quality: dict[str, Any]) -> dict[str, Any]:
    chunk_id = str(chunk.get("chunk_id") or "")
    evidence = evidence_chunks.get(chunk_id, {})
    source_file = evidence.get("source_file") or chunk.get("source_path") or ""
    score = 0.35
    if chunk.get("text"):
        score += 0.2
    if source_file:
        score += 0.2
    if evidence.get("evidence_id"):
        score += 0.15
    if quality.get("status") in {"pass", "passed"} or quality.get("quality_status") in {"good", "excellent"}:
        score += 0.1
    return {
        "chunk_id": chunk_id,
        "title": chunk.get("title") or "",
        "source_file": source_file,
        "evidence_id": evidence.get("evidence_id"),
        "confidence": round(min(score, 1.0), 3),
        "confidence_factors": {
            "has_text": bool(chunk.get("text")),
            "has_source_trace": bool(source_file),
            "has_evidence_id": bool(evidence.get("evidence_id")),
            "quality_report_present": bool(quality),
        },
    }


def _stale_item(item: dict[str, Any], package_age_days: int | None, max_age_days: int) -> dict[str, Any]:
    return {
        "chunk_id": item["chunk_id"],
        "source_file": item["source_file"],
        "package_age_days": package_age_days,
        "max_age_days": max_age_days,
        "reason": "package_age_exceeds_policy",
    }


def _refresh_suggestion(item: dict[str, Any], package_age_days: int | None, max_age_days: int) -> dict[str, Any]:
    reasons = []
    if package_age_days is not None and package_age_days > max_age_days:
        reasons.append("stale_evidence")
    if not item["confidence_factors"]["has_source_trace"]:
        reasons.append("missing_source_trace")
    if not item["confidence_factors"]["has_evidence_id"]:
        reasons.append("missing_evidence_id")
    if item["confidence"] < 1.0:
        reasons.append("confidence_below_perfect")
    return {
        "chunk_id": item["chunk_id"],
        "source_file": item["source_file"],
        "priority": "high" if "stale_evidence" in reasons else "medium",
        "reasons": reasons,
        "recommended_action": "refresh_source_and_rebuild_knowledge_package" if reasons else "retain",
    }


def _retention_item(item: dict[str, Any], min_confidence: float, package_age_days: int | None, max_age_days: int) -> dict[str, Any]:
    stale = package_age_days is not None and package_age_days > max_age_days
    if item["confidence"] < min_confidence:
        decision = "quarantine_for_review"
    elif stale:
        decision = "retain_but_refresh"
    else:
        decision = "retain"
    return {
        "chunk_id": item["chunk_id"],
        "source_file": item["source_file"],
        "confidence": item["confidence"],
        "decision": decision,
        "forgetting_allowed": decision == "quarantine_for_review",
    }


def _parse_datetime(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(timezone.utc)
    except ValueError:
        return None


def _age_days(start: datetime | None, now: datetime) -> int | None:
    if start is None:
        return None
    return max((now - start).days, 0)


def _average(values: Any) -> float:
    items = list(values)
    if not items:
        return 0.0
    return round(sum(items) / len(items), 3)


def _source_paths(items: list[dict[str, Any]]) -> set[str]:
    return {item["source_file"] for item in items if item.get("source_file")}
