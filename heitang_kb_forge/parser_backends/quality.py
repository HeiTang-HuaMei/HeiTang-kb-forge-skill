from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.parser_backends.base import ParserBackendRun
from heitang_kb_forge.parser_backends.review_queue import make_manual_review_queue


def assess_parse_quality(
    run: ParserBackendRun | None = None,
    chunks: list[dict] | None = None,
    default_status: str = "draft_knowledge_package",
    *,
    require_review_for_scanned_pdf: bool = True,
    require_review_for_high_risk_chunks: bool = True,
) -> dict:
    records = [record.to_dict() for record in run.records] if run else []
    chunks = chunks or []
    warnings = list(run.warnings if run else [])
    high_risk_pages = _high_risk_pages(records)
    high_risk_chunks = _high_risk_chunks(records, chunks)
    manual_review_required = bool(
        (require_review_for_scanned_pdf and high_risk_pages)
        or (require_review_for_high_risk_chunks and high_risk_chunks)
    )
    if manual_review_required:
        warnings.append("manual_review_required")
    status = "warning" if high_risk_pages or high_risk_chunks or warnings else "pass"
    return {
        "parse_quality_version": "2.8.0-alpha.1",
        "status": status,
        "kb_trust_status": default_status,
        "manual_review_required": manual_review_required,
        "require_review_for_scanned_pdf": require_review_for_scanned_pdf,
        "require_review_for_high_risk_chunks": require_review_for_high_risk_chunks,
        "high_risk_page_count": len(high_risk_pages),
        "high_risk_chunk_count": len(high_risk_chunks),
        "warnings": warnings,
        "high_risk_pages": high_risk_pages,
        "high_risk_chunks": high_risk_chunks,
        "manual_review_queue": make_manual_review_queue(high_risk_pages, high_risk_chunks),
    }


def make_ocr_risk_report(quality: dict) -> dict:
    return {
        "ocr_risk_report_version": "2.8.0-alpha.1",
        "status": "warning" if quality["high_risk_page_count"] or quality["high_risk_chunk_count"] else "pass",
        "ocr_review_required": quality["manual_review_required"],
        "high_risk_page_count": quality["high_risk_page_count"],
        "high_risk_chunk_count": quality["high_risk_chunk_count"],
        "warnings": quality["warnings"],
    }


def load_parse_run(path: Path) -> ParserBackendRun | None:
    target = path / "parser_backend_result.json" if path.is_dir() else path
    if not target.exists():
        return None
    from heitang_kb_forge.parser_backends.base import ParserBackendRecord, ParserBackendRun

    payload = json.loads(target.read_text(encoding="utf-8"))
    records = []
    for record in payload.get("records", []):
        record_payload = {key: value for key, value in record.items() if key != "adapter_result"}
        record_payload.setdefault("adapter_contract", payload.get("adapter_contract", {}))
        records.append(ParserBackendRecord(**record_payload))
    return ParserBackendRun(
        backend_name=payload.get("backend_name", "unknown"),
        backend_version=payload.get("backend_version", "unknown"),
        command=payload.get("command", ""),
        status=payload.get("status", "unknown"),
        source_count=payload.get("source_count", len(records)),
        records=records,
        warnings=payload.get("warnings", []),
        kb_trust_status=payload.get("kb_trust_status", "raw_parse_output"),
        error_code=payload.get("error_code"),
        fallback_result=payload.get("fallback_result"),
        repair_suggestion=payload.get("repair_suggestion"),
        audit_trace=payload.get("audit_trace"),
        adapter_contract=payload.get("adapter_contract", {}),
    )


def load_chunks(path: Path) -> list[dict]:
    target = path / "chunks.jsonl"
    if not target.exists():
        return []
    rows = []
    for line in target.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows


def _high_risk_pages(records: list[dict]) -> list[dict]:
    rows = []
    for record in records:
        warnings = " ".join(record.get("warnings", []))
        if record.get("source_type") == "pdf" and ("ocr" in warnings.lower() or record.get("confidence", 1.0) < 0.75):
            rows.append(
                {
                    "item_type": "page",
                    "source_path": record.get("source_path", ""),
                    "page": record.get("metadata", {}).get("page"),
                    "reason": "pdf_or_ocr_parse_requires_review",
                    "confidence": record.get("confidence"),
                }
            )
    return rows


def _high_risk_chunks(records: list[dict], chunks: list[dict]) -> list[dict]:
    rows = []
    for record in records:
        if record.get("status") in {"failed", "empty", "unavailable", "unsupported"} or record.get("confidence", 1.0) < 0.75:
            rows.append(
                {
                    "item_type": "parse_record",
                    "source_path": record.get("source_path", ""),
                    "reason": f"parse_status_{record.get('status')}",
                    "confidence": record.get("confidence"),
                }
            )
    for chunk in chunks:
        metadata = chunk.get("metadata") or {}
        if metadata.get("parse_confidence") is not None and float(metadata["parse_confidence"]) < 0.75:
            rows.append(
                {
                    "item_type": "chunk",
                    "source_path": chunk.get("source_path", ""),
                    "chunk_id": chunk.get("chunk_id"),
                    "reason": "low_parse_confidence",
                    "confidence": metadata.get("parse_confidence"),
                }
            )
    return rows
