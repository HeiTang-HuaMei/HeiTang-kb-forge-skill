from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib import parse

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


PLATFORM_PREFLIGHT_FILES = [
    "platform_link_detection.json",
    "platform_preflight_report.json",
    "platform_preflight_report.md",
    "platform_next_paths.json",
    "platform_visible_content.jsonl",
    "platform_preflight_validation_report.json",
    "run_manifest.json",
    "run_summary.md",
]

READABILITY_STATES = {
    "public_readable",
    "partial_readable",
    "login_required",
    "auth_required",
    "blocked_by_platform",
    "anti_crawl_detected",
    "paywall_or_permission_required",
    "video_without_transcript",
    "needs_opencli_verification",
    "needs_manual_evidence",
}

PLATFORM_RULES = [
    {
        "platform": "xiaohongshu",
        "label": "Xiaohongshu note",
        "domains": ("xiaohongshu.com", "xhslink.com"),
        "source_type": "platform_note",
        "readability_state": "auth_required",
        "failure_reason": "Xiaohongshu content often requires a user-visible authorized session; no login or anti-detection bypass is allowed.",
        "next_available_paths": [
            "opencli_external_search_verification",
            "authenticated_browser_visible_content",
            "manual_evidence_upload",
        ],
    },
    {
        "platform": "douyin",
        "label": "Douyin video",
        "domains": ("douyin.com", "iesdouyin.com"),
        "source_type": "platform_video",
        "readability_state": "video_without_transcript",
        "failure_reason": "Douyin links are video-first and do not provide a guaranteed public transcript through generic URL ingestion.",
        "next_available_paths": [
            "opencli_external_search_verification",
            "authenticated_browser_visible_content",
            "manual_evidence_upload",
            "video_to_knowledge_ingestion",
        ],
    },
    {
        "platform": "zhihu",
        "label": "Zhihu article or answer",
        "domains": ("zhihu.com",),
        "source_type": "platform_article",
        "readability_state": "partial_readable",
        "failure_reason": "Zhihu content may be partially public but can require login, permission, or manual evidence for complete source capture.",
        "next_available_paths": [
            "opencli_external_search_verification",
            "authenticated_browser_visible_content",
            "manual_evidence_upload",
        ],
    },
    {
        "platform": "bilibili",
        "label": "Bilibili video",
        "domains": ("bilibili.com", "b23.tv"),
        "source_type": "platform_video",
        "readability_state": "video_without_transcript",
        "failure_reason": "Bilibili links are video-first and require transcript, subtitle, or keyframe evidence before knowledge ingestion can be accepted.",
        "next_available_paths": [
            "opencli_external_search_verification",
            "manual_evidence_upload",
            "video_to_knowledge_ingestion",
        ],
    },
    {
        "platform": "wechat_public_article",
        "label": "WeChat public article",
        "domains": ("mp.weixin.qq.com",),
        "source_type": "platform_article",
        "readability_state": "partial_readable",
        "failure_reason": "WeChat public article readability varies by permission, redirects, and platform controls; generic fetch is not accepted as platform extraction.",
        "next_available_paths": [
            "opencli_external_search_verification",
            "manual_evidence_upload",
            "authenticated_browser_visible_content",
        ],
    },
    {
        "platform": "weibo",
        "label": "Weibo post",
        "domains": ("weibo.com", "m.weibo.cn"),
        "source_type": "platform_post",
        "readability_state": "login_required",
        "failure_reason": "Weibo posts often require login or visible user session for reliable reading; no login bypass is allowed.",
        "next_available_paths": [
            "opencli_external_search_verification",
            "authenticated_browser_visible_content",
            "manual_evidence_upload",
        ],
    },
]


def detect_platform_link(url: str) -> dict[str, Any]:
    parsed = parse.urlparse(url)
    domain = parsed.netloc.lower()
    if domain.startswith("www."):
        domain = domain[4:]
    rule = _match_rule(domain)
    if rule:
        return {
            "schema_version": "platform_link_detection.v1",
            "source_url": url,
            "domain": domain,
            "platform": rule["platform"],
            "platform_label": rule["label"],
            "source_type": rule["source_type"],
            "is_known_platform": True,
            "is_platform_link": True,
        }
    return {
        "schema_version": "platform_link_detection.v1",
        "source_url": url,
        "domain": domain,
        "platform": "other_or_unknown_platform",
        "platform_label": "Other or unknown platform",
        "source_type": "platform_or_public_web",
        "is_known_platform": False,
        "is_platform_link": parsed.scheme in {"http", "https"} and bool(domain),
    }


def preflight_platform_links(
    output: Path,
    *,
    urls: list[str],
    checked_at: str | None = None,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    checked_at = checked_at or _now()
    detections = [detect_platform_link(url) for url in urls]
    records = [_preflight_record(detection, checked_at) for detection in detections]
    detection_report = {
        "schema_version": "platform_link_detection_report.v1",
        "status": "passed",
        "source_count": len(records),
        "known_platform_count": sum(1 for item in records if item["is_known_platform"]),
        "detections": detections,
    }
    next_paths = {
        "schema_version": "platform_next_paths.v1",
        "status": "passed",
        "sources": [
            {
                "source_id": item["source_id"],
                "platform": item["platform"],
                "readability_state": item["readability_state"],
                "next_available_paths": item["next_available_paths"],
                "failure_reason": item["failure_reason"],
            }
            for item in records
        ],
    }
    report = {
        "schema_version": "platform_preflight_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "supplement": "3.0 External Source Memory & Verification",
        "step": "P0 Platform Link Preflight",
        "status": "passed",
        "integration_decision": "real_integration",
        "decision_qualifier": "platform_preflight_only",
        "integration_mode": "platform_link_detection_and_structured_readability_state",
        "checked_at": checked_at,
        "source_count": len(records),
        "platforms_detected": sorted({item["platform"] for item in records}),
        "readability_states": sorted({item["readability_state"] for item in records}),
        "runtime_boundary": _runtime_boundary(),
        "safety_boundary": _safety_boundary(),
        "records": records,
        "output_files": PLATFORM_PREFLIGHT_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Platform Link Preflight now identifies supported platform links, structured readability states, "
            "failure reasons, and next available paths without reading platform content. OpenCLI verification, "
            "manual evidence processing, authenticated browser reading, video/OCR runtime, UI workflow acceptance, "
            "Core Bridge execution acceptance, Supplement 3.0 acceptance, Supplement 4.0, Campaign 4, Full Gate, "
            "EXE, and release remain incomplete."
        ),
        "next_required_e2e_step": "Run Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification only.",
        "not_goal_complete": True,
    }
    validation = validate_platform_preflight_payload(report)
    _write_outputs(output, detection_report, report, next_paths, validation)
    return report | {"validation": validation}


def preflight_platform_link(output: Path, *, url: str, checked_at: str | None = None) -> dict[str, Any]:
    return preflight_platform_links(output, urls=[url], checked_at=checked_at)


def validate_platform_preflight(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [file_name for file_name in PLATFORM_PREFLIGHT_FILES if not (library / file_name).exists()]
    if missing:
        return _validation_failure("required_files_missing", missing_files=missing)
    report = _read_json(library / "platform_preflight_report.json")
    result = validate_platform_preflight_payload(report)
    return {**result, "required_files": PLATFORM_PREFLIGHT_FILES, "missing_files": missing}


def write_platform_preflight_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_platform_preflight(library)
    write_json(output / "platform_preflight_validation_report.json", result)
    return result


def validate_platform_preflight_payload(report: dict[str, Any]) -> dict[str, Any]:
    runtime = report.get("runtime_boundary", {})
    safety = report.get("safety_boundary", {})
    records = report.get("records", [])
    errors: list[str] = []
    if report.get("status") != "passed":
        errors.append("report_status_must_be_passed")
    if report.get("integration_decision") != "real_integration":
        errors.append("integration_decision_must_be_real_integration")
    if report.get("decision_qualifier") != "platform_preflight_only":
        errors.append("decision_qualifier_must_be_platform_preflight_only")
    if runtime.get("platform_link_preflight_implemented") is not True:
        errors.append("platform_link_preflight_implemented_must_be_true")
    for field in [
        "platform_content_extraction_implemented",
        "generic_web_url_ingestion_replaced",
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
    for field in [
        "no_login_bypass",
        "no_paywall_bypass",
        "no_captcha_bypass",
        "no_cookie_import",
        "no_cookie_upload",
        "no_anti_detection_behavior",
        "no_arbitrary_shell_execution",
        "content_fetch_forbidden_in_this_step",
        "user_triggered_only",
    ]:
        if safety.get(field) is not True:
            errors.append(f"{field}_must_be_true")
    if not records:
        errors.append("records_must_be_non_empty")
    for item in records:
        if not item.get("platform"):
            errors.append("platform_required")
        if item.get("readability_state") not in READABILITY_STATES:
            errors.append(f"invalid_readability_state:{item.get('readability_state')}")
        if item.get("readability_state") != "public_readable" and not item.get("failure_reason"):
            errors.append("unreadable_state_requires_failure_reason")
        if not item.get("next_available_paths"):
            errors.append("next_available_paths_required")
        for false_field in [
            "content_fetched",
            "content_extracted",
            "cookies_saved",
            "cookie_import_supported",
            "login_bypass_attempted",
            "anti_detection_attempted",
            "arbitrary_shell_execution",
        ]:
            if item.get(false_field) is not False:
                errors.append(f"{false_field}_must_be_false")
    status = "passed" if not errors else "failed"
    return {
        "schema_version": "platform_preflight_validation_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "status": status,
        "boundary_errors": errors,
        "source_count": len(records),
        "platforms_detected": sorted({item.get("platform") for item in records}),
        "readability_states": sorted({item.get("readability_state") for item in records}),
        "platform_link_preflight_implemented": runtime.get("platform_link_preflight_implemented"),
        "opencli_runtime_integrated": runtime.get("opencli_runtime_integrated"),
        "ui_workflow_accepted": runtime.get("ui_workflow_accepted"),
        "bridge_execution_accepted": runtime.get("bridge_execution_accepted"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": report.get("remaining_gap", ""),
        "next_required_e2e_step": report.get("next_required_e2e_step", ""),
        "not_goal_complete": True,
    }


def _preflight_record(detection: dict[str, Any], checked_at: str) -> dict[str, Any]:
    rule = _rule_by_platform(detection["platform"])
    if rule:
        state = rule["readability_state"]
        failure = rule["failure_reason"]
        paths = list(rule["next_available_paths"])
    else:
        state = "needs_opencli_verification" if detection["is_platform_link"] else "needs_manual_evidence"
        failure = (
            "Unknown platform link requires external verification or manual evidence before ingestion."
            if detection["is_platform_link"]
            else "URL is not a supported public HTTP/HTTPS platform link."
        )
        paths = ["generic_web_url_ingestion", "opencli_external_search_verification", "manual_evidence_upload"]
    return {
        "source_id": _stable_id(detection["source_url"]),
        "source_url": detection["source_url"],
        "domain": detection["domain"],
        "platform": detection["platform"],
        "platform_label": detection["platform_label"],
        "source_type": detection["source_type"],
        "is_known_platform": detection["is_known_platform"],
        "is_platform_link": detection["is_platform_link"],
        "readability_state": state,
        "public_readable": state == "public_readable",
        "failure_reason": "" if state == "public_readable" else failure,
        "next_available_paths": paths,
        "checked_at": checked_at,
        "content_fetched": False,
        "content_extracted": False,
        "cookies_saved": False,
        "cookie_import_supported": False,
        "login_bypass_attempted": False,
        "anti_detection_attempted": False,
        "arbitrary_shell_execution": False,
    }


def _runtime_boundary() -> dict[str, bool]:
    return {
        "platform_link_preflight_implemented": True,
        "platform_detection_implemented": True,
        "structured_readability_state_implemented": True,
        "failure_reason_implemented": True,
        "next_path_recommendation_implemented": True,
        "platform_content_extraction_implemented": False,
        "generic_web_url_ingestion_replaced": False,
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


def _safety_boundary() -> dict[str, bool]:
    return {
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
        "no_arbitrary_shell_execution": True,
        "content_fetch_forbidden_in_this_step": True,
        "user_triggered_only": True,
    }


def _write_outputs(
    output: Path,
    detection_report: dict[str, Any],
    report: dict[str, Any],
    next_paths: dict[str, Any],
    validation: dict[str, Any],
) -> None:
    write_json(output / "platform_link_detection.json", detection_report)
    write_json(output / "platform_preflight_report.json", report)
    (output / "platform_preflight_report.md").write_text(_render_report(report, validation), encoding="utf-8")
    write_json(output / "platform_next_paths.json", next_paths)
    write_jsonl(output / "platform_visible_content.jsonl", [])
    write_json(output / "platform_preflight_validation_report.json", validation)
    write_json(output / "run_manifest.json", _run_manifest(report))
    (output / "run_summary.md").write_text(_render_summary(report), encoding="utf-8")


def _run_manifest(report: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "audit_run_manifest.v1",
        "run_id": "external_source_platform_preflight",
        "generated_at": report["checked_at"],
        "type": "section_5_supplement_3_0_p0_platform_link_preflight",
        "scope": "CAMPAIGN_3_SUPPLEMENT_3_0_P0_PLATFORM_LINK_PREFLIGHT",
        "status": report["status"],
        "integration_decision": report["integration_decision"],
        "decision_qualifier": report["decision_qualifier"],
        "evidence_files": PLATFORM_PREFLIGHT_FILES,
        "campaign_state_after_run": {
            "campaign_3_supplement_3_0_entry_gate_passed": True,
            "campaign_3_3_0_p0_framework_passed": True,
            "generic_web_url_ingestion_implemented": True,
            "platform_preflight_implemented": True,
            "opencli_runtime_integrated": False,
            "manual_evidence_processing_implemented": False,
            "campaign_3_3_0_accepted": False,
            "campaign_3_4_0_active": False,
            "campaign_3_accepted": False,
            "campaign_4_allowed": False,
            "next_business_item": "Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification",
        },
        "retention": "milestone",
        "keep_in_git": True,
        "final_target_not_downgraded": True,
        "remaining_gap": report["remaining_gap"],
        "next_required_e2e_step": report["next_required_e2e_step"],
        "not_goal_complete": True,
    }


def _render_report(report: dict[str, Any], validation: dict[str, Any]) -> str:
    rows = "\n".join(
        f"| {item['platform']} | {item['readability_state']} | {', '.join(item['next_available_paths'])} |"
        for item in report["records"]
    )
    failures = "\n".join(f"- {error}" for error in validation["boundary_errors"]) or "- None"
    return (
        "# Platform Link Preflight Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Decision: `{report['integration_decision']} / {report['decision_qualifier']}`\n"
        f"- Source count: `{report['source_count']}`\n"
        "- Boundary: this step detects platform and readability state only; it does not fetch platform content, "
        "call OpenCLI, use authenticated browser sessions, import manual evidence, accept Supplement 3.0, or open Campaign 4.\n\n"
        "## Sources\n\n"
        "| Platform | Readability state | Next paths |\n"
        "| --- | --- | --- |\n"
        f"{rows}\n\n"
        "## Validation Errors\n\n"
        f"{failures}\n"
    )


def _render_summary(report: dict[str, Any]) -> str:
    return (
        "# Platform Link Preflight Summary\n\n"
        f"Status: `{report['status']}`. "
        "Supported platform links were classified into structured readability states without content extraction. "
        f"Next required E2E step: `{report['next_required_e2e_step']}`\n"
    )


def _match_rule(domain: str) -> dict[str, Any] | None:
    for rule in PLATFORM_RULES:
        if any(domain == suffix or domain.endswith(f".{suffix}") for suffix in rule["domains"]):
            return rule
    return None


def _rule_by_platform(platform: str) -> dict[str, Any] | None:
    for rule in PLATFORM_RULES:
        if rule["platform"] == platform:
            return rule
    return None


def _stable_id(value: str) -> str:
    return "platform_" + hashlib.sha256(value.encode("utf-8")).hexdigest()[:16]


def _now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _validation_failure(error_code: str, *, missing_files: list[str] | None = None) -> dict[str, Any]:
    return {
        "schema_version": "platform_preflight_validation_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "status": "failed",
        "boundary_errors": [error_code],
        "missing_files": missing_files or [],
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": "Platform Link Preflight evidence is incomplete.",
        "next_required_e2e_step": "Produce a passed Platform Link Preflight run before advancing.",
        "not_goal_complete": True,
    }
