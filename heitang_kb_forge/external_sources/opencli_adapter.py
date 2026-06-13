from __future__ import annotations

import json
import re
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable
from urllib import parse

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


OPENCLI_EXTERNAL_VERIFICATION_FILES = [
    "opencli_availability_report.json",
    "opencli_dependency_remediation_report.json",
    "external_search_candidates.jsonl",
    "external_verification_report.json",
    "external_verification_report.md",
    "external_source_confidence.json",
    "external_source_trace.json",
    "external_evidence_map.json",
    "opencli_external_verification_validation_report.json",
    "run_manifest.json",
    "run_summary.md",
]

OPENCLI_PACKAGE = "@jackwener/opencli"
OPENCLI_VERSION = "1.8.3"
OPENCLI_LICENSE = "Apache-2.0"
OPENCLI_SOURCE = "https://registry.npmjs.org/@jackwener/opencli"
OPENCLI_TARBALL = "https://registry.npmjs.org/@jackwener/opencli/-/opencli-1.8.3.tgz"
OPENCLI_INTEGRITY = "sha512-oz2Q2RSSw442dN0O0pgHA+clZoXt/crWF05wOJEsJWlEfEb5jjxCi+215WhOJZMPa1Mnz50CE/VxVndfLgmPJg=="

Runner = Callable[[list[str], int], dict[str, Any]]


def default_opencli_bin(repo_root: Path | None = None) -> Path | None:
    root = Path(repo_root or ".")
    local = root / "_local_dependency_remediation" / "opencli" / "node_modules" / ".bin" / (
        "opencli.cmd" if _is_windows() else "opencli"
    )
    if local.exists():
        return local
    found = shutil.which("opencli")
    return Path(found) if found else None


def check_opencli_external_verification(
    output: Path,
    *,
    opencli_bin: Path | None = None,
    repo_root: Path | None = None,
    runner: Runner | None = None,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    bin_path = opencli_bin or default_opencli_bin(repo_root)
    availability = _availability(bin_path, runner=runner)
    dependency = _dependency_report(bin_path)
    write_json(output / "opencli_availability_report.json", availability)
    write_json(output / "opencli_dependency_remediation_report.json", dependency)
    return availability


def verify_external_source_with_opencli(
    output: Path,
    *,
    query: str,
    claim: str | None = None,
    input_url: str | None = None,
    opencli_bin: Path | None = None,
    repo_root: Path | None = None,
    provider: str = "npm",
    limit: int = 3,
    allow_network: bool = True,
    runner: Runner | None = None,
    retrieved_at: str | None = None,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    retrieved_at = retrieved_at or _now()
    query = query.strip()
    claim = (claim or query).strip()
    bin_path = opencli_bin or default_opencli_bin(repo_root)
    availability = _availability(bin_path, runner=runner)
    dependency = _dependency_report(bin_path)

    if not query:
        report = _degraded_report(
            query=query,
            claim=claim,
            input_url=input_url,
            retrieved_at=retrieved_at,
            availability=availability,
            dependency=dependency,
            error_code="empty_query",
            error_message="OpenCLI verification requires a non-empty query.",
            network_called=False,
        )
        _write_outputs(output, report, [], availability, dependency)
        return report
    if not allow_network:
        report = _degraded_report(
            query=query,
            claim=claim,
            input_url=input_url,
            retrieved_at=retrieved_at,
            availability=availability,
            dependency=dependency,
            error_code="network_not_allowed",
            error_message="Network use was not enabled for this OpenCLI verification run.",
            network_called=False,
        )
        _write_outputs(output, report, [], availability, dependency)
        return report
    if availability["runtime_status"] != "available" or bin_path is None:
        report = _degraded_report(
            query=query,
            claim=claim,
            input_url=input_url,
            retrieved_at=retrieved_at,
            availability=availability,
            dependency=dependency,
            error_code="opencli_unavailable",
            error_message=availability.get("error_message") or "OpenCLI binary is unavailable.",
            network_called=False,
        )
        _write_outputs(output, report, [], availability, dependency)
        return report

    command = _search_command(bin_path, provider, query, limit)
    result = _run(command, timeout_seconds=30, runner=runner)
    if result["returncode"] != 0:
        report = _degraded_report(
            query=query,
            claim=claim,
            input_url=input_url,
            retrieved_at=retrieved_at,
            availability=availability,
            dependency=dependency,
            error_code=_failure_code(result),
            error_message=(result.get("stderr") or result.get("stdout") or "OpenCLI search failed").strip(),
            network_called=True,
        )
        _write_outputs(output, report, [], availability, dependency)
        return report

    raw_rows = _parse_json_rows(result.get("stdout", ""))
    candidates = _normalize_candidates(raw_rows, query=query, claim=claim, provider=provider, retrieved_at=retrieved_at)
    if not candidates:
        report = _degraded_report(
            query=query,
            claim=claim,
            input_url=input_url,
            retrieved_at=retrieved_at,
            availability=availability,
            dependency=dependency,
            error_code="no_candidates",
            error_message="OpenCLI returned no structured search candidates.",
            network_called=True,
        )
        _write_outputs(output, report, [], availability, dependency)
        return report

    confidence = _source_confidence(candidates, query=query, claim=claim)
    source_trace = _source_trace(candidates, query=query, claim=claim, input_url=input_url, retrieved_at=retrieved_at)
    evidence_map = _evidence_map(candidates, confidence, claim=claim)
    report = {
        "schema_version": "opencli_external_verification_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "supplement": "3.0 External Source Memory & Verification",
        "step": "P0 OpenCLI External Search Verification",
        "status": "passed",
        "verification_status": "verified" if confidence["overall_confidence"] >= 0.6 else "partially_verified",
        "integration_decision": "real_integration",
        "decision_qualifier": "opencli_external_search_verification_only",
        "integration_mode": "opencli_read_only_public_source_search_to_evidence_pipeline",
        "query": query,
        "claim": claim,
        "input_url": input_url or "",
        "provider": provider,
        "retrieved_at": retrieved_at,
        "candidate_count": len(candidates),
        "confidence": confidence,
        "runtime_boundary": _runtime_boundary(opencli_integrated=True),
        "safety_boundary": _safety_boundary(),
        "availability": availability,
        "dependency_remediation": dependency,
        "network_called": True,
        "output_files": OPENCLI_EXTERNAL_VERIFICATION_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "OpenCLI External Search Verification now discovers public candidates and maps them into "
            "source_trace, source confidence, and evidence_map. Manual Evidence Upload, authenticated browser "
            "reading, video/OCR runtime, UI workflow acceptance, Core Bridge execution acceptance, Supplement "
            "3.0 acceptance, Supplement 4.0, Campaign 4, Full Gate, EXE, and release remain incomplete."
        ),
        "next_required_e2e_step": "Run Campaign 3 Supplement 3.0 P0 Manual Evidence Upload only.",
        "not_goal_complete": True,
    }
    validation = validate_opencli_external_verification_payload(report, candidates, source_trace, evidence_map, confidence)
    report["validation"] = validation
    _write_outputs(output, report, candidates, availability, dependency, source_trace, evidence_map, confidence)
    return report


def validate_opencli_external_verification(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [
        file_name
        for file_name in OPENCLI_EXTERNAL_VERIFICATION_FILES
        if not (library / file_name).exists()
    ]
    if missing:
        return _validation_failure("required_files_missing", missing_files=missing)
    report = _read_json(library / "external_verification_report.json")
    candidates = _read_jsonl(library / "external_search_candidates.jsonl")
    source_trace = _read_json(library / "external_source_trace.json")
    evidence_map = _read_json(library / "external_evidence_map.json")
    confidence = _read_json(library / "external_source_confidence.json")
    result = validate_opencli_external_verification_payload(
        report,
        candidates,
        source_trace,
        evidence_map,
        confidence,
    )
    return {**result, "required_files": OPENCLI_EXTERNAL_VERIFICATION_FILES, "missing_files": missing}


def write_opencli_external_verification_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_opencli_external_verification(library)
    write_json(output / "opencli_external_verification_validation_report.json", result)
    return result


def validate_opencli_external_verification_payload(
    report: dict[str, Any],
    candidates: list[dict[str, Any]],
    source_trace: dict[str, Any],
    evidence_map: dict[str, Any],
    confidence: dict[str, Any],
) -> dict[str, Any]:
    runtime = report.get("runtime_boundary", {})
    safety = report.get("safety_boundary", {})
    errors: list[str] = []
    if report.get("status") not in {"passed", "degraded"}:
        errors.append("report_status_must_be_passed_or_degraded")
    if report.get("integration_decision") != "real_integration":
        errors.append("integration_decision_must_be_real_integration")
    if report.get("decision_qualifier") != "opencli_external_search_verification_only":
        errors.append("decision_qualifier_must_be_opencli_external_search_verification_only")
    if runtime.get("opencli_external_search_verification_implemented") is not True:
        errors.append("opencli_external_search_verification_implemented_must_be_true")
    for field in [
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
    for field in [
        "read_only_public_source_search",
        "no_login_bypass",
        "no_paywall_bypass",
        "no_captcha_bypass",
        "no_cookie_import",
        "no_plaintext_cookie_persistence",
        "no_cookie_upload",
        "no_anti_detection_behavior",
        "no_browser_session_used",
        "no_arbitrary_shell_execution",
        "user_triggered_only",
    ]:
        if safety.get(field) is not True:
            errors.append(f"{field}_must_be_true")
    if report.get("status") == "passed":
        if not candidates:
            errors.append("passed_report_requires_candidates")
        if source_trace.get("source_trace_required") is not True:
            errors.append("source_trace_required")
        if evidence_map.get("evidence_map_required") is not True:
            errors.append("evidence_map_required")
        if confidence.get("candidate_count") != len(candidates):
            errors.append("confidence_candidate_count_mismatch")
    if report.get("status") == "degraded":
        if report.get("graceful_degradation") is not True:
            errors.append("degraded_report_requires_graceful_degradation")
        if candidates:
            errors.append("degraded_report_must_not_emit_candidates")
    for item in candidates:
        if not item.get("source_url"):
            errors.append("candidate_source_url_required")
        if not item.get("title"):
            errors.append("candidate_title_required")
        if item.get("cookie_or_session_material_present") is not False:
            errors.append("candidate_cookie_or_session_material_present_must_be_false")
    status = "passed" if not errors else "failed"
    return {
        "schema_version": "opencli_external_verification_validation_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "status": status,
        "boundary_errors": errors,
        "candidate_count": len(candidates),
        "verification_status": report.get("verification_status"),
        "runtime_status": report.get("availability", {}).get("runtime_status"),
        "opencli_runtime_integrated": runtime.get("opencli_runtime_integrated"),
        "manual_evidence_processing_implemented": runtime.get("manual_evidence_processing_implemented"),
        "ui_workflow_accepted": runtime.get("ui_workflow_accepted"),
        "bridge_execution_accepted": runtime.get("bridge_execution_accepted"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": report.get("remaining_gap", ""),
        "next_required_e2e_step": report.get("next_required_e2e_step", ""),
        "not_goal_complete": True,
    }


def _availability(bin_path: Path | None, *, runner: Runner | None) -> dict[str, Any]:
    if not bin_path or not Path(bin_path).exists():
        return {
            "schema_version": "opencli_availability_report.v1",
            "status": "skipped",
            "runtime_status": "unavailable",
            "opencli_bin": "",
            "version": "",
            "package": OPENCLI_PACKAGE,
            "source": OPENCLI_SOURCE,
            "license": OPENCLI_LICENSE,
            "error_message": "OpenCLI binary was not found in the project-local remediation path or PATH.",
        }
    result = _run([str(bin_path), "--version"], timeout_seconds=15, runner=runner)
    version = result.get("stdout", "").strip()
    runtime_status = "available" if result["returncode"] == 0 else "unavailable"
    return {
        "schema_version": "opencli_availability_report.v1",
        "status": "passed" if runtime_status == "available" else "skipped",
        "runtime_status": runtime_status,
        "opencli_bin": str(Path(bin_path)).replace("\\", "/"),
        "version": version,
        "package": OPENCLI_PACKAGE,
        "source": OPENCLI_SOURCE,
        "license": OPENCLI_LICENSE,
        "error_message": "" if runtime_status == "available" else (result.get("stderr") or result.get("stdout", "")),
    }


def _dependency_report(bin_path: Path | None) -> dict[str, Any]:
    install_root = ""
    if bin_path:
        path = Path(bin_path)
        parts = path.parts
        if "_local_dependency_remediation" in parts:
            index = parts.index("_local_dependency_remediation")
            install_root = str(Path(*parts[: index + 2])).replace("\\", "/")
    return {
        "schema_version": "dependency_remediation_report.v1",
        "dependency": "OpenCLI",
        "package": OPENCLI_PACKAGE,
        "version": OPENCLI_VERSION,
        "license": OPENCLI_LICENSE,
        "source": OPENCLI_SOURCE,
        "tarball": OPENCLI_TARBALL,
        "integrity": OPENCLI_INTEGRITY,
        "install_command": "npm install @jackwener/opencli@1.8.3 --save-exact --no-audit --no-fund",
        "path": install_root or "_local_dependency_remediation/opencli",
        "risk": "Project-local npm dependency; no global PATH, registry, or user browser profile changes are required.",
        "rollback_plan": "Remove _local_dependency_remediation/opencli and generated audit outputs for this run.",
        "global_path_modified": False,
        "registry_written": False,
        "cookies_or_tokens_stored": False,
    }


def _search_command(bin_path: Path, provider: str, query: str, limit: int) -> list[str]:
    safe_limit = max(1, min(int(limit), 10))
    if provider != "npm":
        raise ValueError("Only the read-only npm OpenCLI adapter is enabled for this P0 smoke.")
    return [str(bin_path), "npm", "search", query, "--limit", str(safe_limit), "-f", "json"]


def _run(command: list[str], *, timeout_seconds: int, runner: Runner | None) -> dict[str, Any]:
    if runner is not None:
        return runner(command, timeout_seconds)
    try:
        completed = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=timeout_seconds,
            shell=False,
            check=False,
        )
        return {
            "returncode": completed.returncode,
            "stdout": completed.stdout,
            "stderr": completed.stderr,
        }
    except subprocess.TimeoutExpired as exc:
        return {
            "returncode": 124,
            "stdout": exc.stdout or "",
            "stderr": "timeout",
        }


def _parse_json_rows(text: str) -> list[dict[str, Any]]:
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return []
    if isinstance(data, list):
        return [item for item in data if isinstance(item, dict)]
    if isinstance(data, dict):
        for value in data.values():
            if isinstance(value, list):
                return [item for item in value if isinstance(item, dict)]
        return [data]
    return []


def _normalize_candidates(
    rows: list[dict[str, Any]],
    *,
    query: str,
    claim: str,
    provider: str,
    retrieved_at: str,
) -> list[dict[str, Any]]:
    candidates = []
    for index, row in enumerate(rows, start=1):
        url = str(row.get("url") or row.get("homepage") or row.get("repository") or "").strip()
        title = str(row.get("title") or row.get("name") or row.get("package") or "").strip()
        if not url or not title:
            continue
        description = str(row.get("snippet") or row.get("description") or row.get("summary") or "").strip()
        candidate_id = _stable_id("opencli_candidate", f"{provider}:{url}:{title}")
        evidence_id = _stable_id("opencli_evidence", candidate_id)
        candidates.append(
            {
                "schema_version": "external_search_candidate.v1",
                "candidate_id": candidate_id,
                "evidence_id": evidence_id,
                "rank": int(row.get("rank") or index),
                "provider": f"opencli:{provider}",
                "source_type": "public_registry_result" if provider == "npm" else "public_search_result",
                "title": title,
                "source_url": url,
                "display_url": parse.urlparse(url).netloc or url,
                "snippet": description,
                "license": row.get("license", ""),
                "published_or_updated_at": row.get("updated", ""),
                "retrieved_at": retrieved_at,
                "query": query,
                "claim": claim,
                "raw": _redact_sensitive(row),
                "cookie_or_session_material_present": False,
            }
        )
    return candidates


def _source_confidence(candidates: list[dict[str, Any]], *, query: str, claim: str) -> dict[str, Any]:
    scores = []
    query_terms = _terms(query)
    claim_terms = _terms(claim)
    for item in candidates:
        haystack = _terms(" ".join([item.get("title", ""), item.get("snippet", ""), item.get("source_url", "")]))
        query_overlap = _overlap(query_terms, haystack)
        claim_overlap = _overlap(claim_terms, haystack)
        authority = 0.9 if "npmjs.com" in item.get("source_url", "") else 0.6
        score = round(min(1.0, 0.35 + query_overlap * 0.3 + claim_overlap * 0.2 + authority * 0.15), 3)
        scores.append(
            {
                "candidate_id": item["candidate_id"],
                "evidence_id": item["evidence_id"],
                "source_url": item["source_url"],
                "confidence": score,
                "query_overlap": round(query_overlap, 3),
                "claim_overlap": round(claim_overlap, 3),
                "authority_score": authority,
            }
        )
    overall = round(max((item["confidence"] for item in scores), default=0.0), 3)
    return {
        "schema_version": "external_source_confidence.v1",
        "status": "passed",
        "candidate_count": len(candidates),
        "overall_confidence": overall,
        "verification_state": "verified" if overall >= 0.6 else "partially_verified",
        "scores": scores,
    }


def _source_trace(
    candidates: list[dict[str, Any]],
    *,
    query: str,
    claim: str,
    input_url: str | None,
    retrieved_at: str,
) -> dict[str, Any]:
    return {
        "schema_version": "external_source_trace.v1",
        "source_trace_required": True,
        "source_count": len(candidates),
        "query": query,
        "claim": claim,
        "input_url": input_url or "",
        "retrieved_at": retrieved_at,
        "sources": [
            {
                "source_id": item["candidate_id"],
                "evidence_id": item["evidence_id"],
                "source_type": item["source_type"],
                "title": item["title"],
                "source_url": item["source_url"],
                "retrieved_at": item["retrieved_at"],
                "provider": item["provider"],
            }
            for item in candidates
        ],
    }


def _evidence_map(
    candidates: list[dict[str, Any]],
    confidence: dict[str, Any],
    *,
    claim: str,
) -> dict[str, Any]:
    scores = {item["candidate_id"]: item for item in confidence.get("scores", [])}
    return {
        "schema_version": "external_evidence_map.v1",
        "evidence_map_required": True,
        "claim": claim,
        "evidence_count": len(candidates),
        "evidence": [
            {
                "evidence_id": item["evidence_id"],
                "candidate_id": item["candidate_id"],
                "claim": claim,
                "source_url": item["source_url"],
                "title": item["title"],
                "snippet": item["snippet"],
                "confidence": scores.get(item["candidate_id"], {}).get("confidence", 0.0),
                "support_state": "supporting_candidate",
            }
            for item in candidates
        ],
    }


def _degraded_report(
    *,
    query: str,
    claim: str,
    input_url: str | None,
    retrieved_at: str,
    availability: dict[str, Any],
    dependency: dict[str, Any],
    error_code: str,
    error_message: str,
    network_called: bool,
) -> dict[str, Any]:
    return {
        "schema_version": "opencli_external_verification_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "supplement": "3.0 External Source Memory & Verification",
        "step": "P0 OpenCLI External Search Verification",
        "status": "degraded",
        "verification_status": "external_service_unavailable",
        "integration_decision": "real_integration",
        "decision_qualifier": "opencli_external_search_verification_only",
        "integration_mode": "opencli_read_only_public_source_search_to_evidence_pipeline",
        "query": query,
        "claim": claim,
        "input_url": input_url or "",
        "provider": "opencli:npm",
        "retrieved_at": retrieved_at,
        "candidate_count": 0,
        "graceful_degradation": True,
        "error_code": error_code,
        "error_message": error_message,
        "runtime_boundary": _runtime_boundary(opencli_integrated=availability.get("runtime_status") == "available"),
        "safety_boundary": _safety_boundary(),
        "availability": availability,
        "dependency_remediation": dependency,
        "network_called": network_called,
        "output_files": OPENCLI_EXTERNAL_VERIFICATION_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "OpenCLI verification produced a graceful degradation record instead of failing the whole stage. "
            "A successful public-source candidate smoke is still required before this step can advance the sequence."
        ),
        "next_required_e2e_step": "Repair or retry Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification only.",
        "not_goal_complete": True,
    }


def _runtime_boundary(*, opencli_integrated: bool) -> dict[str, bool]:
    return {
        "opencli_external_search_verification_implemented": True,
        "opencli_runtime_integrated": opencli_integrated,
        "candidate_source_discovery_implemented": opencli_integrated,
        "source_confidence_implemented": opencli_integrated,
        "evidence_map_implemented": opencli_integrated,
        "natural_language_summary_only": False,
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


def _safety_boundary() -> dict[str, bool]:
    return {
        "read_only_public_source_search": True,
        "user_triggered_only": True,
        "no_login_bypass": True,
        "no_paywall_bypass": True,
        "no_captcha_bypass": True,
        "no_platform_control_bypass": True,
        "no_cookie_import": True,
        "no_plaintext_cookie_persistence": True,
        "no_cookie_upload": True,
        "no_anti_detection_behavior": True,
        "no_unlimited_crawler": True,
        "no_high_frequency_platform_collection": True,
        "no_browser_session_used": True,
        "no_arbitrary_shell_execution": True,
    }


def _write_outputs(
    output: Path,
    report: dict[str, Any],
    candidates: list[dict[str, Any]],
    availability: dict[str, Any],
    dependency: dict[str, Any],
    source_trace: dict[str, Any] | None = None,
    evidence_map: dict[str, Any] | None = None,
    confidence: dict[str, Any] | None = None,
) -> None:
    source_trace = source_trace or _empty_source_trace(report)
    evidence_map = evidence_map or _empty_evidence_map(report)
    confidence = confidence or _empty_confidence(report)
    validation = report.get("validation") or validate_opencli_external_verification_payload(
        report,
        candidates,
        source_trace,
        evidence_map,
        confidence,
    )
    write_json(output / "opencli_availability_report.json", availability)
    write_json(output / "opencli_dependency_remediation_report.json", dependency)
    write_jsonl(output / "external_search_candidates.jsonl", candidates)
    write_json(output / "external_verification_report.json", {key: value for key, value in report.items() if key != "validation"})
    (output / "external_verification_report.md").write_text(_render_report(report, validation), encoding="utf-8")
    write_json(output / "external_source_confidence.json", confidence)
    write_json(output / "external_source_trace.json", source_trace)
    write_json(output / "external_evidence_map.json", evidence_map)
    write_json(output / "opencli_external_verification_validation_report.json", validation)
    write_json(output / "run_manifest.json", _run_manifest(report))
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "audit_run_manifest.v1",
        "run_id": "external_source_opencli_verification",
        "generated_at": report["retrieved_at"],
        "type": "section_5_supplement_3_0_p0_opencli_external_search_verification",
        "scope": "CAMPAIGN_3_SUPPLEMENT_3_0_P0_OPENCLI_EXTERNAL_SEARCH_VERIFICATION",
        "status": report["status"],
        "verification_status": report["verification_status"],
        "integration_decision": report["integration_decision"],
        "decision_qualifier": report["decision_qualifier"],
        "evidence_files": OPENCLI_EXTERNAL_VERIFICATION_FILES,
        "campaign_state_after_run": {
            "campaign_3_supplement_3_0_entry_gate_passed": True,
            "campaign_3_3_0_p0_framework_passed": True,
            "generic_web_url_ingestion_implemented": True,
            "platform_preflight_implemented": True,
            "opencli_external_search_verification_implemented": True,
            "manual_evidence_processing_implemented": False,
            "campaign_3_3_0_accepted": False,
            "campaign_3_4_0_active": False,
            "campaign_3_accepted": False,
            "campaign_4_allowed": False,
            "next_business_item": (
                "Campaign 3 Supplement 3.0 P0 Manual Evidence Upload"
                if report["status"] == "passed"
                else "Retry Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification"
            ),
        },
        "retention": "milestone",
        "keep_in_git": True,
        "final_target_not_downgraded": True,
        "remaining_gap": report["remaining_gap"],
        "next_required_e2e_step": report["next_required_e2e_step"],
        "not_goal_complete": True,
    }


def _empty_source_trace(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "external_source_trace.v1",
        "source_trace_required": True,
        "source_count": 0,
        "query": report.get("query", ""),
        "claim": report.get("claim", ""),
        "input_url": report.get("input_url", ""),
        "retrieved_at": report.get("retrieved_at", ""),
        "sources": [],
    }


def _empty_evidence_map(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "external_evidence_map.v1",
        "evidence_map_required": True,
        "claim": report.get("claim", ""),
        "evidence_count": 0,
        "evidence": [],
    }


def _empty_confidence(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "external_source_confidence.v1",
        "status": "degraded",
        "candidate_count": 0,
        "overall_confidence": 0.0,
        "verification_state": report.get("verification_status", "external_service_unavailable"),
        "scores": [],
    }


def _render_report(report: dict[str, Any], validation: dict[str, Any]) -> str:
    return (
        "# OpenCLI External Search Verification Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Verification status: `{report['verification_status']}`\n"
        f"- Decision: `{report['integration_decision']} / {report['decision_qualifier']}`\n"
        f"- Query: `{report['query']}`\n"
        f"- Candidate count: `{report['candidate_count']}`\n"
        f"- OpenCLI runtime integrated: `{report['runtime_boundary']['opencli_runtime_integrated']}`\n"
        f"- Manual evidence implemented: `{report['runtime_boundary']['manual_evidence_processing_implemented']}`\n"
        f"- UI workflow accepted: `{report['runtime_boundary']['ui_workflow_accepted']}`\n"
        f"- Bridge execution accepted: `{report['runtime_boundary']['bridge_execution_accepted']}`\n"
        f"- Boundary errors: `{len(validation['boundary_errors'])}`\n\n"
        "This step maps OpenCLI read-only public-source results into structured candidates, confidence, "
        "source trace, and evidence map. It does not use browser sessions, cookies, login bypass, "
        "manual evidence processing, UI workflow acceptance, Bridge execution acceptance, or Supplement 3.0 acceptance.\n"
    )


def _render_summary(report: dict[str, Any]) -> str:
    return (
        "# OpenCLI External Search Verification Summary\n\n"
        f"Status: `{report['status']}`. "
        f"Verification status: `{report['verification_status']}`. "
        f"Next required E2E step: `{report['next_required_e2e_step']}`\n"
    )


def _validation_failure(error_code: str, *, missing_files: list[str]) -> dict[str, Any]:
    return {
        "schema_version": "opencli_external_verification_validation_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "status": "failed",
        "boundary_errors": [error_code],
        "candidate_count": 0,
        "verification_status": "failed",
        "required_files": OPENCLI_EXTERNAL_VERIFICATION_FILES,
        "missing_files": missing_files,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": "Required OpenCLI external verification evidence is incomplete.",
        "next_required_e2e_step": "Complete Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification before advancing.",
        "not_goal_complete": True,
    }


def _failure_code(result: dict[str, Any]) -> str:
    text = f"{result.get('stderr', '')}\n{result.get('stdout', '')}".lower()
    if "timeout" in text:
        return "network_timeout"
    if "fetch failed" in text or "connect" in text:
        return "network_error"
    return "opencli_command_failed"


def _terms(text: str) -> set[str]:
    return {item for item in re.findall(r"[a-z0-9][a-z0-9_-]*", text.lower()) if len(item) > 1}


def _overlap(left: set[str], right: set[str]) -> float:
    if not left:
        return 0.0
    return len(left & right) / len(left)


def _redact_sensitive(row: dict[str, Any]) -> dict[str, Any]:
    forbidden = {"cookie", "cookies", "authorization", "access_token", "refresh_token", "password", "session"}
    return {
        key: "[redacted]" if key.lower() in forbidden else value
        for key, value in row.items()
    }


def _stable_id(prefix: str, value: str) -> str:
    import hashlib

    return f"{prefix}_" + hashlib.sha256(value.encode("utf-8")).hexdigest()[:16]


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _now() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")


def _is_windows() -> bool:
    import os

    return os.name == "nt"
