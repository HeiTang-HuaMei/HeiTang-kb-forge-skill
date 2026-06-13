from __future__ import annotations

import hashlib
import json
import re
import socket
from dataclasses import dataclass
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from typing import Any
from urllib import error, parse, request, robotparser

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


GENERIC_WEB_URL_FILES = [
    "external_source_inventory.json",
    "external_source_preflight.json",
    "link_ingestion_report.json",
    "link_ingestion_report.md",
    "external_fetch_report.json",
    "external_fetch_report.md",
    "external_source_trace.json",
    "external_evidence_map.json",
    "external_change_detection_report.json",
    "external_chunks.jsonl",
    "external_metadata.json",
    "generic_web_url_ingestion_validation_report.json",
    "run_manifest.json",
    "run_summary.md",
]

USER_AGENT = "HeiTang-KB-Forge/0.1 (user-triggered external source ingestion)"
MAX_FETCH_BYTES = 2 * 1024 * 1024
PROGRESS_EVENTS_FILE = "progress_events.jsonl"


@dataclass(frozen=True)
class FetchResult:
    status_code: int
    final_url: str
    content_type: str
    body: bytes


def ingest_generic_web_url(
    output: Path,
    *,
    url: str,
    timeout_seconds: int = 30,
    respect_robots: bool = True,
    retrieved_at: str | None = None,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    progress_path = output / PROGRESS_EVENTS_FILE
    progress_path.write_text("", encoding="utf-8")
    retrieved_at = retrieved_at or _now()
    _append_progress(
        progress_path,
        stage="url_preflight",
        status="running",
        message="Validating the user-provided public HTTP/HTML URL.",
        artifact_path="external_source_preflight.json",
    )
    preflight = _preflight(url, timeout_seconds=timeout_seconds, respect_robots=respect_robots)
    if preflight["status"] != "passed":
        result = _failure_manifest(
            url=url,
            retrieved_at=retrieved_at,
            preflight=preflight,
            error_code=preflight["error_code"],
            error_message=preflight["failure_reason"],
        )
        _write_failure(output, result, preflight)
        _append_terminal_progress(progress_path, result)
        return result

    _append_progress(
        progress_path,
        stage="url_preflight",
        status="passed",
        message="URL preflight passed.",
        artifact_path="external_source_preflight.json",
    )
    robots = _check_robots(url, respect_robots=respect_robots, timeout_seconds=timeout_seconds)
    preflight["robots"] = robots
    if robots["status"] == "disallowed":
        result = _failure_manifest(
            url=url,
            retrieved_at=retrieved_at,
            preflight=preflight,
            error_code="robots_disallowed",
            error_message="robots.txt disallows fetching this URL",
            status="skipped",
            readability_state="blocked_by_platform",
        )
        _write_failure(output, result, preflight)
        _append_terminal_progress(progress_path, result)
        return result

    _append_progress(
        progress_path,
        stage="public_html_fetch",
        status="running",
        message="Fetching the public source without login, cookie, or shell execution.",
        artifact_path="external_fetch_report.json",
    )
    try:
        fetch = _fetch(url, timeout_seconds=timeout_seconds)
    except Exception as exc:  # pragma: no cover - exact stdlib exception varies by platform
        result = _failure_manifest(
            url=url,
            retrieved_at=retrieved_at,
            preflight=preflight,
            error_code=_fetch_error_code(exc),
            error_message=str(exc),
            status="failed",
            readability_state="needs_manual_evidence",
        )
        _write_failure(output, result, preflight)
        _append_terminal_progress(progress_path, result)
        return result

    _append_progress(
        progress_path,
        stage="public_html_fetch",
        status="passed",
        message=f"Fetched HTTP {fetch.status_code} public content.",
        artifact_path="external_fetch_report.json",
    )
    preflight["public_readable"] = True
    preflight["readability_state"] = "public_readable"
    _append_progress(
        progress_path,
        stage="content_extraction",
        status="running",
        message="Extracting readable text and source metadata.",
        artifact_path="external_metadata.json",
    )
    parsed = _extract_html(fetch.body, fetch.content_type, fetch.final_url)
    if not parsed["text"]:
        result = _failure_manifest(
            url=url,
            retrieved_at=retrieved_at,
            preflight=preflight,
            error_code="empty_extracted_text",
            error_message="Fetched content did not produce readable text",
            status="failed",
            readability_state="partial_readable",
        )
        result["fetch_report"] = _fetch_report(url, fetch, parsed, retrieved_at)
        _write_failure(output, result, preflight)
        _append_terminal_progress(progress_path, result)
        return result

    _append_progress(
        progress_path,
        stage="content_extraction",
        status="passed",
        message="Readable text and metadata were extracted.",
        artifact_path="external_metadata.json",
    )
    canonical_url = parsed["canonical_url"] or fetch.final_url
    source_id = _stable_id("source", canonical_url)
    content_hash = _sha256(parsed["text"])
    chunk_id = _stable_id("chunk", f"{canonical_url}:{content_hash}:0")
    evidence_id = _stable_id("evidence", chunk_id)
    metadata = _metadata(url, canonical_url, fetch, parsed, content_hash, retrieved_at)
    chunk = _chunk(chunk_id, evidence_id, metadata, parsed["text"])
    inventory = _inventory(source_id, metadata)
    source_trace = _source_trace(source_id, metadata, fetch, content_hash)
    evidence_map = _evidence_map(source_id, chunk_id, evidence_id, metadata)
    fetch_report = _fetch_report(url, fetch, parsed, retrieved_at)
    change_report = {
        "schema_version": "external_change_detection_report.v1",
        "status": "not_compared",
        "content_hash": content_hash,
        "previous_content_hash": None,
        "content_hash_changed": None,
        "reason": "No previous external source snapshot was supplied.",
    }
    manifest = {
        "schema_version": "generic_web_url_ingestion_manifest.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "supplement": "3.0 External Source Memory & Verification",
        "step": "P0 Generic Web URL Ingestion",
        "status": "passed",
        "integration_decision": "real_integration",
        "decision_qualifier": "generic_web_url_ingestion_only",
        "integration_mode": "public_http_html_to_traceable_chunks",
        "source_url": url,
        "canonical_url": canonical_url,
        "runtime_boundary": _runtime_boundary(),
        "safety_boundary": {
            "user_triggered_only": True,
            "url_depth": 0,
            "max_pages": 1,
            "same_domain_only": True,
            "respect_robots": respect_robots,
            "no_login_bypass": True,
            "no_paywall_bypass": True,
            "no_captcha_bypass": True,
            "no_cookie_import": True,
            "no_arbitrary_shell_execution": True,
            "platform_preflight_required_for_platform_links": True,
        },
        "preflight_status": preflight["status"],
        "readability_state": preflight["readability_state"],
        "public_readable": True,
        "chunk_count": 1,
        "source_trace_count": 1,
        "evidence_count": 1,
        "content_hash": content_hash,
        "failure_reason": "",
        "repair_suggestion": "",
        "backlink": canonical_url,
        "source_trace_path": "external_source_trace.json",
        "evidence_map_path": "external_evidence_map.json",
        "progress_events_path": PROGRESS_EVENTS_FILE,
        "output_files": GENERIC_WEB_URL_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Generic public HTTP/HTML URL ingestion now produces traceable text chunks, metadata, "
            "source_trace, evidence_map, content_hash, and backlink. Platform Link Preflight, OpenCLI "
            "verification, manual evidence processing, authenticated browser reading, video/OCR runtime, "
            "UI workflow acceptance, Core Bridge execution acceptance, Supplement 3.0 acceptance, "
            "Supplement 4.0, Campaign 4, Full Gate, EXE, and release remain incomplete."
        ),
        "next_required_e2e_step": "Run Campaign 3 Supplement 3.0 P0 Platform Link Preflight only.",
        "not_goal_complete": True,
    }
    validation = validate_generic_web_url_payload(manifest, preflight, [chunk], source_trace, evidence_map)
    _write_success(
        output,
        manifest=manifest,
        preflight=preflight,
        inventory=inventory,
        metadata=metadata,
        chunk=chunk,
        source_trace=source_trace,
        evidence_map=evidence_map,
        fetch_report=fetch_report,
        change_report=change_report,
        validation=validation,
    )
    _append_progress(
        progress_path,
        stage="trace_and_evidence",
        status="passed",
        message="Source trace, evidence map, content hash, and backlink were written.",
        artifact_path="external_source_trace.json",
    )
    _append_progress(
        progress_path,
        stage="external_link_import",
        status="passed",
        message="External link import completed.",
        artifact_path="link_ingestion_report.json",
    )
    return manifest | {"validation": validation}


def validate_generic_web_url_ingestion(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [file_name for file_name in GENERIC_WEB_URL_FILES if not (library / file_name).exists()]
    if missing:
        return _validation_failure("required_files_missing", missing_files=missing)
    manifest = _read_json(library / "link_ingestion_report.json")
    preflight = _read_json(library / "external_source_preflight.json")
    chunks = _read_jsonl(library / "external_chunks.jsonl")
    source_trace = _read_json(library / "external_source_trace.json")
    evidence_map = _read_json(library / "external_evidence_map.json")
    result = validate_generic_web_url_payload(manifest, preflight, chunks, source_trace, evidence_map)
    return {**result, "required_files": GENERIC_WEB_URL_FILES, "missing_files": missing}


def write_generic_web_url_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_generic_web_url_ingestion(library)
    write_json(output / "generic_web_url_ingestion_validation_report.json", result)
    return result


def validate_generic_web_url_payload(
    manifest: dict[str, Any],
    preflight: dict[str, Any],
    chunks: list[dict[str, Any]],
    source_trace: dict[str, Any],
    evidence_map: dict[str, Any],
) -> dict[str, Any]:
    runtime = manifest.get("runtime_boundary", {})
    safety = manifest.get("safety_boundary", {})
    errors: list[str] = []
    if manifest.get("status") != "passed":
        errors.append("manifest_status_must_be_passed")
    if manifest.get("integration_decision") != "real_integration":
        errors.append("integration_decision_must_be_real_integration")
    if manifest.get("decision_qualifier") != "generic_web_url_ingestion_only":
        errors.append("decision_qualifier_must_be_generic_web_url_ingestion_only")
    if runtime.get("generic_web_url_ingestion_implemented") is not True:
        errors.append("generic_web_url_ingestion_implemented_must_be_true")
    for field in [
        "platform_preflight_implemented",
        "opencli_runtime_integrated",
        "manual_evidence_processing_implemented",
        "authenticated_browser_runtime_integrated",
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
    if preflight.get("public_readable") is not True:
        errors.append("public_readable_must_be_true")
    if preflight.get("readability_state") != "public_readable":
        errors.append("readability_state_must_be_public_readable")
    if not chunks:
        errors.append("chunks_must_be_non_empty")
    for chunk in chunks:
        if chunk.get("chunk_type") != "text":
            errors.append("chunk_type_must_be_text")
        if not chunk.get("text", "").strip():
            errors.append("chunk_text_must_be_non_empty")
        if not chunk.get("source_url"):
            errors.append("chunk_source_url_required")
        if not chunk.get("content_hash"):
            errors.append("chunk_content_hash_required")
        if not chunk.get("backlink"):
            errors.append("chunk_backlink_required")
    if source_trace.get("source_trace_required") is not True:
        errors.append("source_trace_required")
    if len(source_trace.get("sources", [])) != manifest.get("source_trace_count"):
        errors.append("source_trace_count_mismatch")
    if evidence_map.get("evidence_map_required") is not True:
        errors.append("evidence_map_required")
    if len(evidence_map.get("evidence", [])) != manifest.get("evidence_count"):
        errors.append("evidence_count_mismatch")
    for field in [
        "user_triggered_only",
        "respect_robots",
        "no_login_bypass",
        "no_paywall_bypass",
        "no_captcha_bypass",
        "no_cookie_import",
        "no_arbitrary_shell_execution",
    ]:
        if safety.get(field) is not True:
            errors.append(f"{field}_must_be_true")
    if safety.get("url_depth") != 0:
        errors.append("url_depth_must_be_zero")
    if safety.get("max_pages") != 1:
        errors.append("max_pages_must_be_one")
    if safety.get("same_domain_only") is not True:
        errors.append("same_domain_only_must_be_true")
    status = "passed" if not errors else "failed"
    return {
        "schema_version": "generic_web_url_ingestion_validation_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "status": status,
        "boundary_errors": errors,
        "chunk_count": len(chunks),
        "source_trace_count": len(source_trace.get("sources", [])),
        "evidence_count": len(evidence_map.get("evidence", [])),
        "generic_web_url_ingestion_implemented": runtime.get("generic_web_url_ingestion_implemented"),
        "platform_preflight_implemented": runtime.get("platform_preflight_implemented"),
        "opencli_runtime_integrated": runtime.get("opencli_runtime_integrated"),
        "ui_workflow_accepted": runtime.get("ui_workflow_accepted"),
        "bridge_execution_accepted": runtime.get("bridge_execution_accepted"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": manifest.get("remaining_gap", ""),
        "next_required_e2e_step": manifest.get("next_required_e2e_step", ""),
        "not_goal_complete": True,
    }


def _runtime_boundary() -> dict[str, bool]:
    return {
        "generic_web_url_ingestion_implemented": True,
        "url_preflight_implemented": True,
        "html_fetch_implemented": True,
        "html_text_extraction_implemented": True,
        "metadata_extraction_implemented": True,
        "chunking_implemented": True,
        "source_trace_implemented": True,
        "evidence_map_implemented": True,
        "content_hash_implemented": True,
        "backlink_implemented": True,
        "platform_preflight_implemented": False,
        "opencli_runtime_integrated": False,
        "manual_evidence_processing_implemented": False,
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


def _preflight(url: str, *, timeout_seconds: int, respect_robots: bool) -> dict[str, Any]:
    parsed = parse.urlparse(url)
    domain = parsed.netloc.lower()
    base = {
        "schema_version": "external_source_preflight.v1",
        "source_url": url,
        "source_type": "public_web_url",
        "platform": "generic_web",
        "domain": domain,
        "url_depth": 0,
        "max_pages": 1,
        "same_domain_only": True,
        "timeout_seconds": timeout_seconds,
        "respect_robots": respect_robots,
        "user_triggered_only": True,
        "public_readable": False,
        "platform_preflight_required": False,
    }
    if parsed.scheme not in {"http", "https"}:
        return base | {
            "status": "failed",
            "readability_state": "needs_manual_evidence",
            "error_code": "unsupported_url_scheme",
            "failure_reason": "Only http and https URLs are supported by Generic Web URL Ingestion.",
        }
    if parsed.username or parsed.password:
        return base | {
            "status": "failed",
            "readability_state": "auth_required",
            "error_code": "credentials_in_url_forbidden",
            "failure_reason": "Credentials in URLs are forbidden.",
        }
    if not parsed.netloc:
        return base | {
            "status": "failed",
            "readability_state": "needs_manual_evidence",
            "error_code": "missing_domain",
            "failure_reason": "URL must include a domain.",
        }
    return base | {
        "status": "passed",
        "readability_state": "unknown_until_fetch",
        "error_code": None,
        "failure_reason": None,
    }


def _check_robots(url: str, *, respect_robots: bool, timeout_seconds: int) -> dict[str, Any]:
    if not respect_robots:
        return {"status": "not_checked", "allowed": True, "reason": "respect_robots disabled"}
    parsed = parse.urlparse(url)
    robots_url = parse.urlunparse((parsed.scheme, parsed.netloc, "/robots.txt", "", "", ""))
    parser = robotparser.RobotFileParser()
    parser.set_url(robots_url)
    try:
        with _urlopen(robots_url, timeout=timeout_seconds) as response:
            body = response.read(MAX_FETCH_BYTES).decode("utf-8", errors="replace")
        parser.parse(body.splitlines())
    except Exception:
        return {"status": "unavailable_assumed_allowed", "allowed": True, "robots_url": robots_url}
    allowed = parser.can_fetch(USER_AGENT, url)
    return {
        "status": "allowed" if allowed else "disallowed",
        "allowed": allowed,
        "robots_url": robots_url,
    }


def _fetch(url: str, *, timeout_seconds: int) -> FetchResult:
    req = request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "text/html,text/plain;q=0.9,*/*;q=0.1"})
    with _urlopen(req, timeout=timeout_seconds) as response:
        body = response.read(MAX_FETCH_BYTES + 1)
        if len(body) > MAX_FETCH_BYTES:
            raise ValueError("response_exceeds_max_fetch_bytes")
        status = int(getattr(response, "status", 200))
        content_type = response.headers.get("Content-Type", "")
        final_url = response.geturl()
    if status >= 400:
        raise error.HTTPError(url, status, "HTTP error", hdrs=None, fp=None)
    return FetchResult(status_code=status, final_url=final_url, content_type=content_type, body=body)


def _urlopen(url_or_request: str | request.Request, *, timeout: int):
    url = url_or_request.full_url if isinstance(url_or_request, request.Request) else url_or_request
    hostname = parse.urlparse(url).hostname or ""
    if hostname in {"127.0.0.1", "localhost", "::1"}:
        opener = request.build_opener(request.ProxyHandler({}))
        return opener.open(url_or_request, timeout=timeout)
    return request.urlopen(url_or_request, timeout=timeout)


def _extract_html(body: bytes, content_type: str, url: str) -> dict[str, Any]:
    charset = "utf-8"
    match = re.search(r"charset=([\w.-]+)", content_type, flags=re.IGNORECASE)
    if match:
        charset = match.group(1)
    text = body.decode(charset, errors="replace")
    if "html" not in content_type.lower() and not re.search(r"<html|<body|<title", text, re.I):
        normalized = _normalize_text(text)
        return {
            "title": _fallback_title(url),
            "author": "",
            "published_at": "",
            "language": "",
            "canonical_url": url,
            "text": normalized,
            "extraction_method": "plain_text",
        }
    parser = _ReadableHtmlParser(base_url=url)
    parser.feed(text)
    return {
        "title": parser.title.strip() or _fallback_title(url),
        "author": parser.author.strip(),
        "published_at": parser.published_at.strip(),
        "language": parser.language.strip(),
        "canonical_url": parser.canonical_url.strip(),
        "text": _normalize_text(" ".join(parser.text_parts)),
        "extraction_method": "html_parser",
    }


class _ReadableHtmlParser(HTMLParser):
    def __init__(self, *, base_url: str) -> None:
        super().__init__(convert_charrefs=True)
        self.base_url = base_url
        self.text_parts: list[str] = []
        self.title_parts: list[str] = []
        self.title = ""
        self.author = ""
        self.published_at = ""
        self.language = ""
        self.canonical_url = ""
        self._ignored_depth = 0
        self._in_title = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr = {key.lower(): value or "" for key, value in attrs}
        if tag.lower() in {"script", "style", "noscript", "svg", "nav", "footer"}:
            self._ignored_depth += 1
        if tag.lower() == "title":
            self._in_title = True
        if tag.lower() == "html" and attr.get("lang"):
            self.language = attr["lang"]
        if tag.lower() == "meta":
            name = (attr.get("name") or attr.get("property") or "").lower()
            content = attr.get("content", "")
            if name in {"author", "article:author"} and content:
                self.author = content
            if name in {"article:published_time", "date", "pubdate", "publishdate"} and content:
                self.published_at = content
        if tag.lower() == "link" and attr.get("rel", "").lower() == "canonical" and attr.get("href"):
            self.canonical_url = parse.urljoin(self.base_url, attr["href"])

    def handle_endtag(self, tag: str) -> None:
        if tag.lower() in {"script", "style", "noscript", "svg", "nav", "footer"} and self._ignored_depth:
            self._ignored_depth -= 1
        if tag.lower() == "title":
            self._in_title = False
            self.title = _normalize_text(" ".join(self.title_parts))

    def handle_data(self, data: str) -> None:
        if self._ignored_depth:
            return
        if self._in_title:
            self.title_parts.append(data)
        else:
            self.text_parts.append(data)


def _metadata(
    source_url: str,
    canonical_url: str,
    fetch: FetchResult,
    parsed: dict[str, Any],
    content_hash: str,
    retrieved_at: str,
) -> dict[str, Any]:
    parsed_url = parse.urlparse(canonical_url)
    return {
        "schema_version": "external_source_metadata.v1",
        "source_url": source_url,
        "source_type": "public_html" if "html" in fetch.content_type.lower() else "public_text",
        "platform": "generic_web",
        "title": parsed["title"],
        "author": parsed["author"],
        "published_at": parsed["published_at"],
        "retrieved_at": retrieved_at,
        "content_hash": content_hash,
        "language": parsed["language"],
        "domain": parsed_url.netloc.lower(),
        "canonical_url": canonical_url,
        "backlink": canonical_url,
        "content_type": fetch.content_type,
        "extraction_method": parsed["extraction_method"],
    }


def _chunk(chunk_id: str, evidence_id: str, metadata: dict[str, Any], text: str) -> dict[str, Any]:
    return {
        "chunk_id": chunk_id,
        "chunk_type": "text",
        "source_type": metadata["source_type"],
        "source_url": metadata["source_url"],
        "platform": metadata["platform"],
        "title": metadata["title"],
        "author": metadata["author"],
        "published_at": metadata["published_at"],
        "retrieved_at": metadata["retrieved_at"],
        "content_hash": metadata["content_hash"],
        "text": text,
        "ocr_text": "",
        "visual_summary": "",
        "timestamp_start": "",
        "timestamp_end": "",
        "image_index": "",
        "bbox": "",
        "backlink": metadata["backlink"],
        "evidence_id": evidence_id,
        "confidence": 0.86,
    }


def _inventory(source_id: str, metadata: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "external_source_inventory.v1",
        "source_count": 1,
        "sources": [
            {
                "source_id": source_id,
                "source_url": metadata["source_url"],
                "canonical_url": metadata["canonical_url"],
                "source_type": metadata["source_type"],
                "platform": metadata["platform"],
                "title": metadata["title"],
                "domain": metadata["domain"],
                "retrieved_at": metadata["retrieved_at"],
                "content_hash": metadata["content_hash"],
            }
        ],
    }


def _source_trace(source_id: str, metadata: dict[str, Any], fetch: FetchResult, content_hash: str) -> dict[str, Any]:
    return {
        "schema_version": "external_source_trace.v1",
        "source_trace_required": True,
        "source_count": 1,
        "sources": [
            {
                "source_id": source_id,
                "source_type": metadata["source_type"],
                "source_url": metadata["source_url"],
                "canonical_url": metadata["canonical_url"],
                "retrieved_at": metadata["retrieved_at"],
                "content_hash": content_hash,
                "backlink": metadata["backlink"],
                "trace_status": "public_readable",
                "failure_reason": None,
                "http_status": fetch.status_code,
                "content_type": fetch.content_type,
            }
        ],
    }


def _evidence_map(source_id: str, chunk_id: str, evidence_id: str, metadata: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "external_evidence_map.v1",
        "evidence_map_required": True,
        "evidence_count": 1,
        "evidence": [
            {
                "evidence_id": evidence_id,
                "chunk_id": chunk_id,
                "source_id": source_id,
                "claim_id": "",
                "support_status": "source_chunk",
                "confidence": 0.86,
                "backlink": metadata["backlink"],
            }
        ],
    }


def _fetch_report(url: str, fetch: FetchResult, parsed: dict[str, Any], retrieved_at: str) -> dict[str, Any]:
    return {
        "schema_version": "external_fetch_report.v1",
        "status": "passed",
        "source_url": url,
        "final_url": fetch.final_url,
        "http_status": fetch.status_code,
        "content_type": fetch.content_type,
        "byte_count": len(fetch.body),
        "retrieved_at": retrieved_at,
        "extraction_method": parsed["extraction_method"],
        "text_length": len(parsed["text"]),
    }


def _failure_manifest(
    *,
    url: str,
    retrieved_at: str,
    preflight: dict[str, Any],
    error_code: str,
    error_message: str,
    status: str = "failed",
    readability_state: str | None = None,
) -> dict[str, Any]:
    return {
        "schema_version": "generic_web_url_ingestion_manifest.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "supplement": "3.0 External Source Memory & Verification",
        "step": "P0 Generic Web URL Ingestion",
        "status": status,
        "integration_decision": "needs_strengthening",
        "decision_qualifier": "generic_web_url_ingestion_attempt_failed",
        "source_url": url,
        "retrieved_at": retrieved_at,
        "preflight_status": preflight.get("status"),
        "readability_state": readability_state or preflight.get("readability_state"),
        "public_readable": False,
        "error_code": error_code,
        "failure_reason": error_message,
        "repair_suggestion": _repair_suggestion(error_code),
        "backlink": url,
        "source_trace_path": "external_source_trace.json",
        "evidence_map_path": "external_evidence_map.json",
        "progress_events_path": PROGRESS_EVENTS_FILE,
        "runtime_boundary": _runtime_boundary(),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": "Generic URL ingestion attempt did not produce accepted runtime evidence for this URL.",
        "next_required_e2e_step": "Retry Generic Web URL Ingestion with a public readable HTTP/HTML URL.",
        "not_goal_complete": True,
    }


def _write_success(
    output: Path,
    *,
    manifest: dict[str, Any],
    preflight: dict[str, Any],
    inventory: dict[str, Any],
    metadata: dict[str, Any],
    chunk: dict[str, Any],
    source_trace: dict[str, Any],
    evidence_map: dict[str, Any],
    fetch_report: dict[str, Any],
    change_report: dict[str, Any],
    validation: dict[str, Any],
) -> None:
    write_json(output / "external_source_inventory.json", inventory)
    write_json(output / "external_source_preflight.json", preflight)
    write_json(output / "link_ingestion_report.json", manifest)
    (output / "link_ingestion_report.md").write_text(_render_ingestion_report(manifest), encoding="utf-8")
    write_json(output / "external_fetch_report.json", fetch_report)
    (output / "external_fetch_report.md").write_text(_render_fetch_report(fetch_report), encoding="utf-8")
    write_json(output / "external_source_trace.json", source_trace)
    write_json(output / "external_evidence_map.json", evidence_map)
    write_json(output / "external_change_detection_report.json", change_report)
    write_jsonl(output / "external_chunks.jsonl", [chunk])
    write_json(output / "external_metadata.json", metadata)
    write_json(output / "generic_web_url_ingestion_validation_report.json", validation)
    write_json(output / "run_manifest.json", _run_manifest(manifest))
    (output / "run_summary.md").write_text(_render_run_summary(manifest), encoding="utf-8")


def _write_failure(output: Path, manifest: dict[str, Any], preflight: dict[str, Any]) -> None:
    empty_inventory = {"schema_version": "external_source_inventory.v1", "source_count": 0, "sources": []}
    empty_trace = {"schema_version": "external_source_trace.v1", "source_trace_required": True, "source_count": 0, "sources": []}
    empty_evidence = {
        "schema_version": "external_evidence_map.v1",
        "evidence_map_required": True,
        "evidence_count": 0,
        "evidence": [],
    }
    fetch_report = manifest.get("fetch_report") or {
        "schema_version": "external_fetch_report.v1",
        "status": manifest["status"],
        "source_url": manifest["source_url"],
        "error_code": manifest["error_code"],
        "failure_reason": manifest["failure_reason"],
    }
    validation = _validation_failure(manifest["error_code"])
    write_json(output / "external_source_inventory.json", empty_inventory)
    write_json(output / "external_source_preflight.json", preflight)
    write_json(output / "link_ingestion_report.json", manifest)
    (output / "link_ingestion_report.md").write_text(_render_ingestion_report(manifest), encoding="utf-8")
    write_json(output / "external_fetch_report.json", fetch_report)
    (output / "external_fetch_report.md").write_text(_render_fetch_report(fetch_report), encoding="utf-8")
    write_json(output / "external_source_trace.json", empty_trace)
    write_json(output / "external_evidence_map.json", empty_evidence)
    write_json(
        output / "external_change_detection_report.json",
        {"schema_version": "external_change_detection_report.v1", "status": "not_available"},
    )
    write_jsonl(output / "external_chunks.jsonl", [])
    write_json(output / "external_metadata.json", {})
    write_json(output / "generic_web_url_ingestion_validation_report.json", validation)
    write_json(output / "run_manifest.json", _run_manifest(manifest))
    (output / "run_summary.md").write_text(_render_run_summary(manifest), encoding="utf-8")


def _validation_failure(error_code: str, *, missing_files: list[str] | None = None) -> dict[str, Any]:
    return {
        "schema_version": "generic_web_url_ingestion_validation_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "status": "failed",
        "boundary_errors": [error_code],
        "missing_files": missing_files or [],
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": "Generic Web URL Ingestion evidence is incomplete.",
        "next_required_e2e_step": "Produce a passed Generic Web URL Ingestion run before advancing.",
        "not_goal_complete": True,
    }


def _run_manifest(manifest: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "audit_run_manifest.v1",
        "run_id": "external_source_generic_url",
        "generated_at": manifest.get("retrieved_at") or _now(),
        "type": "section_5_supplement_3_0_p0_generic_web_url_ingestion",
        "scope": "CAMPAIGN_3_SUPPLEMENT_3_0_P0_GENERIC_WEB_URL_INGESTION",
        "status": manifest["status"],
        "integration_decision": manifest["integration_decision"],
        "decision_qualifier": manifest["decision_qualifier"],
        "evidence_files": GENERIC_WEB_URL_FILES,
        "campaign_state_after_run": {
            "campaign_3_supplement_3_0_entry_gate_passed": True,
            "campaign_3_3_0_p0_framework_passed": True,
            "generic_web_url_ingestion_implemented": manifest["status"] == "passed",
            "platform_preflight_implemented": False,
            "opencli_runtime_integrated": False,
            "manual_evidence_processing_implemented": False,
            "campaign_3_3_0_accepted": False,
            "campaign_3_4_0_active": False,
            "campaign_3_accepted": False,
            "campaign_4_allowed": False,
            "next_business_item": (
                "Campaign 3 Supplement 3.0 P0 Platform Link Preflight"
                if manifest["status"] == "passed"
                else "Retry Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion"
            ),
        },
        "retention": "milestone",
        "keep_in_git": True,
        "final_target_not_downgraded": True,
        "remaining_gap": manifest["remaining_gap"],
        "next_required_e2e_step": manifest["next_required_e2e_step"],
        "not_goal_complete": True,
    }


def _render_ingestion_report(manifest: dict[str, Any]) -> str:
    return (
        "# Generic Web URL Ingestion Report\n\n"
        f"- Status: `{manifest['status']}`\n"
        f"- Decision: `{manifest['integration_decision']} / {manifest['decision_qualifier']}`\n"
        f"- Source URL: `{manifest['source_url']}`\n"
        f"- Readability: `{manifest.get('readability_state')}`\n"
        f"- Chunk count: `{manifest.get('chunk_count', 0)}`\n"
        f"- Next required step: `{manifest['next_required_e2e_step']}`\n\n"
        "Boundary: this step handles generic public HTTP/HTML URLs only. Platform Link Preflight, OpenCLI, "
        "manual evidence, authenticated browser reading, video/OCR, UI workflow acceptance, Core Bridge execution "
        "acceptance, Supplement 3.0 acceptance, Campaign 4, Full Gate, EXE, and release remain incomplete.\n"
    )


def _render_fetch_report(fetch_report: dict[str, Any]) -> str:
    rows = "\n".join(f"- {key}: `{value}`" for key, value in fetch_report.items())
    return f"# External Fetch Report\n\n{rows}\n"


def _render_run_summary(manifest: dict[str, Any]) -> str:
    return (
        "# Generic Web URL Ingestion Summary\n\n"
        f"Status: `{manifest['status']}`. "
        "A generic public URL was converted into traceable chunks only when public HTTP/HTML content was readable. "
        f"Next required E2E step: `{manifest['next_required_e2e_step']}`\n"
    )


def _fetch_error_code(exc: Exception) -> str:
    if isinstance(exc, error.HTTPError):
        if exc.code in {401, 403}:
            return "auth_or_permission_required"
        if exc.code in {429, 502, 503, 504}:
            return "network_retryable_failure"
        return "http_error"
    if isinstance(exc, error.URLError):
        return "network_error"
    if isinstance(exc, socket.timeout):
        return "timeout"
    return "fetch_failed"


def _repair_suggestion(error_code: str) -> str:
    suggestions = {
        "unsupported_url_scheme": "Use a public http:// or https:// URL.",
        "credentials_in_url_forbidden": "Remove credentials from the URL and use a public source.",
        "robots_disallowed": "Use an allowed public source or provide manual evidence.",
        "auth_or_permission_required": "Use platform preflight or provide manual evidence; do not bypass login.",
        "network_retryable_failure": "Retry after the external service recovers.",
        "network_error": "Check network connectivity and retry.",
        "timeout": "Retry with a reachable public source or increase the bounded timeout.",
        "empty_extracted_text": "Provide manual evidence when the public page has no extractable text.",
    }
    return suggestions.get(
        error_code,
        "Review the failure reason, then retry with a public readable source or provide manual evidence.",
    )


def _append_terminal_progress(progress_path: Path, result: dict[str, Any]) -> None:
    _append_progress(
        progress_path,
        stage="external_link_import",
        status=result["status"],
        message=result.get("failure_reason") or "External link import did not produce accepted content.",
        artifact_path="link_ingestion_report.json",
    )


def _append_progress(
    progress_path: Path,
    *,
    stage: str,
    status: str,
    message: str,
    artifact_path: str,
) -> None:
    event = {
        "schema_version": "external_source_progress_event.v1",
        "stage": stage,
        "status": status,
        "timestamp": _now(),
        "message": message,
        "artifact_path": artifact_path,
    }
    with progress_path.open("a", encoding="utf-8", newline="\n") as handle:
        handle.write(json.dumps(event, ensure_ascii=False, sort_keys=True))
        handle.write("\n")


def _normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def _fallback_title(url: str) -> str:
    path = parse.urlparse(url).path.strip("/")
    return path.rsplit("/", 1)[-1] or parse.urlparse(url).netloc


def _sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _stable_id(prefix: str, value: str) -> str:
    return f"{prefix}_{hashlib.sha256(value.encode('utf-8')).hexdigest()[:16]}"


def _now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _read_json(path: Path) -> dict[str, Any]:
    return __import__("json").loads(path.read_text(encoding="utf-8-sig"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    import json

    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
