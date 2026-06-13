from __future__ import annotations

import hashlib
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


MANUAL_EVIDENCE_FILES = [
    "manual_evidence_manifest.json",
    "manual_evidence_blocks.jsonl",
    "manual_source_trace.json",
    "manual_evidence_map.json",
    "manual_evidence_validation_report.json",
    "manual_evidence_report.md",
    "run_manifest.json",
    "run_summary.md",
]

ACCEPTED_MANUAL_INPUT_TYPES = {
    "copied_text",
    "pasted_text",
    "screenshot_metadata",
    "long_image_metadata",
    "subtitle_metadata",
    "exported_html_metadata",
    "user_note",
    "manual_source_note",
}

STATUS_ACCEPTED = "accepted"
STATUS_EMPTY_INPUT = "empty_input"
STATUS_UNSUPPORTED_TYPE = "unsupported_manual_type"
STATUS_MISSING_CONTEXT = "missing_source_context"
STATUS_SECRET_BLOCKED = "blocked_for_sensitive_secret"
STATUS_VALIDATION_FAILED = "validation_failed"

MANUAL_STATUS_VALUES = {
    STATUS_ACCEPTED,
    STATUS_EMPTY_INPUT,
    STATUS_UNSUPPORTED_TYPE,
    STATUS_MISSING_CONTEXT,
    STATUS_SECRET_BLOCKED,
    STATUS_VALIDATION_FAILED,
}

TEXTUAL_MANUAL_TYPES = {
    "copied_text",
    "pasted_text",
    "user_note",
    "manual_source_note",
}

SECRET_PATTERNS = [
    re.compile(r"(?i)\b(api[_-]?key|access[_-]?token|auth[_-]?token|secret|password|cookie)\b\s*[:=]\s*\S+"),
    re.compile(r"(?i)\b(bearer|basic)\s+[A-Za-z0-9._~+/=-]{16,}"),
    re.compile(r"\bsk-[A-Za-z0-9_-]{16,}\b"),
    re.compile(r"\b[A-Za-z0-9_-]{24,}\.[A-Za-z0-9_-]{24,}\.[A-Za-z0-9_-]{16,}\b"),
]


def import_manual_evidence(
    output: Path,
    *,
    copied_text: str | None = None,
    input_files: list[Path] | None = None,
    title: str | None = None,
    source_url: str | None = None,
    source_type: str = "manual_evidence",
    user_note: str | None = None,
    manual_input_type: str | None = None,
    imported_at: str | None = None,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    imported_at = imported_at or _now()
    manual_type = manual_input_type or ("copied_text" if copied_text is not None else None)
    records = _build_records(
        copied_text=copied_text,
        input_files=input_files or [],
        title=title,
        source_url=source_url,
        source_type=source_type,
        user_note=user_note,
        manual_input_type=manual_type,
        created_at=imported_at,
    )
    blocks = [_block_for_record(record) for record in records]
    source_trace = _source_trace(records)
    evidence_map = _evidence_map(records, blocks)
    accepted_count = sum(1 for record in records if record["status"] == STATUS_ACCEPTED)
    failed_count = len(records) - accepted_count
    status = "passed" if accepted_count > 0 and failed_count == 0 else "failed"
    if accepted_count > 0 and failed_count > 0:
        status = "partial"
    manifest = {
        "schema_version": "manual_evidence_manifest.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "supplement": "3.0 External Source Memory & Verification",
        "step": "P0 Manual Evidence Upload",
        "status": status,
        "integration_decision": "real_integration" if accepted_count > 0 else "needs_strengthening",
        "decision_qualifier": "manual_evidence_upload_only" if accepted_count > 0 else "manual_evidence_validation_failed",
        "integration_mode": "user_supplied_manual_evidence_to_traceable_blocks",
        "created_at": imported_at,
        "imported_at": imported_at,
        "source_count": len(records),
        "accepted_count": accepted_count,
        "failed_count": failed_count,
        "block_count": len(blocks),
        "text_block_count": sum(1 for block in blocks if block["chunk_type"] == "text" and block["status"] == STATUS_ACCEPTED),
        "metadata_block_count": sum(1 for block in blocks if block["chunk_type"] != "text"),
        "isolated_pending_count": failed_count,
        "failure_isolation": True,
        "llm_request_count": 0,
        "llm_tokens_used": 0,
        "runtime_boundary": _runtime_boundary(manual_integrated=accepted_count > 0),
        "safety_boundary": _safety_boundary(),
        "output_files": MANUAL_EVIDENCE_FILES,
        "records": records,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Manual Evidence Upload records user-supplied text and metadata-only manual evidence as traceable "
            "manual blocks, source_trace, evidence_map, content_hash, and manifest backlinks. It does not perform "
            "OCR, video transcription, authenticated browser reading, OpenCLI expansion, UI workflow acceptance, "
            "Core Bridge execution acceptance, Supplement 3.0 acceptance, Supplement 4.0, Campaign 4, Full Gate, "
            "EXE packaging, or release."
        ),
        "next_required_e2e_step": (
            "Run Campaign 3 Supplement 3.0 P0 unified Source Trace / Evidence Map, progress events, "
            "and failure isolation only."
        ),
        "not_goal_complete": True,
    }
    validation = validate_manual_evidence_payload(manifest, blocks, source_trace, evidence_map)
    if validation["status"] == "failed" and manifest["status"] == "passed":
        manifest["status"] = "failed"
        manifest["integration_decision"] = "needs_strengthening"
        manifest["decision_qualifier"] = STATUS_VALIDATION_FAILED
        validation = validate_manual_evidence_payload(manifest, blocks, source_trace, evidence_map)
    _write_outputs(output, manifest, blocks, source_trace, evidence_map, validation)
    return manifest | {"validation": validation}


def validate_manual_evidence(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [file_name for file_name in MANUAL_EVIDENCE_FILES if not (library / file_name).exists()]
    if missing:
        return _validation_failure("required_files_missing", missing_files=missing)
    manifest = _read_json(library / "manual_evidence_manifest.json")
    blocks = _read_jsonl(library / "manual_evidence_blocks.jsonl")
    source_trace = _read_json(library / "manual_source_trace.json")
    evidence_map = _read_json(library / "manual_evidence_map.json")
    result = validate_manual_evidence_payload(manifest, blocks, source_trace, evidence_map)
    return {**result, "required_files": MANUAL_EVIDENCE_FILES, "missing_files": missing}


def write_manual_evidence_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_manual_evidence(library)
    write_json(output / "manual_evidence_validation_report.json", result)
    return result


def validate_manual_evidence_payload(
    manifest: dict[str, Any],
    blocks: list[dict[str, Any]],
    source_trace: dict[str, Any],
    evidence_map: dict[str, Any],
) -> dict[str, Any]:
    runtime = manifest.get("runtime_boundary", {})
    safety = manifest.get("safety_boundary", {})
    records = manifest.get("records", [])
    errors: list[str] = []
    accepted_count = manifest.get("accepted_count", 0)
    if manifest.get("status") not in {"passed", "partial", "failed"}:
        errors.append("manifest_status_invalid")
    if accepted_count and manifest.get("integration_decision") != "real_integration":
        errors.append("accepted_manifest_requires_real_integration")
    if accepted_count and manifest.get("decision_qualifier") != "manual_evidence_upload_only":
        errors.append("decision_qualifier_must_be_manual_evidence_upload_only")
    if runtime.get("manual_evidence_processing_implemented") is not bool(accepted_count):
        errors.append("manual_evidence_processing_implemented_must_match_accepted_count")
    for field in [
        "authenticated_browser_runtime_integrated",
        "opencli_expansion_implemented",
        "platform_fetch_completed",
        "video_transcription_implemented",
        "visual_ocr_runtime_integrated",
        "knowledge_verification_runtime_implemented",
        "ui_workflow_accepted",
        "bridge_execution_accepted",
        "campaign_3_3_0_accepted",
        "campaign_3_4_0_active",
        "campaign_3_accepted",
        "campaign_4_allowed",
        "full_gate_passed",
        "exe_packaging_done",
    ]:
        if runtime.get(field) is not False:
            errors.append(f"{field}_must_be_false")
    for field in [
        "user_supplied_only",
        "user_triggered_only",
        "metadata_only_for_local_files",
        "no_login_bypass",
        "no_paywall_bypass",
        "no_captcha_bypass",
        "no_cookie_import",
        "no_plaintext_cookie_persistence",
        "no_cookie_upload",
        "no_browser_session_used",
        "no_external_upload",
        "no_arbitrary_shell_execution",
        "secret_guard_enabled",
    ]:
        if safety.get(field) is not True:
            errors.append(f"{field}_must_be_true")
    if not records:
        errors.append("manual_evidence_records_required")
    if manifest.get("source_count") != len(records):
        errors.append("source_count_must_match_records")
    if source_trace.get("source_count") != len(records):
        errors.append("source_trace_count_must_match_records")
    if evidence_map.get("evidence_count") != len(blocks):
        errors.append("evidence_count_must_match_blocks")
    for record in records:
        _validate_record(record, errors)
    for block in blocks:
        _validate_block(block, errors)
    if accepted_count and not blocks:
        errors.append("accepted_manual_evidence_requires_blocks")
    status = "passed" if not errors else "failed"
    return {
        "schema_version": "manual_evidence_validation_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "status": status,
        "boundary_errors": errors,
        "source_count": manifest.get("source_count", 0),
        "accepted_count": accepted_count,
        "failed_count": manifest.get("failed_count", 0),
        "block_count": len(blocks),
        "manual_evidence_processing_implemented": runtime.get("manual_evidence_processing_implemented"),
        "opencli_expansion_implemented": runtime.get("opencli_expansion_implemented"),
        "platform_fetch_completed": runtime.get("platform_fetch_completed"),
        "visual_ocr_runtime_integrated": runtime.get("visual_ocr_runtime_integrated"),
        "video_transcription_implemented": runtime.get("video_transcription_implemented"),
        "ui_workflow_accepted": runtime.get("ui_workflow_accepted"),
        "bridge_execution_accepted": runtime.get("bridge_execution_accepted"),
        "llm_request_count": manifest.get("llm_request_count", 0),
        "llm_tokens_used": manifest.get("llm_tokens_used", 0),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": manifest.get("remaining_gap", ""),
        "next_required_e2e_step": manifest.get("next_required_e2e_step", ""),
        "not_goal_complete": True,
    }


def _build_records(
    *,
    copied_text: str | None,
    input_files: list[Path],
    title: str | None,
    source_url: str | None,
    source_type: str,
    user_note: str | None,
    manual_input_type: str | None,
    created_at: str,
) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    if copied_text is not None or manual_input_type is not None:
        records.append(
            _record_from_text(
                text=copied_text or "",
                title=title,
                source_url=source_url,
                source_type=source_type,
                user_note=user_note,
                manual_input_type=manual_input_type or "copied_text",
                created_at=created_at,
            )
        )
    for path in input_files:
        records.append(
            _record_from_file_metadata(
                Path(path),
                title=title,
                source_url=source_url,
                source_type=source_type,
                user_note=user_note,
                created_at=created_at,
            )
        )
    return records


def _record_from_text(
    *,
    text: str,
    title: str | None,
    source_url: str | None,
    source_type: str,
    user_note: str | None,
    manual_input_type: str,
    created_at: str,
) -> dict[str, Any]:
    normalized = _normalize_text(text)
    context_note = _normalize_text(user_note or "")
    if _detect_secret(text) or _detect_secret(user_note or ""):
        return _failure_record(
            manual_input_type=manual_input_type,
            status=STATUS_SECRET_BLOCKED,
            title=title or "Manual evidence blocked",
            source_type=source_type,
            source_url=source_url,
            user_note="[redacted: suspected sensitive secret]",
            created_at=created_at,
            metadata={"redaction": "content_not_persisted_due_to_secret_guard"},
            reason="Manual evidence contained a suspected API key, token, cookie, password, or secret.",
        )
    if manual_input_type not in ACCEPTED_MANUAL_INPUT_TYPES:
        return _failure_record(
            manual_input_type=manual_input_type,
            status=STATUS_UNSUPPORTED_TYPE,
            title=title or "Unsupported manual evidence",
            source_type=source_type,
            source_url=source_url,
            user_note=context_note,
            created_at=created_at,
            metadata={"allowed_manual_input_types": sorted(ACCEPTED_MANUAL_INPUT_TYPES)},
            reason=f"Unsupported manual input type: {manual_input_type}",
        )
    if manual_input_type not in TEXTUAL_MANUAL_TYPES:
        return _failure_record(
            manual_input_type=manual_input_type,
            status=STATUS_UNSUPPORTED_TYPE,
            title=title or "Unsupported text payload type",
            source_type=source_type,
            source_url=source_url,
            user_note=context_note,
            created_at=created_at,
            metadata={"textual_manual_input_types": sorted(TEXTUAL_MANUAL_TYPES)},
            reason=f"Manual input type {manual_input_type} requires file metadata, not text payload.",
        )
    if not normalized:
        return _failure_record(
            manual_input_type=manual_input_type,
            status=STATUS_EMPTY_INPUT,
            title=title or "Empty manual evidence",
            source_type=source_type,
            source_url=source_url,
            user_note=context_note,
            created_at=created_at,
            metadata={},
            reason="Manual evidence text is empty.",
        )
    if not (source_url or context_note or title):
        return _failure_record(
            manual_input_type=manual_input_type,
            status=STATUS_MISSING_CONTEXT,
            title=title or "Manual evidence missing context",
            source_type=source_type,
            source_url=source_url,
            user_note=context_note,
            created_at=created_at,
            metadata={},
            reason="Manual evidence requires title, source URL, or user note for source context.",
        )
    evidence_id = _stable_id("manual_evidence", f"{manual_input_type}:{normalized}:{source_url or ''}:{context_note}")
    trace = _trace(evidence_id=evidence_id, source_url=source_url, created_at=created_at, status=STATUS_ACCEPTED)
    return {
        "evidence_id": evidence_id,
        "source_type": source_type,
        "manual_input_type": manual_input_type,
        "title": title or "Manual text evidence",
        "user_provided_source_url": source_url or "",
        "user_note": context_note,
        "content_hash": _sha256(normalized),
        "created_at": created_at,
        "text": normalized,
        "metadata": {"metadata_only": False, "secret_guard": "passed"},
        "trace": trace,
        "status": STATUS_ACCEPTED,
        "failure_reason": "",
    }


def _record_from_file_metadata(
    path: Path,
    *,
    title: str | None,
    source_url: str | None,
    source_type: str,
    user_note: str | None,
    created_at: str,
) -> dict[str, Any]:
    manual_input_type = _manual_type_for_file(path)
    context_note = _normalize_text(user_note or "")
    if _detect_secret(str(path)) or _detect_secret(user_note or ""):
        return _failure_record(
            manual_input_type=manual_input_type,
            status=STATUS_SECRET_BLOCKED,
            title=title or "Manual file metadata blocked",
            source_type=source_type,
            source_url=source_url,
            user_note="[redacted: suspected sensitive secret]",
            created_at=created_at,
            metadata={"redaction": "file_path_not_persisted_due_to_secret_guard"},
            reason="Manual file metadata contained a suspected API key, token, cookie, password, or secret.",
        )
    if manual_input_type not in ACCEPTED_MANUAL_INPUT_TYPES:
        return _failure_record(
            manual_input_type=manual_input_type,
            status=STATUS_UNSUPPORTED_TYPE,
            title=title or path.name,
            source_type=source_type,
            source_url=source_url,
            user_note=context_note,
            created_at=created_at,
            metadata={"file_name": path.name, "file_extension": path.suffix.lower()},
            reason=f"Unsupported manual evidence file type: {path.suffix.lower() or '<none>'}",
        )
    if not (source_url or context_note or title):
        return _failure_record(
            manual_input_type=manual_input_type,
            status=STATUS_MISSING_CONTEXT,
            title=title or path.name,
            source_type=source_type,
            source_url=source_url,
            user_note=context_note,
            created_at=created_at,
            metadata={"file_name": path.name, "file_extension": path.suffix.lower()},
            reason="Manual file evidence requires title, source URL, or user note for source context.",
        )
    metadata = _file_metadata(path)
    evidence_id = _stable_id("manual_evidence", f"{manual_input_type}:{metadata['file_name']}:{metadata['path_hash']}")
    metadata["metadata_only"] = True
    metadata["secret_guard"] = "passed"
    trace = _trace(evidence_id=evidence_id, source_url=source_url, created_at=created_at, status=STATUS_ACCEPTED)
    return {
        "evidence_id": evidence_id,
        "source_type": source_type,
        "manual_input_type": manual_input_type,
        "title": title or path.name,
        "user_provided_source_url": source_url or "",
        "user_note": context_note,
        "content_hash": _sha256(f"{manual_input_type}:{metadata['file_name']}:{metadata['path_hash']}:{metadata.get('size_bytes', '')}"),
        "created_at": created_at,
        "text": "",
        "metadata": metadata,
        "trace": trace,
        "status": STATUS_ACCEPTED,
        "failure_reason": "",
    }


def _failure_record(
    *,
    manual_input_type: str,
    status: str,
    title: str,
    source_type: str,
    source_url: str | None,
    user_note: str,
    created_at: str,
    metadata: dict[str, Any],
    reason: str,
) -> dict[str, Any]:
    sanitized_title = _redact_if_secret(title)
    sanitized_source_url = "" if _detect_secret(source_url or "") else (source_url or "")
    evidence_id = _stable_id("manual_evidence", f"{manual_input_type}:{status}:{sanitized_title}:{reason}")
    return {
        "evidence_id": evidence_id,
        "source_type": source_type,
        "manual_input_type": manual_input_type,
        "title": sanitized_title,
        "user_provided_source_url": sanitized_source_url,
        "user_note": user_note,
        "content_hash": _sha256(f"{manual_input_type}:{status}:{sanitized_title}:{reason}"),
        "created_at": created_at,
        "text": "",
        "metadata": metadata | {"metadata_only": True},
        "trace": _trace(evidence_id=evidence_id, source_url=sanitized_source_url, created_at=created_at, status=status),
        "status": status,
        "failure_reason": reason,
    }


def _block_for_record(record: dict[str, Any]) -> dict[str, Any]:
    chunk_type = "text" if record["text"] else "layout_block"
    chunk_id = _stable_id("manual_chunk", f"{record['evidence_id']}:{record['content_hash']}")
    return {
        "chunk_id": chunk_id,
        "chunk_type": chunk_type,
        "evidence_id": record["evidence_id"],
        "source_type": record["source_type"],
        "manual_input_type": record["manual_input_type"],
        "source_url": record["user_provided_source_url"],
        "platform": "manual_evidence",
        "title": record["title"],
        "author": "user_supplied",
        "published_at": "",
        "retrieved_at": record["created_at"],
        "created_at": record["created_at"],
        "content_hash": record["content_hash"],
        "text": record["text"],
        "ocr_text": "",
        "visual_summary": "",
        "timestamp_start": "",
        "timestamp_end": "",
        "image_index": "",
        "bbox": "",
        "backlink": f"manual_evidence_manifest.json#{record['evidence_id']}",
        "confidence": 0.9 if record["status"] == STATUS_ACCEPTED else 0.0,
        "status": record["status"],
        "processing_status": record["status"],
        "failure_reason": record["failure_reason"],
        "metadata": record["metadata"],
        "trace": record["trace"],
    }


def _source_trace(records: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "schema_version": "manual_source_trace.v1",
        "source_trace_required": True,
        "source_count": len(records),
        "sources": [
            {
                "evidence_id": record["evidence_id"],
                "source_type": record["source_type"],
                "manual_input_type": record["manual_input_type"],
                "user_provided_source_url": record["user_provided_source_url"],
                "title": record["title"],
                "user_note": record["user_note"],
                "created_at": record["created_at"],
                "content_hash": record["content_hash"],
                "backlink": f"manual_evidence_manifest.json#{record['evidence_id']}",
                "trace_status": record["status"],
                "failure_reason": record["failure_reason"],
                "metadata": record["metadata"],
                "trace": record["trace"],
            }
            for record in records
        ],
    }


def _evidence_map(records: list[dict[str, Any]], blocks: list[dict[str, Any]]) -> dict[str, Any]:
    records_by_id = {record["evidence_id"]: record for record in records}
    evidence = []
    for block in blocks:
        record = records_by_id[block["evidence_id"]]
        evidence.append(
            {
                "evidence_id": record["evidence_id"],
                "chunk_id": block["chunk_id"],
                "source_type": record["source_type"],
                "manual_input_type": record["manual_input_type"],
                "support_status": (
                    "manual_evidence_accepted"
                    if record["status"] == STATUS_ACCEPTED
                    else f"manual_evidence_{record['status']}"
                ),
                "confidence": block["confidence"],
                "content_hash": record["content_hash"],
                "backlink": block["backlink"],
                "failure_reason": record["failure_reason"],
                "trace": record["trace"],
            }
        )
    return {
        "schema_version": "manual_evidence_map.v1",
        "evidence_map_required": True,
        "evidence_count": len(evidence),
        "evidence": evidence,
    }


def _runtime_boundary(*, manual_integrated: bool) -> dict[str, bool]:
    return {
        "manual_evidence_processing_implemented": manual_integrated,
        "manual_text_import_implemented": manual_integrated,
        "manual_file_metadata_import_implemented": manual_integrated,
        "generic_web_url_ingestion_implemented": True,
        "platform_preflight_implemented": True,
        "opencli_external_search_verification_implemented": True,
        "opencli_expansion_implemented": False,
        "platform_fetch_completed": False,
        "authenticated_browser_runtime_integrated": False,
        "video_transcription_implemented": False,
        "visual_ocr_runtime_integrated": False,
        "knowledge_verification_runtime_implemented": False,
        "ui_workflow_accepted": False,
        "bridge_execution_accepted": False,
        "campaign_3_3_0_accepted": False,
        "campaign_3_4_0_active": False,
        "campaign_3_accepted": False,
        "campaign_4_allowed": False,
        "full_gate_passed": False,
        "exe_packaging_done": False,
    }


def _safety_boundary() -> dict[str, bool]:
    return {
        "user_supplied_only": True,
        "user_triggered_only": True,
        "metadata_only_for_local_files": True,
        "no_login_bypass": True,
        "no_paywall_bypass": True,
        "no_captcha_bypass": True,
        "no_platform_control_bypass": True,
        "no_cookie_import": True,
        "no_plaintext_cookie_persistence": True,
        "no_cookie_upload": True,
        "no_browser_session_used": True,
        "no_anti_detection_behavior": True,
        "no_unlimited_crawler": True,
        "no_high_frequency_platform_collection": True,
        "no_external_upload": True,
        "no_arbitrary_shell_execution": True,
        "secret_guard_enabled": True,
    }


def _write_outputs(
    output: Path,
    manifest: dict[str, Any],
    blocks: list[dict[str, Any]],
    source_trace: dict[str, Any],
    evidence_map: dict[str, Any],
    validation: dict[str, Any],
) -> None:
    write_json(output / "manual_evidence_manifest.json", manifest)
    write_jsonl(output / "manual_evidence_blocks.jsonl", blocks)
    write_json(output / "manual_source_trace.json", source_trace)
    write_json(output / "manual_evidence_map.json", evidence_map)
    write_json(output / "manual_evidence_validation_report.json", validation)
    (output / "manual_evidence_report.md").write_text(_render_manual_report(manifest, validation), encoding="utf-8")
    write_json(output / "run_manifest.json", _run_manifest(manifest))
    (output / "run_summary.md").write_text(_render_summary(manifest, validation), encoding="utf-8")


def _run_manifest(manifest: dict[str, Any]) -> dict[str, Any]:
    passed = manifest["status"] in {"passed", "partial"}
    return {
        "schema_version": "audit_run_manifest.v1",
        "run_id": "external_source_manual_evidence",
        "generated_at": manifest["created_at"],
        "type": "section_5_supplement_3_0_p0_manual_evidence_upload",
        "scope": "CAMPAIGN_3_SUPPLEMENT_3_0_P0_MANUAL_EVIDENCE_UPLOAD",
        "status": manifest["status"],
        "integration_decision": manifest["integration_decision"],
        "decision_qualifier": manifest["decision_qualifier"],
        "evidence_files": MANUAL_EVIDENCE_FILES,
        "campaign_state_after_run": {
            "campaign_3_supplement_3_0_entry_gate_passed": True,
            "campaign_3_3_0_p0_framework_passed": True,
            "generic_web_url_ingestion_implemented": True,
            "platform_preflight_implemented": True,
            "opencli_external_search_verification_implemented": True,
            "manual_evidence_upload_passed": passed,
            "authenticated_browser_runtime_integrated": False,
            "video_transcription_implemented": False,
            "visual_ocr_runtime_integrated": False,
            "knowledge_verification_runtime_implemented": False,
            "campaign_3_3_0_accepted": False,
            "campaign_3_4_0_active": False,
            "campaign_3_accepted": False,
            "campaign_4_allowed": False,
            "next_business_item": (
                "Campaign 3 Supplement 3.0 P0 unified Source Trace / Evidence Map, progress events, and failure isolation"
                if passed
                else "Retry Campaign 3 Supplement 3.0 P0 Manual Evidence Upload"
            ),
        },
        "retention": "milestone",
        "keep_in_git": True,
        "final_target_not_downgraded": True,
        "remaining_gap": manifest["remaining_gap"],
        "next_required_e2e_step": manifest["next_required_e2e_step"],
        "not_goal_complete": True,
    }


def _render_manual_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    return (
        "# Manual Evidence Report\n\n"
        f"- Status: `{manifest['status']}`\n"
        f"- Decision: `{manifest['integration_decision']} / {manifest['decision_qualifier']}`\n"
        f"- Accepted: `{manifest['accepted_count']}`\n"
        f"- Failed: `{manifest['failed_count']}`\n"
        f"- Blocks: `{manifest['block_count']}`\n"
        f"- Validation: `{validation['status']}` with `{len(validation['boundary_errors'])}` boundary errors\n"
        "- Boundary: manual evidence is user supplied; it is not OCR completion, browser reading, "
        "OpenCLI expansion, platform fetching, video transcription, UI acceptance, or Core Bridge acceptance.\n"
    )


def _render_summary(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    return (
        "# Manual Evidence Upload Summary\n\n"
        f"Status: `{manifest['status']}`. "
        f"Decision: `{manifest['integration_decision']} / {manifest['decision_qualifier']}`. "
        f"Sources: `{manifest['source_count']}`. Blocks: `{manifest['block_count']}`. "
        f"Boundary errors: `{len(validation['boundary_errors'])}`. "
        f"Next required E2E step: `{manifest['next_required_e2e_step']}`\n"
    )


def _validation_failure(error_code: str, *, missing_files: list[str]) -> dict[str, Any]:
    return {
        "schema_version": "manual_evidence_validation_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "status": "failed",
        "boundary_errors": [error_code],
        "source_count": 0,
        "accepted_count": 0,
        "failed_count": 0,
        "block_count": 0,
        "missing_files": missing_files,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": "Manual Evidence Upload evidence is incomplete.",
        "next_required_e2e_step": "Complete Campaign 3 Supplement 3.0 P0 Manual Evidence Upload before advancing.",
        "not_goal_complete": True,
    }


def _validate_record(record: dict[str, Any], errors: list[str]) -> None:
    for field in [
        "evidence_id",
        "source_type",
        "manual_input_type",
        "title",
        "user_provided_source_url",
        "user_note",
        "content_hash",
        "created_at",
        "text",
        "metadata",
        "trace",
        "status",
    ]:
        if field not in record:
            errors.append(f"record_{field}_required")
    if record.get("manual_input_type") not in ACCEPTED_MANUAL_INPUT_TYPES:
        errors.append(f"record_manual_input_type_invalid:{record.get('manual_input_type')}")
    if record.get("status") not in MANUAL_STATUS_VALUES:
        errors.append(f"record_status_invalid:{record.get('status')}")
    if record.get("status") == STATUS_ACCEPTED and not (record.get("text") or record.get("metadata", {}).get("metadata_only")):
        errors.append("accepted_record_requires_text_or_metadata")
    if record.get("status") != STATUS_ACCEPTED and not record.get("failure_reason"):
        errors.append("failed_record_requires_failure_reason")
    joined = " ".join(
        str(record.get(key, ""))
        for key in ["title", "user_provided_source_url", "user_note", "text", "content_hash"]
    )
    if _detect_secret(joined):
        errors.append("record_must_not_persist_secret_like_text")


def _validate_block(block: dict[str, Any], errors: list[str]) -> None:
    for field in [
        "chunk_id",
        "chunk_type",
        "evidence_id",
        "source_type",
        "manual_input_type",
        "content_hash",
        "backlink",
        "status",
        "trace",
    ]:
        if field not in block:
            errors.append(f"block_{field}_required")
    if block.get("chunk_type") not in {"text", "layout_block"}:
        errors.append(f"invalid_chunk_type:{block.get('chunk_type')}")
    if not str(block.get("backlink", "")).startswith("manual_evidence_manifest.json#"):
        errors.append("block_backlink_must_target_manual_manifest")
    if block.get("ocr_text") or block.get("visual_summary") or block.get("timestamp_start") or block.get("timestamp_end"):
        errors.append("manual_block_must_not_claim_ocr_or_video_outputs")
    if block.get("status") == STATUS_ACCEPTED and block.get("chunk_type") == "text" and not block.get("text"):
        errors.append("accepted_text_block_requires_text")


def _manual_type_for_file(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix in {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif", ".tif", ".tiff"}:
        return "screenshot_metadata"
    if suffix in {".srt", ".vtt"}:
        return "subtitle_metadata"
    if suffix in {".html", ".htm"}:
        return "exported_html_metadata"
    if suffix in {".md", ".markdown", ".txt"}:
        return "user_note"
    return "unsupported_manual_type"


def _file_metadata(path: Path) -> dict[str, Any]:
    return {
        "file_name": path.name,
        "file_extension": path.suffix.lower(),
        "exists_at_import": None,
        "size_bytes": None,
        "modified_at_epoch": None,
        "path_hash": _sha256(str(path)),
        "path_not_persisted": True,
        "file_system_metadata_read": False,
        "file_content_read": False,
        "ocr_completed": False,
        "video_transcription_completed": False,
        "browser_read_completed": False,
        "opencli_fetch_completed": False,
        "platform_fetch_completed": False,
    }


def _trace(*, evidence_id: str, source_url: str | None, created_at: str, status: str) -> dict[str, Any]:
    return {
        "trace_id": _stable_id("manual_trace", evidence_id),
        "trace_type": "manual_evidence",
        "source_origin": "user_supplied_manual_material",
        "user_provided_source_url": source_url or "",
        "created_at": created_at,
        "status": status,
        "manual_evidence_not_public_fetch": True,
        "manual_evidence_not_ocr_completion": True,
        "manual_evidence_not_browser_read": True,
        "manual_evidence_not_opencli_result": True,
        "manual_evidence_not_video_transcription": True,
    }


def _normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def _sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _stable_id(prefix: str, value: str) -> str:
    return f"{prefix}_{hashlib.sha256(value.encode('utf-8')).hexdigest()[:16]}"


def _detect_secret(text: str) -> bool:
    return any(pattern.search(text) for pattern in SECRET_PATTERNS)


def _redact_if_secret(text: str) -> str:
    return "[redacted: suspected sensitive secret]" if _detect_secret(text) else text


def _now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _read_json(path: Path) -> dict[str, Any]:
    return __import__("json").loads(path.read_text(encoding="utf-8-sig"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    import json

    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
