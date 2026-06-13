from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit
from uuid import uuid4

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


AUTHENTICATED_BROWSER_FILES = [
    "browser_session.json",
    "user_consent_record.json",
    "visible_content_extract.jsonl",
    "auth_source_trace.json",
    "authenticated_source_evidence_map.json",
    "progress_events.jsonl",
    "authenticated_browser_validation_report.json",
    "authenticated_browser_report.md",
    "run_manifest.json",
    "run_summary.md",
]

_REQUIRED_RUNTIME_FILES = [
    "browser_session.json",
    "user_consent_record.json",
    "visible_content_extract.jsonl",
    "auth_source_trace.json",
    "authenticated_source_evidence_map.json",
    "progress_events.jsonl",
]

AUTHENTICATED_BROWSER_STATES = {
    "auth_required",
    "user_authorized_session",
    "visible_content_readable",
    "visible_content_partial",
    "user_cancelled",
    "session_expired",
    "permission_denied",
    "manual_evidence_required",
}

_SENSITIVE_PATTERNS = [
    re.compile(
        r"(?i)\b(api[_-]?key|access[_-]?token|refresh[_-]?token|auth[_-]?token|"
        r"authorization|password|secret|session[_-]?id|cookie)\b\s*[:=]\s*\S+"
    ),
    re.compile(r"(?i)\b(bearer|basic)\s+[A-Za-z0-9._~+/=-]{16,}"),
    re.compile(r"\bsk-[A-Za-z0-9_-]{16,}\b"),
]

_FORBIDDEN_PERSISTED_KEYS = {
    "cookie",
    "cookies",
    "cookie_header",
    "authorization",
    "password",
    "secret",
    "access_token",
    "refresh_token",
    "session_cookie",
}


def start_authenticated_browser_session(
    output: Path,
    *,
    source_url: str,
    title: str,
    user_consent: bool,
    ttl_seconds: int = 1800,
    started_at: str | None = None,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    timestamp = started_at or _now()
    errors = _validate_start(source_url=source_url, title=title, ttl_seconds=ttl_seconds)
    consent_granted = user_consent and not errors
    status = "user_authorized_session" if consent_granted else "permission_denied"
    if errors:
        status = "auth_required"

    session = {
        "schema_version": "authenticated_browser_session.v1",
        "session_id": f"abs_{uuid4().hex}",
        "status": status,
        "source_url": source_url.strip(),
        "title": title.strip(),
        "started_at": timestamp,
        "expires_at": _add_seconds(timestamp, ttl_seconds),
        "ttl_seconds": ttl_seconds,
        "consent_granted": consent_granted,
        "paused": False,
        "revoked": False,
        "visible_content_read_count": 0,
        "last_read_at": None,
        "failure_reason": (
            "; ".join(errors)
            if errors
            else ("" if consent_granted else "The user did not authorize the visible-content session.")
        ),
        "repair_suggestion": (
            "Provide a public HTTP/HTTPS source URL, title, and positive user consent."
            if errors
            else (
                ""
                if consent_granted
                else "Ask the user to explicitly authorize a new local visible-content session."
            )
        ),
        "runtime_boundary": _runtime_boundary(),
        "safety_boundary": _safety_boundary(),
    }
    consent = _consent_record(session, consent_status="granted" if consent_granted else "denied")
    _write_session(output, session, consent)
    _append_progress(
        output,
        stage="authenticated_browser_session_start",
        status="passed" if consent_granted else "blocked",
        message=(
            "User-authorized visible-content session started."
            if consent_granted
            else session["failure_reason"]
        ),
        artifact_path="browser_session.json",
    )
    _refresh_reports(output)
    return session


def read_visible_browser_source(
    output: Path,
    *,
    visible_text: str,
    source_url: str | None = None,
    title: str | None = None,
    partial: bool = False,
    captured_at: str | None = None,
) -> dict[str, Any]:
    output = Path(output)
    session = _load_session(output)
    timestamp = captured_at or _now()
    state_error = _session_read_error(session, timestamp)
    normalized_text = _normalize_text(visible_text)
    secret_detected = _contains_sensitive_material(visible_text)

    if state_error:
        result = _failure_result(session, status=state_error[0], reason=state_error[1], timestamp=timestamp)
    elif secret_detected:
        result = _failure_result(
            session,
            status="permission_denied",
            reason="Visible content contains suspected cookie, token, password, or secret material.",
            timestamp=timestamp,
        )
    elif not normalized_text:
        result = _failure_result(
            session,
            status="manual_evidence_required",
            reason="No visible page content was supplied by the user-authorized connector.",
            timestamp=timestamp,
        )
    else:
        effective_url = (source_url or session["source_url"]).strip()
        effective_title = (title or session["title"]).strip()
        validation_errors = _validate_visible_source(effective_url, effective_title)
        if validation_errors:
            result = _failure_result(
                session,
                status="permission_denied",
                reason="; ".join(validation_errors),
                timestamp=timestamp,
            )
        else:
            result = _accepted_result(
                session,
                visible_text=normalized_text,
                source_url=effective_url,
                title=effective_title,
                partial=partial,
                captured_at=timestamp,
            )

    if result["status"] in {"visible_content_readable", "visible_content_partial"}:
        rows = _load_jsonl(output / "visible_content_extract.jsonl")
        rows.append(result["content_block"])
        write_jsonl(output / "visible_content_extract.jsonl", rows)
        session["visible_content_read_count"] += 1
        session["last_read_at"] = timestamp
        session["status"] = result["status"]
        session["failure_reason"] = ""
        session["repair_suggestion"] = ""
        write_json(output / "browser_session.json", session)
    else:
        session["status"] = result["status"]
        session["failure_reason"] = result["failure_reason"]
        session["repair_suggestion"] = result["repair_suggestion"]
        write_json(output / "browser_session.json", session)

    _append_progress(
        output,
        stage="authenticated_browser_visible_content_read",
        status=(
            "partial"
            if result["status"] == "visible_content_partial"
            else "passed"
            if result["status"] == "visible_content_readable"
            else "blocked"
        ),
        message=result["message"],
        artifact_path="visible_content_extract.jsonl",
    )
    _refresh_reports(output)
    return result


def pause_authenticated_browser_session(
    output: Path, *, paused_at: str | None = None
) -> dict[str, Any]:
    output = Path(output)
    session = _load_session(output)
    session["paused"] = True
    session["paused_at"] = paused_at or _now()
    session["status"] = "user_authorized_session"
    write_json(output / "browser_session.json", session)
    _append_progress(
        output,
        stage="authenticated_browser_session_pause",
        status="passed",
        message="Authorized visible-content session paused by the user.",
        artifact_path="browser_session.json",
    )
    _refresh_reports(output)
    return session


def resume_authenticated_browser_session(
    output: Path, *, resumed_at: str | None = None
) -> dict[str, Any]:
    output = Path(output)
    session = _load_session(output)
    timestamp = resumed_at or _now()
    if session.get("revoked"):
        return _failure_result(
            session,
            status="user_cancelled",
            reason="The authorized session was revoked and cannot be resumed.",
            timestamp=timestamp,
        )
    if _is_expired(session, timestamp):
        session["status"] = "session_expired"
        session["failure_reason"] = "The authorized visible-content session expired."
        session["repair_suggestion"] = "Start a new user-authorized session."
    else:
        session["paused"] = False
        session["resumed_at"] = timestamp
        session["status"] = "user_authorized_session"
        session["failure_reason"] = ""
        session["repair_suggestion"] = ""
    write_json(output / "browser_session.json", session)
    _append_progress(
        output,
        stage="authenticated_browser_session_resume",
        status="passed" if session["status"] == "user_authorized_session" else "blocked",
        message=(
            "Authorized visible-content session resumed."
            if session["status"] == "user_authorized_session"
            else session["failure_reason"]
        ),
        artifact_path="browser_session.json",
    )
    _refresh_reports(output)
    return session


def clear_authenticated_browser_session(
    output: Path, *, cleared_at: str | None = None
) -> dict[str, Any]:
    output = Path(output)
    session = _load_session(output)
    timestamp = cleared_at or _now()
    session.update(
        {
            "status": "user_cancelled",
            "consent_granted": False,
            "paused": False,
            "revoked": True,
            "revoked_at": timestamp,
            "failure_reason": "The user revoked and cleared the authorized browser session.",
            "repair_suggestion": "Start a new session only after fresh explicit user consent.",
        }
    )
    consent = _consent_record(session, consent_status="revoked")
    _write_session(output, session, consent)
    _append_progress(
        output,
        stage="authenticated_browser_session_clear",
        status="passed",
        message="Authorized browser session revoked and cleared without retaining cookie material.",
        artifact_path="user_consent_record.json",
    )
    _refresh_reports(output)
    return session


def validate_authenticated_browser_session(output: Path) -> dict[str, Any]:
    output = Path(output)
    missing = [name for name in _REQUIRED_RUNTIME_FILES if not (output / name).exists()]
    errors: list[str] = []
    session = _read_json(output / "browser_session.json")
    consent = _read_json(output / "user_consent_record.json")
    trace = _read_json(output / "auth_source_trace.json")
    evidence = _read_json(output / "authenticated_source_evidence_map.json")
    rows = _load_jsonl(output / "visible_content_extract.jsonl")

    if missing:
        errors.extend(f"missing_file:{name}" for name in missing)
    if not rows:
        errors.append("visible_content_evidence_required")
    if session and session.get("status") not in AUTHENTICATED_BROWSER_STATES:
        errors.append("invalid_session_status")
    if session and session.get("runtime_boundary") != _runtime_boundary():
        errors.append("runtime_boundary_mismatch")
    if session and session.get("safety_boundary") != _safety_boundary():
        errors.append("safety_boundary_mismatch")
    if consent and consent.get("cookie_material_collected") is not False:
        errors.append("cookie_material_collected_must_be_false")
    if consent and consent.get("plaintext_credentials_persisted") is not False:
        errors.append("plaintext_credentials_persisted_must_be_false")
    for label, payload in [
        ("session", session),
        ("consent", consent),
        ("trace", trace),
        ("evidence", evidence),
        ("visible_content", rows),
    ]:
        forbidden = sorted(_find_forbidden_keys(payload))
        if forbidden:
            errors.append(f"{label}_forbidden_sensitive_keys:{','.join(forbidden)}")
    if any(_contains_sensitive_material(row.get("text", "")) for row in rows):
        errors.append("visible_content_contains_sensitive_material")
    if trace and trace.get("browser_automation_integrated") is not False:
        errors.append("browser_automation_integrated_must_be_false")
    if trace and trace.get("cookie_accessed") is not False:
        errors.append("cookie_accessed_must_be_false")
    if evidence and evidence.get("knowledge_verification_engine_complete") is not False:
        errors.append("knowledge_verification_engine_complete_must_be_false")

    return {
        "schema_version": "authenticated_browser_validation_report.v1",
        "status": "passed" if not errors else "failed",
        "boundary_errors": errors,
        "missing_files": missing,
        "session_state": session.get("status") if session else "missing",
        "visible_content_count": len(rows),
        "authenticated_browser_connector_alpha_complete": not errors,
        "browser_automation_integrated": False,
        "cookie_import_supported": False,
        "cookie_material_persisted": False,
        "login_bypass_attempted": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "local_core_bridge_complete": False,
        "bridge_execution_accepted": False,
        "supplement_3_0_complete": False,
        "not_goal_complete": True,
    }


def write_authenticated_browser_validation(
    library: Path, output: Path
) -> dict[str, Any]:
    validation = validate_authenticated_browser_session(library)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    write_json(output / "authenticated_browser_validation_report.json", validation)
    return validation


def _refresh_reports(output: Path) -> None:
    session = _load_session(output)
    rows = _load_jsonl(output / "visible_content_extract.jsonl")
    trace_rows = [
        {
            "source_id": row["source_id"],
            "evidence_id": row["evidence_id"],
            "source_url": row["source_url"],
            "title": row["title"],
            "captured_at": row["captured_at"],
            "content_hash": row["content_hash"],
            "backlink": row["backlink"],
            "integration_mode": "user_authorized_visible_content",
            "visible_content_only": True,
        }
        for row in rows
    ]
    trace = {
        "schema_version": "auth_source_trace.v1",
        "session_id": session["session_id"],
        "source_count": len(trace_rows),
        "sources": trace_rows,
        "user_authorized_visible_content_only": True,
        "browser_automation_integrated": False,
        "cookie_accessed": False,
        "login_bypass_attempted": False,
    }
    evidence = {
        "schema_version": "authenticated_source_evidence_map.v1",
        "session_id": session["session_id"],
        "evidence_count": len(rows),
        "evidence": [
            {
                "source_id": row["source_id"],
                "evidence_id": row["evidence_id"],
                "content_hash": row["content_hash"],
                "source_type": row["source_type"],
                "integration_mode": row["integration_mode"],
                "trace_ref": "auth_source_trace.json",
                "content_ref": f"visible_content_extract.jsonl#{index + 1}",
                "backlink": row["backlink"],
            }
            for index, row in enumerate(rows)
        ],
        "knowledge_verification_engine_complete": False,
    }
    write_json(output / "auth_source_trace.json", trace)
    write_json(output / "authenticated_source_evidence_map.json", evidence)
    validation = validate_authenticated_browser_session(output)
    write_json(output / "authenticated_browser_validation_report.json", validation)
    (output / "authenticated_browser_report.md").write_text(
        _render_report(session, rows, validation), encoding="utf-8"
    )
    manifest = {
        "schema_version": "audit_run_manifest.v1",
        "run_id": "external_source_authenticated_browser_connector",
        "generated_at": _now(),
        "type": "section_5_supplement_3_0_p1_authenticated_browser_connector_alpha",
        "scope": "CAMPAIGN_3_SUPPLEMENT_3_0_P1_AUTHENTICATED_BROWSER_CONNECTOR_ALPHA",
        "status": validation["status"],
        "integration_decision": "real_integration",
        "decision_qualifier": "authenticated_browser_visible_content_connector_alpha",
        "evidence_files": AUTHENTICATED_BROWSER_FILES,
        "session_state": session["status"],
        "visible_content_count": len(rows),
        "campaign_4_active": False,
        "campaign_5_active": False,
        "local_core_bridge_complete": False,
        "bridge_execution_accepted": False,
        "supplement_3_0_complete": False,
        "next_business_item": (
            "Campaign 3 Supplement 3.0 P1 Video-to-Knowledge and Visual Evidence Understanding foundations"
        ),
        "not_goal_complete": True,
    }
    write_json(output / "run_manifest.json", manifest)
    (output / "run_summary.md").write_text(_render_summary(manifest), encoding="utf-8")


def _write_session(output: Path, session: dict[str, Any], consent: dict[str, Any]) -> None:
    write_json(output / "browser_session.json", session)
    write_json(output / "user_consent_record.json", consent)
    if not (output / "visible_content_extract.jsonl").exists():
        write_jsonl(output / "visible_content_extract.jsonl", [])
    if not (output / "progress_events.jsonl").exists():
        write_jsonl(output / "progress_events.jsonl", [])


def _accepted_result(
    session: dict[str, Any],
    *,
    visible_text: str,
    source_url: str,
    title: str,
    partial: bool,
    captured_at: str,
) -> dict[str, Any]:
    content_hash = hashlib.sha256(visible_text.encode("utf-8")).hexdigest()
    source_id = f"source_{hashlib.sha256(source_url.encode('utf-8')).hexdigest()[:16]}"
    evidence_id = f"evidence_{content_hash[:16]}"
    status = "visible_content_partial" if partial else "visible_content_readable"
    block = {
        "chunk_id": f"chunk_{content_hash[:16]}",
        "chunk_type": "text",
        "source_id": source_id,
        "evidence_id": evidence_id,
        "source_type": "authenticated_browser_visible_content",
        "integration_mode": "user_authorized_visible_content",
        "source_url": source_url,
        "platform": urlsplit(source_url).hostname or "",
        "title": title,
        "author": "",
        "published_at": "",
        "retrieved_at": captured_at,
        "captured_at": captured_at,
        "content_hash": content_hash,
        "text": visible_text,
        "ocr_text": "",
        "visual_summary": "",
        "timestamp_start": "",
        "timestamp_end": "",
        "image_index": "",
        "bbox": "",
        "backlink": source_url,
        "confidence": 0.85 if partial else 1.0,
        "visibility_scope": "current_user_visible_content_only",
        "session_id": session["session_id"],
        "status": status,
    }
    return {
        "status": status,
        "message": (
            "Partial user-visible content captured with source trace."
            if partial
            else "User-visible content captured with source trace."
        ),
        "failure_reason": "",
        "repair_suggestion": "",
        "content_block": block,
    }


def _failure_result(
    session: dict[str, Any], *, status: str, reason: str, timestamp: str
) -> dict[str, Any]:
    suggestion = {
        "auth_required": "Start a session with explicit user consent.",
        "permission_denied": "Remove sensitive material or grant permission through a new session.",
        "session_expired": "Start a new user-authorized session.",
        "user_cancelled": "Start a new session only after fresh explicit user consent.",
        "manual_evidence_required": "Paste or upload the visible material through Manual Evidence Upload.",
    }.get(status, "Review the session state and retry.")
    return {
        "status": status,
        "message": reason,
        "failure_reason": reason,
        "repair_suggestion": suggestion,
        "captured_at": timestamp,
        "session_id": session.get("session_id", ""),
    }


def _session_read_error(
    session: dict[str, Any], timestamp: str
) -> tuple[str, str] | None:
    if not session.get("consent_granted"):
        return "permission_denied", "The session has no active explicit user consent."
    if session.get("revoked"):
        return "user_cancelled", "The user revoked the authorized browser session."
    if session.get("paused"):
        return "permission_denied", "The user paused the authorized browser session."
    if _is_expired(session, timestamp):
        return "session_expired", "The authorized visible-content session expired."
    return None


def _validate_start(*, source_url: str, title: str, ttl_seconds: int) -> list[str]:
    errors = _validate_visible_source(source_url, title)
    if ttl_seconds < 1 or ttl_seconds > 86400:
        errors.append("Session TTL must be between 1 and 86400 seconds.")
    return errors


def _validate_visible_source(source_url: str, title: str) -> list[str]:
    errors: list[str] = []
    parsed = urlsplit(source_url.strip())
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        errors.append("Source URL must be a public HTTP/HTTPS URL.")
    if parsed.username or parsed.password:
        errors.append("Source URL credentials are forbidden.")
    if not title.strip():
        errors.append("A visible page title is required.")
    return errors


def _consent_record(session: dict[str, Any], *, consent_status: str) -> dict[str, Any]:
    return {
        "schema_version": "user_consent_record.v1",
        "session_id": session["session_id"],
        "consent_status": consent_status,
        "consent_granted": consent_status == "granted",
        "consent_scope": "read_current_visible_page_content_only",
        "source_url": session["source_url"],
        "title": session["title"],
        "recorded_at": session.get("revoked_at") or session["started_at"],
        "revocable": True,
        "cookie_material_collected": False,
        "plaintext_credentials_persisted": False,
        "login_automation_used": False,
        "captcha_bypass_used": False,
        "paywall_bypass_used": False,
        "platform_control_bypass_used": False,
    }


def _runtime_boundary() -> dict[str, bool]:
    return {
        "authenticated_browser_connector_alpha_implemented": True,
        "user_consent_session_lifecycle_implemented": True,
        "visible_content_snapshot_ingestion_implemented": True,
        "pause_resume_revoke_implemented": True,
        "browser_automation_integrated": False,
        "cookie_import_integrated": False,
        "platform_crawler_integrated": False,
        "video_transcription_implemented": False,
        "visual_ocr_runtime_integrated": False,
        "knowledge_verification_runtime_implemented": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "local_core_bridge_complete": False,
        "bridge_execution_accepted": False,
        "supplement_3_0_complete": False,
    }


def _safety_boundary() -> dict[str, bool]:
    return {
        "user_triggered_only": True,
        "current_visible_content_only": True,
        "no_cookie_import": True,
        "no_plaintext_cookie_persistence": True,
        "no_cookie_upload": True,
        "no_login_bypass": True,
        "no_captcha_bypass": True,
        "no_paywall_bypass": True,
        "no_platform_control_bypass": True,
        "no_anti_detection_behavior": True,
        "no_high_frequency_collection": True,
        "no_arbitrary_shell_execution": True,
    }


def _append_progress(
    output: Path, *, stage: str, status: str, message: str, artifact_path: str
) -> None:
    path = output / "progress_events.jsonl"
    rows = _load_jsonl(path)
    rows.append(
        {
            "event_id": f"evt_{uuid4().hex[:12]}",
            "stage": stage,
            "status": status,
            "timestamp": _now(),
            "message": message,
            "artifact_path": artifact_path,
        }
    )
    write_jsonl(path, rows)


def _load_session(output: Path) -> dict[str, Any]:
    path = output / "browser_session.json"
    if not path.exists():
        raise ValueError("Authenticated browser session does not exist.")
    return json.loads(path.read_text(encoding="utf-8"))


def _read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _load_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def _find_forbidden_keys(value: Any, prefix: str = "") -> set[str]:
    found: set[str] = set()
    if isinstance(value, dict):
        for key, child in value.items():
            lowered = str(key).lower()
            path = f"{prefix}.{key}" if prefix else str(key)
            if lowered in _FORBIDDEN_PERSISTED_KEYS:
                found.add(path)
            found.update(_find_forbidden_keys(child, path))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            found.update(_find_forbidden_keys(child, f"{prefix}[{index}]"))
    return found


def _contains_sensitive_material(value: str) -> bool:
    return any(pattern.search(value or "") for pattern in _SENSITIVE_PATTERNS)


def _normalize_text(value: str) -> str:
    return " ".join((value or "").split())


def _is_expired(session: dict[str, Any], timestamp: str) -> bool:
    return _parse_time(timestamp) >= _parse_time(session["expires_at"])


def _add_seconds(timestamp: str, seconds: int) -> str:
    return (_parse_time(timestamp) + timedelta(seconds=seconds)).isoformat()


def _parse_time(value: str) -> datetime:
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _render_report(
    session: dict[str, Any], rows: list[dict[str, Any]], validation: dict[str, Any]
) -> str:
    failures = "\n".join(f"- {item}" for item in validation["boundary_errors"]) or "- None"
    return (
        "# Authenticated Browser Connector Alpha Report\n\n"
        f"- Status: `{validation['status']}`\n"
        f"- Session state: `{session['status']}`\n"
        f"- Visible-content records: `{len(rows)}`\n"
        "- Integration: user-authorized local visible-content snapshot connector only.\n"
        "- Browser automation: `false`\n"
        "- Cookie import/save/upload: `false`\n"
        "- Campaign 4 active: `false`\n"
        "- Campaign 5 active: `false`\n"
        "- Supplement 3.0 complete: `false`\n\n"
        "## Validation Errors\n\n"
        f"{failures}\n"
    )


def _render_summary(manifest: dict[str, Any]) -> str:
    return (
        "# Authenticated Browser Connector Alpha Summary\n\n"
        f"- Status: `{manifest['status']}`\n"
        f"- Decision: `{manifest['integration_decision']} / {manifest['decision_qualifier']}`\n"
        f"- Visible-content records: `{manifest['visible_content_count']}`\n"
        "- This is a Campaign 3 Supplement 3.0 internal connector, not Campaign 4 UI acceptance "
        "and not Campaign 5 Local Core Bridge acceptance.\n"
    )
