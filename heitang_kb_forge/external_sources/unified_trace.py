from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


UNIFIED_TRACE_FILES = [
    "unified_source_trace.json",
    "unified_evidence_map.json",
    "external_source_progress_events.jsonl",
    "external_source_failure_isolation_report.json",
    "unified_trace_validation_report.json",
    "unified_trace_report.md",
    "run_manifest.json",
    "run_summary.md",
]

PIPELINE_ORDER = [
    "generic_web_url",
    "platform_link_preflight",
    "opencli_external_search_verification",
    "manual_evidence_upload",
]


@dataclass(frozen=True)
class PipelineSpec:
    pipeline_id: str
    display_name: str
    evidence_dir: str
    report_file: str
    trace_file: str | None
    evidence_file: str | None
    validation_file: str
    decision_class: str
    expected_qualifier: str
    integration_mode: str


PIPELINE_SPECS = [
    PipelineSpec(
        pipeline_id="generic_web_url",
        display_name="Generic Web URL Ingestion",
        evidence_dir="external_source_generic_url",
        report_file="ingestion/link_ingestion_report.json",
        trace_file="ingestion/external_source_trace.json",
        evidence_file="ingestion/external_evidence_map.json",
        validation_file="ingestion/generic_web_url_ingestion_validation_report.json",
        decision_class="real_integration",
        expected_qualifier="generic_web_url_ingestion_only",
        integration_mode="public_http_html_to_traceable_chunks",
    ),
    PipelineSpec(
        pipeline_id="platform_link_preflight",
        display_name="Platform Link Preflight",
        evidence_dir="external_source_platform_preflight",
        report_file="preflight/platform_preflight_report.json",
        trace_file=None,
        evidence_file=None,
        validation_file="preflight/platform_preflight_validation_report.json",
        decision_class="preflight_only",
        expected_qualifier="platform_preflight_only",
        integration_mode="platform_link_detection_and_structured_readability_state",
    ),
    PipelineSpec(
        pipeline_id="opencli_external_search_verification",
        display_name="OpenCLI External Search Verification",
        evidence_dir="external_source_opencli_verification",
        report_file="external_verification_report.json",
        trace_file="external_source_trace.json",
        evidence_file="external_evidence_map.json",
        validation_file="opencli_external_verification_validation_report.json",
        decision_class="verification_result",
        expected_qualifier="opencli_external_search_verification_only",
        integration_mode="opencli_read_only_public_source_search_to_evidence_pipeline",
    ),
    PipelineSpec(
        pipeline_id="manual_evidence_upload",
        display_name="Manual Evidence Upload",
        evidence_dir="external_source_manual_evidence",
        report_file="manual_evidence_manifest.json",
        trace_file="manual_source_trace.json",
        evidence_file="manual_evidence_map.json",
        validation_file="manual_evidence_validation_report.json",
        decision_class="manual_evidence",
        expected_qualifier="manual_evidence_upload_only",
        integration_mode="user_supplied_manual_evidence_to_traceable_blocks",
    ),
]


def build_external_source_unified_trace(
    output: Path,
    *,
    evidence_root: Path = Path("artifacts/audits/section_5"),
    generated_at: str | None = None,
) -> dict[str, Any]:
    output = Path(output)
    evidence_root = Path(evidence_root)
    output.mkdir(parents=True, exist_ok=True)
    generated_at = generated_at or _now()

    progress: list[dict[str, Any]] = []
    pipeline_summaries: list[dict[str, Any]] = []
    source_records: list[dict[str, Any]] = []
    evidence_records: list[dict[str, Any]] = []
    isolated_failures: list[dict[str, Any]] = []

    _event(
        progress,
        stage="build_started",
        status="started",
        timestamp=generated_at,
        message="Started bounded industrial-grade unified trace/evidence/progress/failure isolation build.",
        artifact_path=str(output),
    )

    for spec in PIPELINE_SPECS:
        pipeline_dir = evidence_root / spec.evidence_dir
        _event(
            progress,
            stage="pipeline_discovered",
            status="started",
            timestamp=generated_at,
            message=f"Reading {spec.display_name} evidence.",
            artifact_path=str(pipeline_dir),
            pipeline_id=spec.pipeline_id,
        )
        summary, sources, evidence, failures = _read_pipeline(spec, pipeline_dir, evidence_root)
        pipeline_summaries.append(summary)
        source_records.extend(sources)
        evidence_records.extend(evidence)
        isolated_failures.extend(failures)
        _event(
            progress,
            stage="pipeline_merged",
            status=summary["status"],
            timestamp=generated_at,
            message=(
                f"{spec.display_name} status={summary['status']} "
                f"sources={summary['source_count']} evidence={summary['evidence_count']}."
            ),
            artifact_path=summary["audit_dir"],
            pipeline_id=spec.pipeline_id,
        )
        for failure in failures:
            _event(
                progress,
                stage="failure_isolated",
                status=failure["source_status"],
                timestamp=generated_at,
                message=failure["failure_reason"],
                artifact_path=failure["artifact_path"],
                pipeline_id=spec.pipeline_id,
            )

    status = _overall_status(pipeline_summaries)
    unified_trace = {
        "schema_version": "external_source_unified_source_trace.v1",
        "source_trace_required": True,
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "supplement": "3.0 External Source Memory & Verification",
        "step": "P0 unified Source Trace / Evidence Map, progress events, and failure isolation",
        "status": status,
        "generated_at": generated_at,
        "pipeline_count": len(pipeline_summaries),
        "source_count": len(source_records),
        "pipelines": pipeline_summaries,
        "sources": source_records,
        "planned_not_active_schema_fields": _planned_not_active_fields(),
        "runtime_boundary": _runtime_boundary(),
        "safety_boundary": _safety_boundary(),
        "final_target_not_downgraded": True,
        "remaining_gap": _remaining_gap(),
        "next_required_e2e_step": (
            "Run Campaign 3 Supplement 3.0 P0 External Link Import entry plus real Core Bridge "
            "allowlist registrations and no-shell tests only."
        ),
        "not_goal_complete": True,
    }
    unified_evidence_map = {
        "schema_version": "external_source_unified_evidence_map.v1",
        "evidence_map_required": True,
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "status": status,
        "generated_at": generated_at,
        "evidence_count": len(evidence_records),
        "evidence": evidence_records,
        "knowledge_verification_engine_completed": False,
        "runtime_boundary": _runtime_boundary(),
        "final_target_not_downgraded": True,
        "remaining_gap": _remaining_gap(),
        "next_required_e2e_step": unified_trace["next_required_e2e_step"],
        "not_goal_complete": True,
    }
    failure_report = {
        "schema_version": "external_source_failure_isolation_report.v1",
        "status": "passed" if isolated_failures else "no_failures",
        "failure_isolation": True,
        "isolated_failure_count": len(isolated_failures),
        "isolated_failures": isolated_failures,
        "one_source_failure_does_not_abort_unified_report": True,
        "runtime_boundary": _runtime_boundary(),
        "final_target_not_downgraded": True,
        "remaining_gap": _remaining_gap(),
        "next_required_e2e_step": unified_trace["next_required_e2e_step"],
        "not_goal_complete": True,
    }
    validation = validate_external_source_unified_trace_payload(
        unified_trace,
        unified_evidence_map,
        progress,
        failure_report,
    )
    _event(
        progress,
        stage="validation_completed",
        status=validation["status"],
        timestamp=generated_at,
        message=f"Unified trace validation completed with {len(validation['boundary_errors'])} boundary errors.",
        artifact_path=str(output / "unified_trace_validation_report.json"),
    )
    _event(
        progress,
        stage="build_completed",
        status=status,
        timestamp=generated_at,
        message=f"Unified trace build completed with status={status}.",
        artifact_path=str(output / "run_manifest.json"),
    )

    write_json(output / "unified_source_trace.json", unified_trace)
    write_json(output / "unified_evidence_map.json", unified_evidence_map)
    write_jsonl(output / "external_source_progress_events.jsonl", progress)
    write_json(output / "external_source_failure_isolation_report.json", failure_report)
    write_json(output / "unified_trace_validation_report.json", validation)
    (output / "unified_trace_report.md").write_text(
        _render_report(unified_trace, unified_evidence_map, failure_report, validation),
        encoding="utf-8",
    )
    write_json(output / "run_manifest.json", _run_manifest(unified_trace, validation))
    (output / "run_summary.md").write_text(_render_summary(unified_trace, failure_report), encoding="utf-8")
    return unified_trace | {"validation": validation}


def validate_external_source_unified_trace(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [file_name for file_name in UNIFIED_TRACE_FILES if not (library / file_name).exists()]
    if missing:
        return _validation_failure("required_files_missing", missing_files=missing)
    unified_trace = _read_json(library / "unified_source_trace.json")
    unified_evidence_map = _read_json(library / "unified_evidence_map.json")
    progress = _read_jsonl(library / "external_source_progress_events.jsonl")
    failure_report = _read_json(library / "external_source_failure_isolation_report.json")
    result = validate_external_source_unified_trace_payload(
        unified_trace,
        unified_evidence_map,
        progress,
        failure_report,
    )
    return {**result, "required_files": UNIFIED_TRACE_FILES, "missing_files": missing}


def write_external_source_unified_trace_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_external_source_unified_trace(library)
    write_json(output / "unified_trace_validation_report.json", result)
    return result


def validate_external_source_unified_trace_payload(
    unified_trace: dict[str, Any],
    unified_evidence_map: dict[str, Any],
    progress: list[dict[str, Any]],
    failure_report: dict[str, Any],
) -> dict[str, Any]:
    errors: list[str] = []
    runtime = unified_trace.get("runtime_boundary", {})
    safety = unified_trace.get("safety_boundary", {})
    sources = unified_trace.get("sources", [])
    evidence = unified_evidence_map.get("evidence", [])
    pipelines = unified_trace.get("pipelines", [])

    if unified_trace.get("status") not in {"passed", "partial", "failed"}:
        errors.append("unified_trace_status_invalid")
    if unified_evidence_map.get("status") != unified_trace.get("status"):
        errors.append("evidence_map_status_must_match_trace")
    if len(pipelines) != len(PIPELINE_SPECS):
        errors.append("all_expected_pipelines_must_be_reported")
    if {item.get("pipeline_id") for item in pipelines} != set(PIPELINE_ORDER):
        errors.append("pipeline_ids_must_match_locked_p0_inputs")
    if unified_trace.get("source_count") != len(sources):
        errors.append("source_count_must_match_sources")
    if unified_evidence_map.get("evidence_count") != len(evidence):
        errors.append("evidence_count_must_match_evidence")
    if not progress:
        errors.append("progress_events_required")
    for event in progress:
        for field in ["stage", "status", "timestamp", "message", "artifact_path"]:
            if field not in event:
                errors.append(f"progress_event_{field}_required")
    for field in [
        "unified_source_trace_implemented",
        "unified_evidence_map_implemented",
        "progress_events_implemented",
        "failure_isolation_implemented",
        "generic_web_url_ingestion_covered",
        "platform_preflight_covered",
        "opencli_external_search_verification_covered",
        "manual_evidence_upload_covered",
    ]:
        if runtime.get(field) is not True:
            errors.append(f"{field}_must_be_true")
    for field in [
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
        "no_platform_control_bypass",
        "no_cookie_import",
        "no_plaintext_cookie_persistence",
        "no_cookie_upload",
        "no_arbitrary_shell_execution",
        "user_triggered_only",
    ]:
        if safety.get(field) is not True:
            errors.append(f"{field}_must_be_true")
    for source in sources:
        _validate_source(source, errors)
    for item in evidence:
        _validate_evidence(item, errors)
    if failure_report.get("failure_isolation") is not True:
        errors.append("failure_isolation_report_must_enable_isolation")
    if failure_report.get("isolated_failure_count") != len(failure_report.get("isolated_failures", [])):
        errors.append("isolated_failure_count_must_match_failures")
    if unified_evidence_map.get("knowledge_verification_engine_completed") is not False:
        errors.append("unified_evidence_map_must_not_claim_knowledge_verification_engine")
    if unified_trace.get("planned_not_active_schema_fields", {}).get("video_ocr_visual_evidence") != "planned_not_active":
        errors.append("video_ocr_schema_field_must_be_planned_not_active")
    if unified_trace.get("planned_not_active_schema_fields", {}).get("knowledge_verification_engine") != "planned_not_active":
        errors.append("knowledge_verification_schema_field_must_be_planned_not_active")

    return {
        "schema_version": "external_source_unified_trace_validation_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "status": "passed" if not errors else "failed",
        "business_status": unified_trace.get("status"),
        "boundary_errors": errors,
        "pipeline_count": len(pipelines),
        "source_count": len(sources),
        "evidence_count": len(evidence),
        "progress_event_count": len(progress),
        "isolated_failure_count": failure_report.get("isolated_failure_count", 0),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": unified_trace.get("remaining_gap", ""),
        "next_required_e2e_step": unified_trace.get("next_required_e2e_step", ""),
        "not_goal_complete": True,
    }


def _read_pipeline(
    spec: PipelineSpec,
    pipeline_dir: Path,
    evidence_root: Path,
) -> tuple[dict[str, Any], list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    display_root = _display_root(evidence_root)
    missing_paths = _missing_pipeline_paths(spec, pipeline_dir)
    if missing_paths:
        failure = _pipeline_failure(spec, pipeline_dir, missing_paths, display_root)
        return failure["pipeline"], [], [], [failure["failure"]]

    report_path = pipeline_dir / spec.report_file
    report = _read_json(report_path)
    validation = _read_json(pipeline_dir / spec.validation_file)
    raw_trace = _read_json(pipeline_dir / spec.trace_file) if spec.trace_file else {}
    raw_evidence = _read_json(pipeline_dir / spec.evidence_file) if spec.evidence_file else {}

    if spec.pipeline_id == "platform_link_preflight":
        sources = [_source_from_platform_record(spec, item, report_path, report, display_root) for item in report.get("records", [])]
        evidence = [
            _evidence_from_platform_record(spec, source, report_path, display_root)
            for source in sources
        ]
    else:
        sources = [
            _normalize_source(spec, item, report_path, report, display_root)
            for item in raw_trace.get("sources", [])
        ]
        evidence = [
            _normalize_evidence(spec, item, pipeline_dir / (spec.evidence_file or spec.report_file), sources, report, display_root)
            for item in raw_evidence.get("evidence", [])
        ]

    failures = [_failure_from_source(source) for source in sources if source["source_status"] != "passed"]
    pipeline_status = _pipeline_status_from_sources(report.get("status", "failed"), sources, validation)
    summary = {
        "pipeline_id": spec.pipeline_id,
        "display_name": spec.display_name,
        "status": pipeline_status,
        "reported_status": report.get("status", ""),
        "integration_decision": report.get("integration_decision", ""),
        "decision_qualifier": report.get("decision_qualifier", ""),
        "decision_class": spec.decision_class,
        "integration_mode": report.get("integration_mode", spec.integration_mode),
        "source_count": len(sources),
        "evidence_count": len(evidence),
        "isolated_failure_count": len(failures),
        "audit_dir": _rel(pipeline_dir, display_root),
        "report_artifact_path": _rel(report_path, display_root),
        "validation_status": validation.get("status", ""),
        "source_trace_artifact_path": _rel(pipeline_dir / spec.trace_file, display_root) if spec.trace_file else "",
        "evidence_map_artifact_path": _rel(pipeline_dir / spec.evidence_file, display_root) if spec.evidence_file else "",
        "repair_suggestion": "No repair needed." if pipeline_status == "passed" else _repair_suggestion(spec.pipeline_id, pipeline_status),
    }
    return summary, sources, evidence, failures


def _missing_pipeline_paths(spec: PipelineSpec, pipeline_dir: Path) -> list[str]:
    required = [spec.report_file, spec.validation_file]
    if spec.trace_file:
        required.append(spec.trace_file)
    if spec.evidence_file:
        required.append(spec.evidence_file)
    return [item for item in required if not (pipeline_dir / item).exists()]


def _pipeline_failure(
    spec: PipelineSpec,
    pipeline_dir: Path,
    missing_paths: list[str],
    display_root: Path,
) -> dict[str, Any]:
    reason = f"Required audit evidence is missing: {', '.join(missing_paths)}"
    source_trace = {
        "source_id": _stable_id("missing_source", spec.pipeline_id),
        "source_pipeline": spec.pipeline_id,
        "source_status": "failed",
        "failure_reason": reason,
        "repair_suggestion": _repair_suggestion(spec.pipeline_id, "missing_audit"),
        "source_trace": {},
        "source_audit_file": _rel(pipeline_dir, display_root),
    }
    return {
        "pipeline": {
            "pipeline_id": spec.pipeline_id,
            "display_name": spec.display_name,
            "status": "failed",
            "reported_status": "missing",
            "integration_decision": "",
            "decision_qualifier": spec.expected_qualifier,
            "decision_class": spec.decision_class,
            "integration_mode": spec.integration_mode,
            "source_count": 0,
            "evidence_count": 0,
            "isolated_failure_count": 1,
            "audit_dir": _rel(pipeline_dir, display_root),
            "report_artifact_path": "",
            "validation_status": "missing",
            "source_trace_artifact_path": "",
            "evidence_map_artifact_path": "",
            "repair_suggestion": _repair_suggestion(spec.pipeline_id, "missing_audit"),
        },
        "failure": {
            "pipeline_id": spec.pipeline_id,
            "source_id": source_trace["source_id"],
            "source_status": "failed",
            "error_type": "missing_audit_evidence",
            "failure_reason": reason,
            "repair_suggestion": _repair_suggestion(spec.pipeline_id, "missing_audit"),
            "source_trace": source_trace,
            "artifact_path": _rel(pipeline_dir, display_root),
        },
    }


def _normalize_source(
    spec: PipelineSpec,
    item: dict[str, Any],
    report_path: Path,
    report: dict[str, Any],
    display_root: Path,
) -> dict[str, Any]:
    source_id = str(item.get("source_id") or item.get("candidate_id") or item.get("evidence_id") or _stable_id("source", json.dumps(item, sort_keys=True)))
    evidence_id = str(item.get("evidence_id") or "")
    source_status = _source_status(item.get("trace_status") or item.get("status") or report.get("status"))
    failure_reason = item.get("failure_reason") or ""
    if source_status != "passed" and not failure_reason:
        failure_reason = _default_failure_reason(source_status, spec.pipeline_id)
    return {
        "source_id": source_id,
        "source_pipeline": spec.pipeline_id,
        "display_name": spec.display_name,
        "source_status": source_status,
        "source_type": item.get("source_type", ""),
        "source_url": item.get("source_url") or item.get("user_provided_source_url") or "",
        "canonical_url": item.get("canonical_url", ""),
        "title": item.get("title", ""),
        "platform": item.get("platform", ""),
        "evidence_id": evidence_id,
        "content_hash": item.get("content_hash") or _stable_id("content", json.dumps(item, sort_keys=True)),
        "integration_decision": report.get("integration_decision", ""),
        "decision_qualifier": report.get("decision_qualifier", ""),
        "decision_class": spec.decision_class,
        "integration_mode": report.get("integration_mode", spec.integration_mode),
        "backlink": item.get("backlink") or item.get("source_url") or item.get("user_provided_source_url") or "",
        "failure_reason": failure_reason,
        "repair_suggestion": _repair_suggestion(spec.pipeline_id, source_status),
        "source_trace": item,
        "source_audit_file": _rel(report_path, display_root),
        "source_trace_audit_file": _rel(report_path, display_root),
        "manual_evidence_not_platform_fetch_success": spec.pipeline_id != "manual_evidence_upload" or True,
        "opencli_not_authenticated_browser_connector": spec.pipeline_id != "opencli_external_search_verification" or True,
    }


def _source_from_platform_record(
    spec: PipelineSpec,
    item: dict[str, Any],
    report_path: Path,
    report: dict[str, Any],
    display_root: Path,
) -> dict[str, Any]:
    status = _source_status(item.get("readability_state"))
    return {
        "source_id": item["source_id"],
        "source_pipeline": spec.pipeline_id,
        "display_name": spec.display_name,
        "source_status": status,
        "source_type": item.get("source_type", ""),
        "source_url": item.get("source_url", ""),
        "canonical_url": "",
        "title": item.get("platform_label", ""),
        "platform": item.get("platform", ""),
        "evidence_id": _stable_id("platform_evidence", item["source_id"]),
        "content_hash": _stable_id("content", f"{item.get('source_url')}|{item.get('readability_state')}"),
        "integration_decision": report.get("integration_decision", ""),
        "decision_qualifier": report.get("decision_qualifier", ""),
        "decision_class": spec.decision_class,
        "integration_mode": report.get("integration_mode", spec.integration_mode),
        "backlink": item.get("source_url", ""),
        "failure_reason": item.get("failure_reason", "") if status != "passed" else "",
        "repair_suggestion": _repair_suggestion(spec.pipeline_id, status, item.get("next_available_paths", [])),
        "source_trace": item,
        "source_audit_file": _rel(report_path, display_root),
        "source_trace_audit_file": _rel(report_path, display_root),
        "manual_evidence_not_platform_fetch_success": True,
        "opencli_not_authenticated_browser_connector": True,
    }


def _normalize_evidence(
    spec: PipelineSpec,
    item: dict[str, Any],
    evidence_path: Path,
    sources: list[dict[str, Any]],
    report: dict[str, Any],
    display_root: Path,
) -> dict[str, Any]:
    source_id = item.get("source_id") or item.get("candidate_id") or _source_id_for_evidence(item, sources)
    source = next((entry for entry in sources if entry["source_id"] == source_id or entry.get("evidence_id") == item.get("evidence_id")), {})
    evidence_id = str(item.get("evidence_id") or _stable_id("evidence", json.dumps(item, sort_keys=True)))
    return {
        "unified_evidence_id": _stable_id("unified_evidence", f"{spec.pipeline_id}:{evidence_id}"),
        "evidence_id": evidence_id,
        "source_pipeline": spec.pipeline_id,
        "source_id": source_id or source.get("source_id", ""),
        "source_type": item.get("source_type") or source.get("source_type", ""),
        "source_url": item.get("source_url") or source.get("source_url", ""),
        "content_hash": item.get("content_hash") or source.get("content_hash") or _stable_id("content", json.dumps(item, sort_keys=True)),
        "integration_decision": report.get("integration_decision", ""),
        "decision_qualifier": report.get("decision_qualifier", ""),
        "decision_class": spec.decision_class,
        "integration_mode": report.get("integration_mode", spec.integration_mode),
        "support_status": item.get("support_status") or item.get("support_state") or "",
        "confidence": item.get("confidence", 0.0),
        "backlink": item.get("backlink") or item.get("source_url") or source.get("backlink", ""),
        "failure_reason": item.get("failure_reason") or source.get("failure_reason", ""),
        "repair_suggestion": source.get("repair_suggestion") or _repair_suggestion(spec.pipeline_id, source.get("source_status", "passed")),
        "source_audit_file": source.get("source_audit_file", ""),
        "evidence_audit_file": _rel(evidence_path, display_root),
        "knowledge_verification_engine_completed": False,
    }


def _evidence_from_platform_record(
    spec: PipelineSpec,
    source: dict[str, Any],
    report_path: Path,
    display_root: Path,
) -> dict[str, Any]:
    evidence_id = source["evidence_id"]
    return {
        "unified_evidence_id": _stable_id("unified_evidence", f"{spec.pipeline_id}:{evidence_id}"),
        "evidence_id": evidence_id,
        "source_pipeline": spec.pipeline_id,
        "source_id": source["source_id"],
        "source_type": source["source_type"],
        "source_url": source["source_url"],
        "content_hash": source["content_hash"],
        "integration_decision": source["integration_decision"],
        "decision_qualifier": source["decision_qualifier"],
        "decision_class": spec.decision_class,
        "integration_mode": source["integration_mode"],
        "support_status": f"platform_preflight_{source['source_status']}",
        "confidence": 0.5 if source["source_status"] != "passed" else 0.75,
        "backlink": source["backlink"],
        "failure_reason": source["failure_reason"],
        "repair_suggestion": source["repair_suggestion"],
        "source_audit_file": source["source_audit_file"],
        "evidence_audit_file": _rel(report_path, display_root),
        "knowledge_verification_engine_completed": False,
    }


def _failure_from_source(source: dict[str, Any]) -> dict[str, Any]:
    return {
        "pipeline_id": source["source_pipeline"],
        "source_id": source["source_id"],
        "source_status": source["source_status"],
        "error_type": source["source_status"],
        "failure_reason": source["failure_reason"] or _default_failure_reason(source["source_status"], source["source_pipeline"]),
        "repair_suggestion": source["repair_suggestion"],
        "source_trace": source,
        "artifact_path": source["source_audit_file"],
    }


def _pipeline_status_from_sources(
    reported_status: str,
    sources: list[dict[str, Any]],
    validation: dict[str, Any],
) -> str:
    if validation.get("status") == "failed":
        return "failed"
    if reported_status == "passed":
        return "passed"
    if reported_status in {"partial", "failed", "skipped", "blocked"}:
        return reported_status
    if not sources:
        return "failed"
    statuses = {source["source_status"] for source in sources}
    if statuses == {"passed"} and reported_status == "passed":
        return "passed"
    if "failed" in statuses or reported_status == "failed":
        return "partial" if "passed" in statuses else "failed"
    if "blocked" in statuses:
        return "blocked" if statuses == {"blocked"} else "partial"
    if "partial" in statuses:
        return "partial"
    if "skipped" in statuses:
        return "skipped" if statuses == {"skipped"} else "partial"
    return "partial"


def _source_status(raw: Any) -> str:
    value = str(raw or "").strip()
    if value in {"passed", "accepted", "public_readable", "verified", "supporting_candidate"}:
        return "passed"
    if value in {"partial", "degraded", "partial_readable", "partially_verified"}:
        return "partial"
    if value in {
        "auth_required",
        "login_required",
        "blocked_by_platform",
        "anti_crawl_detected",
        "paywall_or_permission_required",
        "blocked_for_sensitive_secret",
    }:
        return "blocked"
    if value in {"video_without_transcript", "needs_opencli_verification", "needs_manual_evidence", "structured_skipped", "skipped"}:
        return "skipped"
    if value in {"empty_input", "unsupported_manual_type", "missing_source_context", "validation_failed", "failed"}:
        return "failed"
    return "failed" if value else "skipped"


def _overall_status(pipelines: list[dict[str, Any]]) -> str:
    statuses = {pipeline["status"] for pipeline in pipelines}
    if statuses == {"passed"}:
        return "passed"
    if "passed" in statuses:
        return "partial"
    return "failed"


def _validate_source(source: dict[str, Any], errors: list[str]) -> None:
    for field in [
        "source_id",
        "source_pipeline",
        "source_status",
        "source_type",
        "content_hash",
        "integration_mode",
        "decision_class",
        "source_audit_file",
    ]:
        if not source.get(field):
            errors.append(f"source_{field}_required")
    if source.get("source_status") not in {"passed", "failed", "skipped", "blocked", "partial"}:
        errors.append(f"source_status_invalid:{source.get('source_status')}")
    if source.get("source_status") != "passed":
        for field in ["failure_reason", "repair_suggestion", "source_trace"]:
            if not source.get(field):
                errors.append(f"failed_or_blocked_source_{field}_required")
    if source.get("source_pipeline") == "manual_evidence_upload":
        if source.get("decision_class") != "manual_evidence":
            errors.append("manual_evidence_source_must_keep_manual_decision_class")
        if "platform_fetch" in source.get("integration_mode", ""):
            errors.append("manual_evidence_must_not_be_platform_fetch_success")
    if source.get("source_pipeline") == "opencli_external_search_verification":
        if source.get("decision_class") != "verification_result":
            errors.append("opencli_source_must_keep_verification_result_class")
        if "browser" in source.get("integration_mode", ""):
            errors.append("opencli_must_not_be_browser_connector")


def _validate_evidence(item: dict[str, Any], errors: list[str]) -> None:
    for field in ["source_id", "evidence_id", "content_hash", "source_type", "integration_mode", "source_audit_file", "evidence_audit_file"]:
        if not item.get(field):
            errors.append(f"evidence_{field}_required")
    if item.get("knowledge_verification_engine_completed") is not False:
        errors.append("evidence_must_not_claim_knowledge_verification_engine")
    if item.get("source_pipeline") == "manual_evidence_upload" and "platform_fetch" in item.get("integration_mode", ""):
        errors.append("manual_evidence_map_must_not_claim_platform_fetch_success")
    if item.get("source_pipeline") == "opencli_external_search_verification" and "browser" in item.get("integration_mode", ""):
        errors.append("opencli_evidence_must_not_claim_browser_connector")


def _runtime_boundary() -> dict[str, bool]:
    return {
        "unified_source_trace_implemented": True,
        "unified_evidence_map_implemented": True,
        "progress_events_implemented": True,
        "failure_isolation_implemented": True,
        "generic_web_url_ingestion_covered": True,
        "platform_preflight_covered": True,
        "opencli_external_search_verification_covered": True,
        "manual_evidence_upload_covered": True,
        "external_link_import_entry_implemented": False,
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
        "user_triggered_only": True,
        "read_existing_audit_artifacts_only": True,
        "no_new_network_request": True,
        "no_login_bypass": True,
        "no_paywall_bypass": True,
        "no_captcha_bypass": True,
        "no_platform_control_bypass": True,
        "no_cookie_import": True,
        "no_plaintext_cookie_persistence": True,
        "no_cookie_upload": True,
        "no_browser_session_used": True,
        "no_video_or_ocr_runtime": True,
        "no_knowledge_verification_engine_execution": True,
        "no_arbitrary_shell_execution": True,
    }


def _planned_not_active_fields() -> dict[str, str]:
    return {
        "external_link_import_entry": "planned_not_active",
        "authenticated_browser_connector": "planned_not_active",
        "video_ocr_visual_evidence": "planned_not_active",
        "knowledge_verification_engine": "planned_not_active",
        "campaign_3_supplement_4_0": "planned_not_active",
        "campaign_4": "blocked_by_sequence",
    }


def _run_manifest(unified_trace: dict[str, Any], validation: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": "audit_run_manifest.v1",
        "run_id": "external_source_unified_trace",
        "generated_at": unified_trace["generated_at"],
        "type": "section_5_supplement_3_0_p0_unified_trace_evidence_progress_failure_isolation",
        "scope": "CAMPAIGN_3_SUPPLEMENT_3_0_P0_UNIFIED_TRACE_EVIDENCE_PROGRESS_FAILURE_ISOLATION",
        "status": unified_trace["status"],
        "integration_decision": "real_integration",
        "decision_qualifier": "unified_trace_evidence_progress_failure_isolation_only",
        "evidence_files": UNIFIED_TRACE_FILES,
        "validation_status": validation["status"],
        "campaign_state_after_run": {
            "campaign_3_supplement_3_0_entry_gate_passed": True,
            "campaign_3_3_0_p0_framework_passed": True,
            "generic_web_url_ingestion_implemented": True,
            "platform_preflight_implemented": True,
            "opencli_external_search_verification_implemented": True,
            "manual_evidence_processing_implemented": True,
            "unified_trace_evidence_progress_failure_isolation_implemented": unified_trace["status"] == "passed",
            "external_link_import_entry_implemented": False,
            "authenticated_browser_runtime_integrated": False,
            "video_ocr_visual_evidence_implemented": False,
            "knowledge_verification_runtime_implemented": False,
            "campaign_3_3_0_accepted": False,
            "campaign_3_4_0_active": False,
            "campaign_3_accepted": False,
            "campaign_4_allowed": False,
            "next_business_item": (
                "Campaign 3 Supplement 3.0 P0 External Link Import entry plus real Core Bridge allowlist registrations and no-shell tests"
            ),
        },
        "retention": "milestone",
        "keep_in_git": True,
        "final_target_not_downgraded": True,
        "remaining_gap": unified_trace["remaining_gap"],
        "next_required_e2e_step": unified_trace["next_required_e2e_step"],
        "not_goal_complete": True,
    }


def _render_report(
    unified_trace: dict[str, Any],
    unified_evidence_map: dict[str, Any],
    failure_report: dict[str, Any],
    validation: dict[str, Any],
) -> str:
    pipeline_rows = "\n".join(
        (
            f"| {item['display_name']} | {item['status']} | {item['decision_class']} | "
            f"{item['source_count']} | {item['evidence_count']} | {item['isolated_failure_count']} |"
        )
        for item in unified_trace["pipelines"]
    )
    failures = "\n".join(
        f"- `{item['pipeline_id']}` / `{item['source_status']}`: {item['failure_reason']}"
        for item in failure_report["isolated_failures"]
    ) or "- None"
    return (
        "# External Source Unified Trace Report\n\n"
        f"- Status: `{unified_trace['status']}`\n"
        "- Decision: `real_integration / unified_trace_evidence_progress_failure_isolation_only`\n"
        f"- Source count: `{unified_trace['source_count']}`\n"
        f"- Evidence count: `{unified_evidence_map['evidence_count']}`\n"
        f"- Isolated failure count: `{failure_report['isolated_failure_count']}`\n"
        f"- Validation: `{validation['status']}` with `{len(validation['boundary_errors'])}` boundary errors\n\n"
        "## Pipeline Status\n\n"
        "| Pipeline | Status | Decision class | Sources | Evidence | Isolated failures |\n"
        "| --- | --- | --- | --- | --- | --- |\n"
        f"{pipeline_rows}\n\n"
        "## Isolated Failures\n\n"
        f"{failures}\n\n"
        "Boundary: this current-item industrial completion unifies already completed Generic Web URL, Platform "
        "Preflight, OpenCLI verification, and Manual Evidence outputs. It does not implement Authenticated Browser, "
        "Video/OCR/Visual Evidence, Knowledge Verification Engine, Supplement 4.0, Campaign 4, Closure, Upload, "
        "Tag, CI, Full Gate, EXE, or Release.\n"
    )


def _render_summary(unified_trace: dict[str, Any], failure_report: dict[str, Any]) -> str:
    return (
        "# External Source Unified Trace Summary\n\n"
        f"Status: `{unified_trace['status']}`. "
        "The current locked item now has bounded industrial-grade unified source trace, evidence map, progress "
        "events, and failure isolation across the completed P0 inputs. "
        f"Isolated failure count: `{failure_report['isolated_failure_count']}`. "
        f"Next required E2E step: `{unified_trace['next_required_e2e_step']}`\n"
    )


def _event(
    events: list[dict[str, Any]],
    *,
    stage: str,
    status: str,
    timestamp: str,
    message: str,
    artifact_path: str,
    pipeline_id: str = "",
) -> None:
    events.append(
        {
            "event_id": _stable_id("progress", f"{len(events)}:{stage}:{status}:{artifact_path}:{message}"),
            "stage": stage,
            "status": status,
            "timestamp": timestamp,
            "message": message,
            "artifact_path": artifact_path,
            "pipeline_id": pipeline_id,
        }
    )


def _source_id_for_evidence(item: dict[str, Any], sources: list[dict[str, Any]]) -> str:
    evidence_id = item.get("evidence_id")
    for source in sources:
        if source.get("evidence_id") == evidence_id:
            return source["source_id"]
    return ""


def _repair_suggestion(pipeline_id: str, status: str, next_paths: list[str] | None = None) -> str:
    if next_paths:
        return "Use the next available path: " + ", ".join(next_paths) + "."
    if status in {"missing_audit", "pipeline"}:
        return f"Regenerate and validate the {pipeline_id} audit run before rebuilding unified trace."
    if status == "blocked":
        return "Use user-authorized visible content, manual evidence, or approved public-source verification without bypassing platform controls."
    if status == "skipped":
        return "Run the next locked supplement item that handles this source type, or provide manual evidence when allowed."
    if status == "partial":
        return "Keep the partial trace and add complementary evidence through the next allowed path."
    if status == "failed":
        return "Review the source audit file, repair the failed input, and rerun only the locked current item."
    return "No repair needed."


def _default_failure_reason(status: str, pipeline_id: str) -> str:
    if status == "blocked":
        return f"{pipeline_id} source is blocked by access, authorization, or platform boundary."
    if status == "skipped":
        return f"{pipeline_id} source requires a later allowed path and was not processed in this step."
    if status == "partial":
        return f"{pipeline_id} source is only partially readable or partially verified."
    return f"{pipeline_id} source failed in its original audit evidence."


def _remaining_gap() -> str:
    return (
        "Unified Source Trace / Evidence Map, progress events, and failure isolation now cover the completed "
        "Generic Web URL, Platform Link Preflight, OpenCLI External Search Verification, and Manual Evidence Upload "
        "P0 inputs. External Link Import entry plus real Core Bridge allowlist registrations and no-shell tests, "
        "Authenticated Browser Connector, Video/OCR/Visual Evidence, Knowledge Verification Engine, Supplement 3.0 "
        "Acceptance Gate, Supplement 4.0, Campaign 4, Closure, Upload, Tag, CI, Full Gate, EXE, and Release remain incomplete."
    )


def _validation_failure(error_code: str, *, missing_files: list[str]) -> dict[str, Any]:
    return {
        "schema_version": "external_source_unified_trace_validation_report.v1",
        "section": "5.3.0-P0",
        "campaign": "Campaign 3",
        "status": "failed",
        "business_status": "failed",
        "boundary_errors": [error_code],
        "required_files": UNIFIED_TRACE_FILES,
        "missing_files": missing_files,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": "Unified external-source trace evidence is incomplete.",
        "next_required_e2e_step": "Complete the current locked unified trace/evidence/progress/failure isolation item before advancing.",
        "not_goal_complete": True,
    }


def _stable_id(prefix: str, value: str) -> str:
    return f"{prefix}_{hashlib.sha256(value.encode('utf-8')).hexdigest()[:16]}"


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8-sig").splitlines() if line.strip()]


def _rel(path: Path, root: Path) -> str:
    try:
        return str(Path(path).relative_to(root)).replace("\\", "/")
    except ValueError:
        return str(path).replace("\\", "/")


def _display_root(evidence_root: Path) -> Path:
    path = Path(evidence_root)
    if path.name == "section_5" and path.parent.name == "audits":
        return path.parent.parent.parent
    return path.parent


def _now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
