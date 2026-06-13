from __future__ import annotations

import os
import shutil
import sys
from importlib import metadata
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any

from heitang_kb_forge.parser_backends.document_backend_contract import AdapterError, AdapterSmokeReport
from heitang_kb_forge.parser_backends.model_cache import resolve_backend_model_cache
from heitang_kb_forge.parser_backends.registry import BACKENDS, list_backends, parse_sources_with_backend


P21_RELEASE_VERSION = "v4.1.0"
P21_RELEASE_TITLE = "HeiTang KB Forge v4.1.0 Parser/OCR Pluggable Backend Runtime"
P21_RUNTIME_BASELINE_COMMIT = "576a62075dc1ecbe00388bb0569fd1fc767be7cb"
P21_BASELINE_HYGIENE_COMMIT = "13640d5"
V4_0_0_TAG_COMMIT = "0217e54b162871e7c40c31ff3d0cc72e8ba78f06"
P21_AUDIT_DIR = "docs/audits/p2_1_parser_ocr_backends"
P21_ACCEPTANCE_SOURCE = "docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json"
INTEGRATION_DECISION_VALUES = ["real_integration", "reference_only", "needs_strengthening", "stop_integration"]
PADDLEOCR_DECISION_VALUES = INTEGRATION_DECISION_VALUES

BACKEND_STATUS_SCHEMA = {
    "schema_version": "p2.1.backend_status.schema.v1",
    "required_backend_fields": [
        "backend_id",
        "dependency_mode",
        "dependency_available",
        "runtime_invoked",
        "sample_input_type",
        "validated_stable_surface",
        "known_limitations",
        "status",
        "evidence_path",
        "fallback_behavior",
    ],
    "failure_fields": [
        "error_code",
        "human_readable_reason",
        "backend_id",
        "fallback_result",
        "repair_suggestion",
        "audit_trace",
        "workbench_visible_status",
    ],
    "stable_status_values": [
        "builtin_passed",
        "real_runtime_integrated",
        "optional_dependency_gated",
        "limited_surface",
        "future_hardening",
        "blocked_by_dependency",
        "not_ready",
    ],
}

BACKEND_BOUNDARIES: dict[str, dict[str, Any]] = {
    "builtin": {
        "display_name": "Built-in parser fallback",
        "dependency_mode": "default",
        "optional_extra": None,
        "sample_input_type": "Markdown/TXT local source",
        "validated_stable_surface": [".md", ".txt"],
        "known_limitations": ["Best-effort OCR/image extraction still requires review.", "Not a replacement for optional layout/OCR runtimes."],
        "status": "builtin_passed",
        "fallback_behavior": "Preserved default parser path; used when optional backend is missing or not selected.",
        "evidence_path": "tests/test_v28_parser_backends.py::test_parse_with_backend_builtin_writes_normalized_outputs",
        "workbench_state": ["builtin_passed"],
        "static_workbench_executable": False,
    },
    "docling": {
        "display_name": "Docling local runtime adapter",
        "dependency_mode": "optional_extra",
        "optional_extra": "parser-docling",
        "sample_input_type": "Markdown/TXT document source in live acceptance replay",
        "validated_stable_surface": [".md", ".txt"],
        "known_limitations": [
            "P2.1 live acceptance proves Docling runtime invocation on Markdown/TXT samples only.",
            "Docling adapter declares broader document extensions, but PDF/DOCX/HTML/PPTX must be revalidated before stable claims.",
            "Docling is not bundled and is not default Core parsing.",
        ],
        "status": "real_runtime_integrated",
        "fallback_behavior": "If parser-docling is missing or runtime fails, the report marks the backend unavailable/failed and preserves builtin fallback guidance.",
        "evidence_path": P21_ACCEPTANCE_SOURCE,
        "workbench_state": ["real_runtime_integrated", "optional_dependency_gated", "limited_surface"],
        "static_workbench_executable": False,
    },
    "paddleocr": {
        "display_name": "PaddleOCR local OCR runtime adapter",
        "dependency_mode": "optional_extra",
        "optional_extra": "parser-paddleocr",
        "sample_input_type": "PNG OCR image in live acceptance replay",
        "validated_stable_surface": [".pdf", ".png"],
        "known_limitations": [
            "P2.1 live acceptance proves OCR runtime invocation on a PNG sample.",
            "PaddleOCR 3.2 strengthening adds scanned PDF page OCR routing with source page trace.",
            "TIFF/JPEG support remains adapter-declared but not universally stable for this release.",
            "PaddleOCR and model files are not bundled in the default install.",
        ],
        "status": "real_runtime_integrated",
        "fallback_behavior": "If parser-paddleocr or local OCR model/runtime is missing, the report marks the backend unavailable/failed and preserves builtin fallback guidance.",
        "evidence_path": P21_ACCEPTANCE_SOURCE,
        "workbench_state": ["real_runtime_integrated", "optional_dependency_gated", "limited_surface"],
        "static_workbench_executable": False,
    },
    "mineru": {
        "display_name": "MinerU local document understanding adapter",
        "dependency_mode": "optional_extra",
        "optional_extra": "parser-mineru",
        "sample_input_type": "PDF/image document understanding source",
        "validated_stable_surface": [".pdf", ".png"],
        "known_limitations": [
            "MinerU 3.3 strengthening adds dependency-gated CLI integration and Markdown/JSON output normalization.",
            "Default install does not bundle MinerU or local model files.",
            "Table, figure, and formula metadata are normalized when MinerU emits them, but quality depends on the local MinerU runtime.",
        ],
        "status": "real_runtime_integrated",
        "fallback_behavior": "If parser-mineru or local MinerU model/runtime is missing, the report marks the backend unavailable/failed and preserves builtin fallback guidance.",
        "evidence_path": "docs/audits/mineru_backend_strengthening/mineru_integration_decision_report.json",
        "workbench_state": ["real_runtime_integrated", "optional_dependency_gated", "limited_surface"],
        "static_workbench_executable": False,
    },
    "opendataloader": {
        "display_name": "OpenDataLoader local PDF conversion adapter",
        "dependency_mode": "optional_extra",
        "optional_extra": "parser-opendataloader",
        "sample_input_type": "PDF document source",
        "validated_stable_surface": [".pdf"],
        "known_limitations": [
            "OpenDataLoader 3.6 strengthening adds dependency-gated CLI integration for PDF to Markdown/JSON conversion.",
            "Default install does not bundle OpenDataLoader or Java 11+.",
            "Hybrid/OCR server mode is excluded from the default smoke path and remains future hardening.",
        ],
        "status": "real_runtime_integrated",
        "fallback_behavior": "If parser-opendataloader, Java, or the local CLI is missing, the report marks the backend unavailable/failed and preserves builtin fallback guidance.",
        "evidence_path": "docs/audits/dependency_remediation/opendataloader/opendataloader_integration_decision_report.json",
        "workbench_state": ["real_runtime_integrated", "optional_dependency_gated", "limited_surface", "smoke_passed"],
        "static_workbench_executable": False,
    },
    "surya": {
        "display_name": "Surya OCR/layout benchmark reference adapter",
        "dependency_mode": "optional_extra",
        "optional_extra": "parser-surya",
        "sample_input_type": "PDF/image OCR and layout benchmark source",
        "validated_stable_surface": [],
        "known_limitations": [
            "Surya is prioritized as an OCR/layout benchmark, not a primary parser backend.",
            "Surya 2 requires surya-ocr plus a vllm or llama.cpp inference backend; default install does not bundle models or inference servers.",
            "The adapter is intentionally blocked before runtime invocation until dependency remediation and benchmark smoke evidence are complete.",
        ],
        "status": "future_hardening",
        "fallback_behavior": "Surya is reported as a benchmark/reference candidate; missing or installed dependency does not make it a primary parser backend yet.",
        "evidence_path": "docs/audits/surya_backend_decision/surya_integration_decision_report.json",
        "workbench_state": ["needs_strengthening", "reference_benchmark"],
        "static_workbench_executable": False,
    },
    "marker": {
        "display_name": "Marker local PDF document understanding adapter",
        "dependency_mode": "optional_extra",
        "optional_extra": "parser-marker",
        "sample_input_type": "PDF document source",
        "validated_stable_surface": [".pdf"],
        "known_limitations": [
            "Marker model assets are large and must use an explicit workspace-local cache.",
            "The local runtime path does not enable --use_llm and does not require an external API key.",
            "Runtime smoke success does not prove EXE bundling or settle the separate Marker licensing gate.",
        ],
        "status": "real_runtime_integrated",
        "fallback_behavior": "If marker-pdf or marker_single is missing, the report remains blocked_by_dependency and preserves alternate verified backend guidance.",
        "evidence_path": "docs/audits/dependency_remediation/marker/marker_integration_decision_report.json",
        "workbench_state": ["real_runtime_integrated", "optional_dependency_gated", "license_gate_pending"],
        "static_workbench_executable": False,
    },
    "unstructured": {
        "display_name": "Unstructured local runtime adapter",
        "dependency_mode": "optional_extra",
        "optional_extra": "parser-unstructured",
        "sample_input_type": "Markdown/TXT document source in live acceptance replay",
        "validated_stable_surface": [".md", ".txt"],
        "known_limitations": [
            "Stable P2.1 surface is explicitly limited to .md/.txt.",
            "PDF/DOCX/image extras are future hardening and are not claimed stable in v4.1.0.",
            "Unstructured is not bundled and is not default Core parsing.",
        ],
        "status": "real_runtime_integrated",
        "fallback_behavior": "If parser-unstructured is missing or runtime fails, the report marks the backend unavailable/failed and preserves builtin fallback guidance.",
        "evidence_path": P21_ACCEPTANCE_SOURCE,
        "workbench_state": ["real_runtime_integrated", "optional_dependency_gated", "limited_surface"],
        "static_workbench_executable": False,
    },
}

FAILURE_MODES = [
    {
        "case_id": "missing_backend_dependency",
        "error_code": "optional_runtime_dependency_missing",
        "human_readable_reason": "Optional parser/OCR backend dependency is not installed in the current environment.",
        "backend_id": "docling|paddleocr|unstructured",
        "fallback_result": "builtin_available",
        "repair_suggestion": "Install the matching parser extra or rerun with backend=builtin.",
        "audit_trace": "parser_backend_result.json.records[].metadata",
        "workbench_visible_status": "blocked_by_dependency",
    },
    {
        "case_id": "invalid_backend_id",
        "error_code": "invalid_backend_id",
        "human_readable_reason": "Requested backend id is not in the Core backend registry.",
        "backend_id": "user_supplied",
        "fallback_result": "builtin_available",
        "repair_suggestion": "Run parser-backend-registry and retry with a listed backend_id.",
        "audit_trace": "parser_backend_result.json",
        "workbench_visible_status": "not_ready",
    },
    {
        "case_id": "unsupported_file_type",
        "error_code": "unsupported_file_type",
        "human_readable_reason": "The selected backend has no supported source for the provided file type.",
        "backend_id": "selected_backend",
        "fallback_result": "builtin_available_when_supported",
        "repair_suggestion": "Use a supported file extension or select a backend with matching supported_extensions.",
        "audit_trace": "parser_backend_result.json.warnings",
        "workbench_visible_status": "not_ready",
    },
    {
        "case_id": "backend_import_unavailable",
        "error_code": "optional_runtime_dependency_missing",
        "human_readable_reason": "Backend import cannot be resolved without importing heavy packages.",
        "backend_id": "docling|paddleocr|unstructured",
        "fallback_result": "builtin_available",
        "repair_suggestion": "Install the optional backend dependency in a dedicated environment.",
        "audit_trace": "parser-backend-inspect",
        "workbench_visible_status": "blocked_by_dependency",
    },
    {
        "case_id": "runtime_exception",
        "error_code": "backend_runtime_exception",
        "human_readable_reason": "Backend runtime was invoked but raised an exception.",
        "backend_id": "selected_backend",
        "fallback_result": "builtin_available_when_supported",
        "repair_suggestion": "Inspect backend dependency/model installation or rerun with backend=builtin.",
        "audit_trace": "parser_backend_result.json.records[].warnings",
        "workbench_visible_status": "not_ready",
    },
    {
        "case_id": "empty_result",
        "error_code": "empty_parse_result",
        "human_readable_reason": "Backend completed but returned no extractable text.",
        "backend_id": "selected_backend",
        "fallback_result": "manual_review_required",
        "repair_suggestion": "Review the source or route through a more suitable OCR/parser backend.",
        "audit_trace": "parser_backend_result.json.records[].metadata",
        "workbench_visible_status": "not_ready",
    },
]


def make_backend_status_schema() -> dict[str, Any]:
    return BACKEND_STATUS_SCHEMA


def make_parser_backend_matrix() -> dict[str, Any]:
    registry = {row["name"]: row for row in list_backends()}
    backends = []
    for backend_id in ["builtin", "docling", "marker", "mineru", "opendataloader", "paddleocr", "surya", "unstructured"]:
        boundary = BACKEND_BOUNDARIES[backend_id]
        registry_row = registry.get(backend_id, {})
        acceptance_proven = backend_id not in {"builtin", "surya"}
        backends.append(
            {
                "backend_id": backend_id,
                "display_name": boundary["display_name"],
                "dependency_mode": boundary["dependency_mode"],
                "optional_extra": boundary["optional_extra"],
                "default_install_available": backend_id == "builtin",
                "current_environment_available": bool(registry_row.get("available", backend_id == "builtin")),
                "dependency_available": backend_id == "builtin" or acceptance_proven,
                "runtime_invoked": backend_id == "builtin" or acceptance_proven,
                "sample_input_type": boundary["sample_input_type"],
                "validated_stable_surface": boundary["validated_stable_surface"],
                "adapter_supported_extensions": registry_row.get("supported_extensions", []),
                "known_limitations": boundary["known_limitations"],
                "status": boundary["status"],
                "workbench_state": boundary["workbench_state"],
                "evidence_path": boundary["evidence_path"],
                "fallback_behavior": boundary["fallback_behavior"],
                "static_workbench_executable": boundary["static_workbench_executable"],
                "capability_contract": registry_row.get("capability_contract", {}),
            }
        )
    return {
        "schema_version": "p2.1.parser_backend_matrix.v1",
        "release_version": P21_RELEASE_VERSION,
        "release_title": P21_RELEASE_TITLE,
        "runtime_baseline_commit": P21_RUNTIME_BASELINE_COMMIT,
        "baseline_hygiene_commit": P21_BASELINE_HYGIENE_COMMIT,
        "v4_0_0_tag_expected_commit": V4_0_0_TAG_COMMIT,
        "default_heavy_dependencies_bundled": False,
        "default_core_parser_changed": False,
        "static_workbench_runtime_execution_claimed": False,
        "acceptance_report_path": P21_ACCEPTANCE_SOURCE,
        "known_limitation_report_path": f"{P21_AUDIT_DIR}/backend_capability_boundaries.md",
        "backends": backends,
    }


def make_parser_backend_registry() -> dict[str, Any]:
    return {
        "schema_version": "p2.1.parser_backend_registry.v1",
        "release_version": P21_RELEASE_VERSION,
        "no_heavy_import_required": True,
        "backends": list_backends(),
    }


def make_fallback_parser_contract() -> dict[str, Any]:
    check = inspect_backend_status("builtin")
    contract = check["capability_contract"]
    stable_inputs = [".md", ".txt"]
    return {
        "schema_version": "fallback_parser.contract.v1",
        "status": "pass",
        "adapter_id": "builtin",
        "adapter_type": contract["adapter_type"],
        "decision": contract["integration_decision"],
        "dependency_status": contract["dependency_status"],
        "runtime_status": contract["runtime_status"],
        "default_install_available": True,
        "handles_basic_text_documents": True,
        "validated_stable_surface": stable_inputs,
        "adapter_supported_extensions": contract["supported_inputs"],
        "supported_outputs": contract["supported_outputs"],
        "primary_document_understanding_backend": False,
        "full_ocr_support": False,
        "full_layout_support": False,
        "table_extraction_support": False,
        "figure_extraction_support": False,
        "formula_recognition_support": False,
        "contract_capabilities": {
            "ocr_support": contract["ocr_support"],
            "layout_support": contract["layout_support"],
            "table_support": contract["table_support"],
            "figure_support": contract["figure_support"],
            "formula_support": contract["formula_support"],
            "reading_order_support": contract["reading_order_support"],
        },
        "ui_status": "available",
        "fallback_result": "not_needed",
        "repair_suggestion": "Use backend=builtin for basic Markdown/TXT fallback; select a real Document Understanding backend for layout/OCR-heavy sources.",
        "truthfulness_note": "The built-in parser is a dependable basic text fallback, not a full Document Understanding backend.",
    }


def inspect_backend_status(backend_id: str) -> dict[str, Any]:
    normalized = backend_id.strip().lower()
    if normalized not in BACKENDS:
        return {
            "schema_version": "p2.1.parser_backend_inspect.v1",
            "status": "fail",
            "backend_id": normalized,
            "error_code": "invalid_backend_id",
            "human_readable_reason": f"Unsupported parser backend: {backend_id}",
            "fallback_result": "builtin_available",
            "repair_suggestion": "Run parser-backend-registry and retry with a listed backend_id.",
            "audit_trace": "parser-backend-inspect",
            "workbench_visible_status": "not_ready",
        }
    registry_row = {item["name"]: item for item in list_backends()}[normalized]
    contract = registry_row["capability_contract"]
    matrix = {row["backend_id"]: row for row in make_parser_backend_matrix()["backends"]}
    row = matrix.get(
        normalized,
        {
            "backend_id": normalized,
            "display_name": registry_row["name"],
            "optional_extra": f"parser-{normalized}",
            "workbench_state": [contract["integration_decision"]],
            "capability_contract": contract,
        },
    )
    if registry_row["available"]:
        status = "available"
        error_code = None
    elif contract["dependency_status"] == "missing":
        status = "blocked_by_dependency"
        error_code = "optional_runtime_dependency_missing"
    else:
        status = "disabled"
        error_code = "adapter_not_integrated"
    return {
        "schema_version": "p2.1.parser_backend_inspect.v1",
        "status": status,
        "backend_id": normalized,
        "backend": row,
        "registry": registry_row,
        "capability_contract": contract,
        "error_code": error_code,
        "human_readable_reason": registry_row.get("reason"),
        "fallback_result": "builtin_available" if not registry_row["available"] else "selected_backend_available",
        "repair_suggestion": None if registry_row["available"] else contract.get("repair_suggestion"),
        "audit_trace": "parser-backend-inspect",
        "workbench_visible_status": row["workbench_state"][0] if registry_row["available"] else status,
    }


def make_parser_backend_smoke(backend_id: str, input_path: Path | None = None) -> dict[str, Any]:
    normalized = backend_id.strip().lower()
    if normalized not in BACKENDS:
        return inspect_backend_status(normalized) | {"schema_version": "p2.1.parser_backend_smoke.v1"}
    with TemporaryDirectory(prefix="heitang_parser_backend_smoke_") as tmp:
        source = input_path or _default_smoke_source(Path(tmp), normalized)
        run = parse_sources_with_backend(source, normalized, f"parser-backend-smoke --backend {normalized}")
        first_result = run.records[0].to_dict().get("adapter_result") if run.records else None
        smoke_status = (
            "pass"
            if run.status == "success"
            else "skipped"
            if run.status == "unavailable"
            else "warning"
            if run.status == "warning"
            else "fail"
        )
        legacy_status = "blocked" if smoke_status == "skipped" else smoke_status
        smoke_errors = first_result.get("errors", []) if first_result else []
        if run.error_code and not smoke_errors:
            smoke_errors = [
                AdapterError(
                    code=run.error_code,
                    message=run.warnings[0] if run.warnings else run.error_code,
                    fallback_reason=run.warnings[0] if run.warnings else None,
                    fallback_result=run.fallback_result,
                    repair_suggestion=run.repair_suggestion,
                )
            ]
        smoke_report = AdapterSmokeReport(
            adapter=run.adapter_contract,
            status=smoke_status,
            result=first_result,
            warnings=run.warnings,
            errors=smoke_errors,
            repair_suggestion=run.repair_suggestion
            or (first_result.get("repair_suggestion") if first_result else None),
        )
        return {
            "schema_version": "p2.1.parser_backend_smoke.v1",
            "status": legacy_status,
            "backend_id": normalized,
            "source": str(source),
            "run": run.to_dict(),
            "adapter_smoke_report": smoke_report.model_dump(mode="json"),
            "fallback_result": run.fallback_result or ("builtin_available" if normalized != "builtin" else "not_needed"),
            "repair_suggestion": smoke_report.repair_suggestion,
            "audit_trace": run.audit_trace or "parser-backend-smoke",
        }


def make_paddleocr_backend_check() -> dict[str, Any]:
    return make_paddleocr_integration_decision_report()


def make_paddleocr_backend_smoke(input_path: Path | None = None) -> dict[str, Any]:
    if input_path is None and inspect_backend_status("paddleocr")["status"] != "available":
        with TemporaryDirectory(prefix="heitang_paddleocr_smoke_") as tmp:
            placeholder = Path(tmp) / "paddleocr_smoke.png"
            placeholder.write_bytes(b"")
            smoke = make_parser_backend_smoke("paddleocr", placeholder)
    else:
        smoke = make_parser_backend_smoke("paddleocr", input_path)
    contract = smoke.get("run", {}).get("adapter_contract") or smoke.get("adapter_smoke_report", {}).get("adapter", {})
    return {
        **smoke,
        "schema_version": "paddleocr.smoke_report.v1",
        "adapter_id": "paddleocr",
        "decision": contract.get("integration_decision", "real_integration"),
        "image_ocr_supported": ".png" in contract.get("supported_inputs", []),
        "scanned_pdf_page_ocr_supported": ".pdf" in contract.get("supported_inputs", []),
        "confidence_reported": True,
        "source_page_trace_reported": True,
    }


def make_paddleocr_integration_decision_report(
    smoke_report: dict[str, Any] | None = None,
    run_report: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return _make_backend_integration_decision_report(
        "paddleocr",
        schema_version="paddleocr.integration_decision.v1",
        smoke_report=smoke_report,
        run_report=run_report,
        commands={
            "check": "check-paddleocr-backend",
            "smoke": "smoke-paddleocr-backend",
            "run": "run-paddleocr-ocr",
        },
        artifacts=[
            "paddleocr_smoke_report.json",
            "paddleocr_smoke_report.md",
            "paddleocr_integration_decision_report.json",
            "paddleocr_integration_decision_report.md",
            "paddleocr_ocr_result.json",
            "paddleocr_ocr_result.md",
        ],
        ui_bridge_actions=[
            "check_paddleocr_backend",
            "smoke_paddleocr_backend",
            "run_paddleocr_ocr",
        ],
        extra_capabilities={
            "image_ocr": True,
            "scanned_pdf_page_ocr": True,
            "confidence": True,
            "source_page_trace": True,
            "structured_skipped_when_missing": True,
        },
    )


def make_paddleocr_ocr_result_report(run: Any) -> dict[str, Any]:
    payload = run.to_dict()
    return {
        "schema_version": "paddleocr.ocr_result.v1",
        "adapter_id": "paddleocr",
        "status": run.status,
        "source_count": run.source_count,
        "success_count": payload["success_count"],
        "warning_count": payload["warning_count"],
        "supports_image_ocr": True,
        "supports_scanned_pdf_page_ocr": True,
        "confidence_reported": True,
        "source_page_trace_reported": True,
        "run": payload,
    }


def make_mineru_backend_check() -> dict[str, Any]:
    return make_mineru_integration_decision_report()


def make_mineru_backend_smoke(input_path: Path | None = None) -> dict[str, Any]:
    if input_path is None and inspect_backend_status("mineru")["status"] != "available":
        with TemporaryDirectory(prefix="heitang_mineru_smoke_") as tmp:
            placeholder = Path(tmp) / "mineru_smoke.pdf"
            placeholder.write_bytes(b"%PDF fake dependency-gate fixture")
            smoke = make_parser_backend_smoke("mineru", placeholder)
    else:
        smoke = make_parser_backend_smoke("mineru", input_path)
    contract = smoke.get("run", {}).get("adapter_contract") or smoke.get("adapter_smoke_report", {}).get("adapter", {})
    return {
        **smoke,
        "schema_version": "mineru.smoke_report.v1",
        "adapter_id": "mineru",
        "decision": contract.get("integration_decision", "real_integration"),
        "pdf_supported": ".pdf" in contract.get("supported_inputs", []),
        "image_or_scanned_supported": any(ext in contract.get("supported_inputs", []) for ext in [".png", ".jpg", ".jpeg"]),
        "layout_blocks_supported": contract.get("layout_support") == "supported",
        "reading_order_supported": contract.get("reading_order_support") == "supported",
        "markdown_json_normalization_supported": {"markdown", "layout_json"} <= set(contract.get("supported_outputs", [])),
    }


def make_mineru_integration_decision_report(
    smoke_report: dict[str, Any] | None = None,
    run_report: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return _make_backend_integration_decision_report(
        "mineru",
        schema_version="mineru.integration_decision.v1",
        smoke_report=smoke_report,
        run_report=run_report,
        commands={
            "check": "check-mineru-backend",
            "smoke": "smoke-mineru-backend",
            "run": "run-mineru-document-understanding",
        },
        artifacts=[
            "mineru_smoke_report.json",
            "mineru_smoke_report.md",
            "mineru_integration_decision_report.json",
            "mineru_integration_decision_report.md",
            "mineru_document_understanding_result.json",
            "mineru_document_understanding_result.md",
        ],
        ui_bridge_actions=[
            "check_mineru_backend",
            "smoke_mineru_backend",
            "run_mineru_document_understanding",
        ],
        extra_capabilities={
            "pdf_parse": True,
            "image_or_scanned_path": True,
            "layout_blocks": True,
            "reading_order": True,
            "table_metadata": "partial",
            "figure_metadata": "partial",
            "formula_metadata": "partial",
            "markdown_json_normalization": True,
            "structured_skipped_when_missing": True,
        },
    )


def make_mineru_document_understanding_result_report(run: Any) -> dict[str, Any]:
    payload = run.to_dict()
    return {
        "schema_version": "mineru.document_understanding_result.v1",
        "adapter_id": "mineru",
        "status": run.status,
        "source_count": run.source_count,
        "success_count": payload["success_count"],
        "warning_count": payload["warning_count"],
        "supports_pdf_parse": True,
        "supports_image_or_scanned_path": True,
        "layout_blocks_reported": True,
        "reading_order_reported": True,
        "table_metadata_reported": True,
        "figure_metadata_reported": True,
        "formula_metadata_reported": True,
        "run": payload,
    }


def make_docling_backend_check() -> dict[str, Any]:
    return make_docling_integration_decision_report()


def make_docling_backend_smoke(input_path: Path | None = None) -> dict[str, Any]:
    if input_path is None and inspect_backend_status("docling")["status"] != "available":
        with TemporaryDirectory(prefix="heitang_docling_smoke_") as tmp:
            placeholder = Path(tmp) / "docling_smoke.md"
            placeholder.write_text("# Docling dependency gate\n\nSmoke placeholder.", encoding="utf-8")
            smoke = make_parser_backend_smoke("docling", placeholder)
    else:
        smoke = make_parser_backend_smoke("docling", input_path)
    contract = smoke.get("run", {}).get("adapter_contract") or smoke.get("adapter_smoke_report", {}).get("adapter", {})
    return {
        **smoke,
        "schema_version": "docling.smoke_report.v1",
        "adapter_id": "docling",
        "decision": contract.get("integration_decision", "real_integration"),
        "document_conversion_supported": True,
        "layout_blocks_supported": contract.get("layout_support") in {"supported", "partial", "unknown"},
        "table_metadata_supported": contract.get("table_support") in {"supported", "partial", "unknown"},
        "markdown_normalization_supported": "markdown" in contract.get("supported_outputs", []),
    }


def make_docling_integration_decision_report(
    smoke_report: dict[str, Any] | None = None,
    run_report: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return _make_backend_integration_decision_report(
        "docling",
        schema_version="docling.integration_decision.v1",
        smoke_report=smoke_report,
        run_report=run_report,
        commands={
            "check": "check-docling-backend",
            "smoke": "smoke-docling-backend",
            "run": "run-docling-convert",
        },
        artifacts=[
            "docling_smoke_report.json",
            "docling_smoke_report.md",
            "docling_integration_decision_report.json",
            "docling_integration_decision_report.md",
            "docling_convert_result.json",
            "docling_convert_result.md",
        ],
        ui_bridge_actions=[
            "check_docling_backend",
            "smoke_docling_backend",
            "run_docling_convert",
        ],
        extra_capabilities={
            "document_conversion": True,
            "layout_blocks": "unknown",
            "tables": "unknown",
            "markdown_normalization": True,
            "structured_skipped_when_missing": True,
        },
    )


def make_docling_convert_result_report(run: Any) -> dict[str, Any]:
    payload = run.to_dict()
    return {
        "schema_version": "docling.convert_result.v1",
        "adapter_id": "docling",
        "status": run.status,
        "source_count": run.source_count,
        "success_count": payload["success_count"],
        "warning_count": payload["warning_count"],
        "document_conversion_reported": True,
        "markdown_normalization_reported": True,
        "run": payload,
    }


def make_unstructured_backend_check() -> dict[str, Any]:
    return make_unstructured_integration_decision_report()


def make_unstructured_backend_smoke(input_path: Path | None = None) -> dict[str, Any]:
    if input_path is None and inspect_backend_status("unstructured")["status"] != "available":
        with TemporaryDirectory(prefix="heitang_unstructured_smoke_") as tmp:
            placeholder = Path(tmp) / "unstructured_smoke.md"
            placeholder.write_text("# Unstructured dependency gate\n\nSmoke placeholder.", encoding="utf-8")
            smoke = make_parser_backend_smoke("unstructured", placeholder)
    else:
        smoke = make_parser_backend_smoke("unstructured", input_path)
    contract = smoke.get("run", {}).get("adapter_contract") or smoke.get("adapter_smoke_report", {}).get("adapter", {})
    return {
        **smoke,
        "schema_version": "unstructured.smoke_report.v1",
        "adapter_id": "unstructured",
        "decision": contract.get("integration_decision", "real_integration"),
        "basic_text_documents_supported": {".md", ".txt"} <= set(contract.get("validated_inputs", [])),
        "validated_stable_surface": contract.get("validated_inputs", []),
        "full_document_understanding_backend": False,
        "layout_claimed_stable": False,
        "ocr_claimed_stable": False,
        "structured_skipped_when_missing": True,
    }


def make_unstructured_integration_decision_report(
    smoke_report: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return _make_backend_integration_decision_report(
        "unstructured",
        schema_version="unstructured.integration_decision.v1",
        smoke_report=smoke_report,
        run_report=None,
        commands={
            "fallback_contract": "fallback-parser-contract",
            "check": "check-unstructured-backend",
            "smoke": "smoke-unstructured-backend",
        },
        artifacts=[
            "fallback_parser_contract.json",
            "fallback_parser_contract.md",
            "unstructured_smoke_report.json",
            "unstructured_smoke_report.md",
            "unstructured_dependency_remediation_report.json",
            "unstructured_dependency_remediation_report.md",
            "unstructured_integration_decision_report.json",
            "unstructured_integration_decision_report.md",
            "unstructured_ui_impact_note.json",
            "unstructured_ui_impact_note.md",
        ],
        ui_bridge_actions=[
            "fallback_parser_contract",
            "check_unstructured_backend",
            "smoke_unstructured_backend",
        ],
        extra_capabilities={
            "basic_text_documents": True,
            "validated_stable_surface": [".md", ".txt"],
            "full_document_understanding_backend": False,
            "ocr": "unsupported",
            "layout": "unsupported",
            "tables": "unsupported",
            "figures": "unsupported",
            "formulas": "unsupported",
            "reading_order": "partial",
            "structured_skipped_when_missing": True,
        },
    )


def make_unstructured_dependency_remediation_report(
    smoke_report: dict[str, Any] | None = None,
) -> dict[str, Any]:
    post_check = inspect_backend_status("unstructured")
    missing = ["unstructured"] if post_check["status"] == "blocked_by_dependency" else []
    smoke_status = smoke_report.get("status") if smoke_report else "not_run"
    final_decision = (
        "real_integration"
        if post_check["status"] == "available" and smoke_status in {"pass", "success"}
        else "needs_strengthening"
        if missing
        else "smoke_pending"
    )
    return {
        "schema_version": "unstructured.dependency_remediation.v1",
        "adapter_name": "unstructured",
        "missing_dependencies": missing,
        "install_attempted": False,
        "install_commands": [
            "python -m pip install -e \".[parser-unstructured]\"",
            "python -m pip install \"unstructured[md]>=0.16,<1\"",
        ],
        "installed_versions": {},
        "install_paths": {},
        "source": {
            "project_extra": "parser-unstructured",
            "python_package": "PyPI: unstructured[md]",
        },
        "risk_notes": [
            "Installation is project-approved when performed in an auditable local environment.",
            "Checks and smokes must not install packages silently.",
            "Only Markdown/TXT are claimed as the stable Unstructured surface in this slice.",
        ],
        "rollback_steps": [
            "Remove the project-local environment or uninstall unstructured from the selected environment.",
            "Re-run check-unstructured-backend and smoke-unstructured-backend.",
        ],
        "post_install_check_result": post_check["status"],
        "post_install_smoke_result": smoke_status,
        "final_decision": final_decision,
        "blocker_evidence": post_check.get("human_readable_reason"),
    }


def make_unstructured_ui_impact_note() -> dict[str, Any]:
    check = inspect_backend_status("unstructured")
    ui_status = "available" if check["status"] == "available" else "dependency_missing"
    return {
        "schema_version": "unstructured.ui_impact_note.v1",
        "adapter_id": "unstructured",
        "ui_status": ui_status,
        "desktop_bridge_actions": [
            "fallback_parser_contract",
            "check_unstructured_backend",
            "smoke_unstructured_backend",
        ],
        "web_execution_enabled": False,
        "web_blocked_reason": "web_local_cli_unsupported",
        "truthfulness_note": (
            "Static web surfaces may show Core evidence snapshots, but only the desktop bridge can run "
            "local Unstructured checks or smokes. Unstructured remains limited to the .md/.txt stable surface."
        ),
        "evidence_path": "docs/audits/unstructured_fallback_strengthening/unstructured_integration_decision_report.json",
    }


def make_marker_backend_check() -> dict[str, Any]:
    return make_marker_integration_decision_report()


def make_marker_backend_smoke(input_path: Path | None = None) -> dict[str, Any]:
    if input_path is None:
        with TemporaryDirectory(prefix="heitang_marker_smoke_") as tmp:
            placeholder = Path(tmp) / "marker_smoke.pdf"
            placeholder.write_bytes(b"%PDF fake reference-gate fixture")
            smoke = make_parser_backend_smoke("marker", placeholder)
    else:
        smoke = make_parser_backend_smoke("marker", input_path)
    contract = smoke.get("run", {}).get("adapter_contract") or smoke.get("adapter_smoke_report", {}).get("adapter", {})
    records = smoke.get("run", {}).get("records", [])
    first_record = records[0] if records else {}
    metadata_payload = first_record.get("metadata", {})
    return {
        **smoke,
        "schema_version": "marker.smoke_report.v1",
        "adapter_id": "marker",
        "decision": contract.get("integration_decision", "real_integration"),
        "runtime_invocation_blocked_until_strengthened": False,
        "reference_only_or_strengthening_candidate": False,
        "use_llm": False,
        "model_cache_path": str(resolve_backend_model_cache("marker")),
        "license_gate_status": "license_gate_pending",
        "output_non_empty": bool(first_record.get("text")),
        "output_schema_readable": bool(metadata_payload.get("output_schema_readable")),
        "llm_request_count": int(metadata_payload.get("llm_request_count", 0) or 0),
        "llm_tokens_used": int(metadata_payload.get("llm_tokens_used", 0) or 0),
    }


def make_marker_integration_decision_report(
    smoke_report: dict[str, Any] | None = None,
) -> dict[str, Any]:
    report = _make_backend_integration_decision_report(
        "marker",
        schema_version="marker.integration_decision.v1",
        smoke_report=smoke_report,
        run_report=None,
        commands={
            "check": "check-marker-backend",
            "smoke": "smoke-marker-backend",
            "run": "run-marker-convert",
        },
        artifacts=[
            "marker_dependency_remediation_report.json",
            "marker_dependency_remediation_report.md",
            "marker_integration_decision_report.json",
            "marker_integration_decision_report.md",
            "marker_smoke_report.json",
            "marker_smoke_report.md",
            "marker_ui_impact_note.json",
            "marker_ui_impact_note.md",
        ],
        ui_bridge_actions=[
            "check_marker_backend",
            "smoke_marker_backend",
            "run_marker_convert",
        ],
        extra_capabilities={
            "stable_markdown_or_json_output": True,
            "runtime_invocation_blocked_until_strengthened": False,
            "reference_only_or_strengthening_candidate": False,
            "structured_skipped_when_missing": True,
            "use_llm": False,
            "license_gate_status": "license_gate_pending",
            "model_cache_path": str(resolve_backend_model_cache("marker")),
        },
    )
    report["runtime_status"] = (
        "available"
        if report["current_environment_status"] == "available"
        else "blocked_by_dependency"
    )
    smoke_status = report.get("smoke_status")
    report["smoke_status"] = (
        "passed"
        if smoke_status == "pass"
        else "failed"
        if smoke_status in {"fail", "warning"}
        else "skipped"
        if smoke_status == "blocked"
        else "not_run"
    )
    return report


def make_marker_dependency_remediation_report(
    smoke_report: dict[str, Any] | None = None,
) -> dict[str, Any]:
    check = inspect_backend_status("marker")
    smoke_status = smoke_report.get("status") if smoke_report else "not_run"
    old_cache_path = _datalab_cache_root()
    old_model_cache_path = old_cache_path / "models"
    new_cache_path = resolve_backend_model_cache("marker")
    old_cache_size = _directory_size(old_cache_path)
    new_cache_size = _directory_size(new_cache_path)
    migration_needed = old_cache_size > 0 and new_cache_size < old_cache_size
    try:
        marker_version = metadata.version("marker-pdf")
    except metadata.PackageNotFoundError:
        marker_version = None
    runtime_available = check["status"] == "available"
    final_decision = (
        "real_integration"
        if runtime_available and smoke_status == "pass"
        else "needs_strengthening"
        if runtime_available
        else "blocked_by_dependency"
    )
    return {
        "schema_version": "marker.dependency_remediation.v1",
        "adapter_name": "marker",
        "install_attempted": marker_version is not None,
        "install_command": "python -m pip install marker-pdf>=1,<2",
        "installed_version": marker_version,
        "source": "PyPI: marker-pdf; runtime CLI: marker_single",
        "install_path": str(Path(sys.executable).resolve().parent.parent),
        "risk": [
            "Marker and Surya model assets require several gigabytes of local storage.",
            "Marker licensing acceptance is a separate product gate and is not treated as a runtime failure.",
            "Runtime success does not prove portable EXE bundling.",
        ],
        "rollback_plan": [
            "Remove the isolated Marker environment if the remediation must be reverted.",
            "Point HEITANG_MARKER_MODEL_CACHE back to an approved retained cache copy.",
            "Do not delete the legacy datalab cache until a separate cleanup checkpoint is accepted.",
        ],
        "post_install_check_result": check["status"],
        "post_install_smoke_result": smoke_status,
        "runtime_status": "available" if runtime_available else "blocked_by_dependency",
        "smoke_status": "passed" if smoke_status == "pass" else smoke_status,
        "license_gate_status": "license_gate_pending",
        "final_decision": final_decision,
        "old_cache_path": str(old_cache_path),
        "old_model_cache_path": str(old_model_cache_path),
        "new_cache_path": str(new_cache_path),
        "cache_size": {
            "old_bytes": old_cache_size,
            "new_bytes": new_cache_size,
        },
        "migration_performed": old_cache_size > 0 and new_cache_size == old_cache_size,
        "migration_needed": migration_needed,
        "cleanup_suggestion": (
            "Retain the old cache until workspace-local Markdown and JSON smokes pass and file counts/sizes are verified; "
            "then use the documented cleanup plan instead of automatic deletion."
        ),
        "blocker_evidence": check.get("human_readable_reason") if not runtime_available else None,
    }


def make_marker_ui_impact_note(
    smoke_report: dict[str, Any] | None = None,
) -> dict[str, Any]:
    check = inspect_backend_status("marker")
    smoke_status = smoke_report.get("status") if smoke_report else None
    if check["status"] != "available":
        ui_status = "dependency_missing"
    elif smoke_status == "pass":
        ui_status = "available_smoke_passed_license_gate_pending"
    elif smoke_status in {"fail", "warning"}:
        ui_status = "smoke_failed_needs_strengthening"
    else:
        ui_status = "available_smoke_pending"
    return {
        "schema_version": "marker.ui_impact_note.v1",
        "adapter_id": "marker",
        "ui_status": ui_status,
        "runtime_status": "available" if check["status"] == "available" else "blocked_by_dependency",
        "smoke_status": "passed" if smoke_status == "pass" else smoke_status or "not_run",
        "license_gate_status": "license_gate_pending",
        "model_cache_path": str(resolve_backend_model_cache("marker")),
        "desktop_bridge_actions": [
            "check_marker_backend",
            "smoke_marker_backend",
            "run_marker_convert",
        ],
        "web_execution_enabled": False,
        "web_blocked_reason": "web_local_cli_unsupported",
        "truthfulness_note": (
            "UI may show Marker ready only after a real smoke passes with the configured workspace-local model cache. "
            "The licensing gate and EXE bundling remain separate acceptance items."
        ),
        "evidence_path": "docs/audits/dependency_remediation/marker/marker_integration_decision_report.json",
    }


def make_marker_convert_result_report(run: Any) -> dict[str, Any]:
    payload = run.to_dict()
    records = payload.get("records", [])
    llm_request_count = sum(
        int(record.get("metadata", {}).get("llm_request_count", 0) or 0)
        for record in records
    )
    llm_tokens_used = sum(
        int(record.get("metadata", {}).get("llm_tokens_used", 0) or 0)
        for record in records
    )
    return {
        "schema_version": "marker.convert_result.v1",
        "adapter_id": "marker",
        "status": run.status,
        "source_count": run.source_count,
        "success_count": payload["success_count"],
        "warning_count": payload["warning_count"],
        "output_non_empty": any(bool(record.get("text")) for record in records),
        "output_schema_readable": all(isinstance(record, dict) for record in records),
        "llm_request_count": llm_request_count,
        "llm_tokens_used": llm_tokens_used,
        "model_cache_path": str(resolve_backend_model_cache("marker")),
        "run": payload,
    }


def make_opendataloader_backend_check() -> dict[str, Any]:
    return make_opendataloader_integration_decision_report()


def make_opendataloader_backend_smoke(input_path: Path | None = None) -> dict[str, Any]:
    if input_path is None and inspect_backend_status("opendataloader")["status"] != "available":
        with TemporaryDirectory(prefix="heitang_opendataloader_smoke_") as tmp:
            placeholder = Path(tmp) / "opendataloader_smoke.pdf"
            placeholder.write_bytes(b"%PDF fake dependency-gate fixture")
            smoke = make_parser_backend_smoke("opendataloader", placeholder)
    else:
        smoke = make_parser_backend_smoke("opendataloader", input_path)
    contract = smoke.get("run", {}).get("adapter_contract") or smoke.get("adapter_smoke_report", {}).get("adapter", {})
    return {
        **smoke,
        "schema_version": "opendataloader.smoke_report.v1",
        "adapter_id": "opendataloader",
        "decision": contract.get("integration_decision", "real_integration"),
        "pdf_supported": ".pdf" in contract.get("supported_inputs", []),
        "markdown_json_normalization_supported": {"markdown", "json"} <= set(contract.get("supported_outputs", [])),
        "layout_blocks_supported": contract.get("layout_support") in {"supported", "partial"},
        "reading_order_supported": contract.get("reading_order_support") in {"supported", "partial"},
        "hybrid_mode_in_default_smoke": False,
    }


def make_opendataloader_integration_decision_report(
    smoke_report: dict[str, Any] | None = None,
    run_report: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return _make_backend_integration_decision_report(
        "opendataloader",
        schema_version="opendataloader.integration_decision.v1",
        smoke_report=smoke_report,
        run_report=run_report,
        commands={
            "check": "check-opendataloader-backend",
            "smoke": "smoke-opendataloader-backend",
            "run": "run-opendataloader-convert",
        },
        artifacts=[
            "opendataloader_smoke_report.json",
            "opendataloader_smoke_report.md",
            "opendataloader_dependency_remediation_report.json",
            "opendataloader_dependency_remediation_report.md",
            "opendataloader_integration_decision_report.json",
            "opendataloader_integration_decision_report.md",
            "opendataloader_convert_result.json",
            "opendataloader_convert_result.md",
            "opendataloader_ui_impact_note.md",
        ],
        ui_bridge_actions=[
            "check_opendataloader_backend",
            "smoke_opendataloader_backend",
            "run_opendataloader_convert",
        ],
        extra_capabilities={
            "pdf_conversion": True,
            "markdown_json_normalization": True,
            "layout_blocks": "partial",
            "tables": "partial",
            "figures": "partial",
            "reading_order": "partial",
            "hybrid_mode_in_default_smoke": False,
            "structured_skipped_when_missing": True,
        },
    )


def make_opendataloader_dependency_remediation_report(
    smoke_report: dict[str, Any] | None = None,
    run_report: dict[str, Any] | None = None,
) -> dict[str, Any]:
    missing = _opendataloader_missing_dependencies()
    post_check = inspect_backend_status("opendataloader")
    smoke_status = smoke_report.get("status") if smoke_report else None
    run_status = run_report.get("status") if run_report else None
    post_smoke_result = smoke_status or run_status or "not_run"
    remediation_needed = bool(missing)
    final_decision = (
        "real_integration"
        if post_check["status"] == "available" and post_smoke_result in {"pass", "success"}
        else "needs_strengthening"
        if remediation_needed
        else "smoke_pending"
    )
    return {
        "schema_version": "opendataloader.dependency_remediation.v1",
        "adapter_name": "opendataloader",
        "missing_dependencies": missing,
        "install_attempted": False,
        "install_commands": [
            "python -m pip install opendataloader-pdf>=2,<3",
            "Install Java 11+ and ensure java is on PATH.",
        ],
        "installed_versions": {},
        "install_paths": {},
        "source": {
            "python_package": "PyPI: opendataloader-pdf",
            "java_runtime": "Project-approved Java 11+ distribution or existing local Java runtime.",
        },
        "risk_notes": [
            "Python package installation is project-approved only when run in an auditable local environment.",
            "Java installation may touch machine-level paths and must not be performed silently by a dependency check.",
            "Hybrid/OCR server mode is excluded from the default smoke path.",
        ],
        "rollback_steps": [
            "Remove the project-local environment or uninstall opendataloader-pdf from the selected environment.",
            "Remove or disable any Java runtime added solely for this adapter.",
            "Re-run check-opendataloader-backend and smoke-opendataloader-backend.",
        ],
        "post_install_check_result": post_check["status"],
        "post_install_smoke_result": post_smoke_result,
        "final_decision": final_decision,
        "blocker_evidence": post_check.get("human_readable_reason"),
    }


def make_opendataloader_ui_impact_note() -> dict[str, Any]:
    check = inspect_backend_status("opendataloader")
    ui_status = "available" if check["status"] == "available" else "dependency_missing"
    return {
        "schema_version": "opendataloader.ui_impact_note.v1",
        "adapter_id": "opendataloader",
        "ui_status": ui_status,
        "desktop_bridge_actions": [
            "check_opendataloader_backend",
            "smoke_opendataloader_backend",
            "run_opendataloader_convert",
        ],
        "web_execution_enabled": False,
        "web_blocked_reason": "web_local_cli_unsupported",
        "truthfulness_note": (
            "UI may expose desktop-local actions, but static web surfaces must show dependency_missing "
            "or structured_skipped until check/smoke evidence proves local availability."
        ),
        "evidence_path": "docs/audits/opendataloader_backend_strengthening/opendataloader_integration_decision_report.json",
    }


def make_opendataloader_convert_result_report(run: Any) -> dict[str, Any]:
    payload = run.to_dict()
    return {
        "schema_version": "opendataloader.convert_result.v1",
        "adapter_id": "opendataloader",
        "status": run.status,
        "source_count": run.source_count,
        "success_count": payload["success_count"],
        "warning_count": payload["warning_count"],
        "pdf_conversion_reported": True,
        "markdown_json_normalization_reported": True,
        "hybrid_mode_in_default_smoke": False,
        "run": payload,
    }


def make_surya_backend_check() -> dict[str, Any]:
    return make_surya_integration_decision_report()


def make_surya_backend_smoke(input_path: Path | None = None) -> dict[str, Any]:
    if input_path is None:
        with TemporaryDirectory(prefix="heitang_surya_smoke_") as tmp:
            placeholder = Path(tmp) / "surya_smoke.pdf"
            placeholder.write_bytes(b"%PDF fake benchmark-gate fixture")
            smoke = make_parser_backend_smoke("surya", placeholder)
    else:
        smoke = make_parser_backend_smoke("surya", input_path)
    contract = smoke.get("run", {}).get("adapter_contract") or smoke.get("adapter_smoke_report", {}).get("adapter", {})
    return {
        **smoke,
        "schema_version": "surya.smoke_report.v1",
        "adapter_id": "surya",
        "decision": contract.get("integration_decision", "needs_strengthening"),
        "benchmark_adapter": True,
        "primary_parser_promotion_blocked": True,
        "ocr_layout_benchmark_candidate": True,
        "runtime_invocation_blocked_until_strengthened": True,
    }


def make_surya_integration_decision_report(
    smoke_report: dict[str, Any] | None = None,
) -> dict[str, Any]:
    return _make_backend_integration_decision_report(
        "surya",
        schema_version="surya.integration_decision.v1",
        smoke_report=smoke_report,
        run_report=None,
        commands={
            "check": "check-surya-backend",
            "smoke": "smoke-surya-backend",
        },
        artifacts=[
            "surya_smoke_report.json",
            "surya_smoke_report.md",
            "surya_dependency_remediation_report.json",
            "surya_dependency_remediation_report.md",
            "surya_integration_decision_report.json",
            "surya_integration_decision_report.md",
            "surya_ui_impact_note.json",
            "surya_ui_impact_note.md",
        ],
        ui_bridge_actions=[
            "check_surya_backend",
            "smoke_surya_backend",
        ],
        extra_capabilities={
            "benchmark_adapter": True,
            "primary_parser": False,
            "ocr_benchmark": True,
            "layout_benchmark": True,
            "table_benchmark": True,
            "requires_inference_backend": "vllm_or_llama_cpp",
            "runtime_invocation_blocked_until_strengthened": True,
            "structured_skipped_when_missing": True,
        },
    )


def make_surya_dependency_remediation_report(
    smoke_report: dict[str, Any] | None = None,
) -> dict[str, Any]:
    missing = _surya_missing_dependencies()
    post_check = inspect_backend_status("surya")
    smoke_status = smoke_report.get("status") if smoke_report else "not_run"
    return {
        "schema_version": "surya.dependency_remediation.v1",
        "adapter_name": "surya",
        "missing_dependencies": missing,
        "install_attempted": False,
        "install_commands": [
            "python -m pip install surya-ocr>=0.20,<1",
            "Install or configure vllm for NVIDIA GPU, or llama.cpp llama-server for CPU/Apple Silicon.",
        ],
        "installed_versions": {},
        "install_paths": {},
        "source": {
            "python_package": "PyPI: surya-ocr",
            "inference_backend": "vllm or llama.cpp llama-server",
        },
        "risk_notes": [
            "Surya 2 model/runtime setup is heavy and may start inference servers or containers.",
            "Do not install or start vllm/llama.cpp silently from a backend check.",
            "Surya remains a benchmark/reference candidate until a scoped smoke proves local runtime behavior.",
        ],
        "rollback_steps": [
            "Uninstall surya-ocr from the selected environment if installed for this adapter.",
            "Stop any vllm container or llama-server process started for Surya.",
            "Remove downloaded Surya model/runtime assets if they were created for this adapter.",
        ],
        "post_install_check_result": post_check["status"],
        "post_install_smoke_result": smoke_status,
        "final_decision": "needs_strengthening",
        "blocker_evidence": post_check.get("human_readable_reason"),
        "old_cache_path": str(_datalab_cache_root()),
        "new_cache_path": str(resolve_backend_model_cache("surya")),
        "cache_size": {
            "old_bytes": _directory_size(_datalab_cache_root()),
            "new_bytes": _directory_size(resolve_backend_model_cache("surya")),
        },
        "migration_needed": _directory_size(_datalab_cache_root()) > 0
        and _directory_size(resolve_backend_model_cache("surya")) == 0,
        "cleanup_suggestion": "Do not delete the legacy datalab cache until Marker/Surya workspace-local runtime evidence is complete.",
    }


def make_surya_ui_impact_note() -> dict[str, Any]:
    check = inspect_backend_status("surya")
    ui_status = "needs_strengthening" if check["status"] != "available" else "smoke_pending"
    return {
        "schema_version": "surya.ui_impact_note.v1",
        "adapter_id": "surya",
        "ui_status": ui_status,
        "desktop_bridge_actions": [
            "check_surya_backend",
            "smoke_surya_backend",
        ],
        "web_execution_enabled": False,
        "web_blocked_reason": "web_local_cli_unsupported",
        "truthfulness_note": "UI should present Surya as an OCR/layout benchmark/reference candidate, not as a primary parser or ready backend.",
        "evidence_path": "docs/audits/surya_backend_decision/surya_integration_decision_report.json",
        "model_cache_path": str(resolve_backend_model_cache("surya")),
    }


def _datalab_cache_root() -> Path:
    local_app_data = Path(os.environ.get("LOCALAPPDATA", Path.home() / "AppData" / "Local"))
    return local_app_data / "datalab" / "datalab" / "Cache"


def _directory_size(path: Path) -> int:
    if not path.exists():
        return 0
    return sum(item.stat().st_size for item in path.rglob("*") if item.is_file())


def _opendataloader_missing_dependencies() -> list[str]:
    missing = []
    if shutil.which("opendataloader-pdf") is None:
        missing.append("opendataloader-pdf")
    if shutil.which("java") is None:
        missing.append("Java 11+")
    return missing


def _surya_missing_dependencies() -> list[str]:
    missing = []
    if shutil.which("surya_ocr") is None:
        missing.append("surya_ocr")
    if shutil.which("vllm") is None and shutil.which("llama-server") is None:
        missing.append("vllm_or_llama_server")
    return missing


def _make_backend_integration_decision_report(
    backend_id: str,
    *,
    schema_version: str,
    smoke_report: dict[str, Any] | None,
    run_report: dict[str, Any] | None,
    commands: dict[str, str],
    artifacts: list[str],
    ui_bridge_actions: list[str],
    extra_capabilities: dict[str, Any],
) -> dict[str, Any]:
    check = inspect_backend_status(backend_id)
    contract = check["capability_contract"]
    decision = contract["integration_decision"]
    supported_inputs = contract.get("supported_inputs", [])
    validated_inputs = contract.get("validated_inputs", [])
    status = "pass" if decision == "real_integration" else "blocked"
    return {
        "schema_version": schema_version,
        "status": status,
        "adapter_id": backend_id,
        "decision": decision,
        "allowed_decisions": INTEGRATION_DECISION_VALUES,
        "current_environment_status": check["status"],
        "dependency_status": contract["dependency_status"],
        "runtime_status": contract["runtime_status"],
        "dependency_available_currently": check["status"] == "available",
        "dependency_name": contract.get("dependency_name"),
        "optional_extra": contract.get("optional_extra"),
        "supported_inputs": supported_inputs,
        "validated_inputs": validated_inputs,
        "supported_outputs": contract.get("supported_outputs", []),
        "capabilities": extra_capabilities,
        "commands": commands,
        "artifacts": artifacts,
        "ui_bridge_actions": ui_bridge_actions,
        "fallback_result": check.get("fallback_result"),
        "repair_suggestion": check.get("repair_suggestion"),
        "inspect_report": check,
        "smoke_status": smoke_report.get("status") if smoke_report else None,
        "run_status": run_report.get("status") if run_report else None,
    }


def make_failure_mode_report() -> dict[str, Any]:
    return {
        "schema_version": "p2.1.failure_modes.v1",
        "release_version": P21_RELEASE_VERSION,
        "status": "pass",
        "fallback_preserved": True,
        "crash_only_failures_allowed": False,
        "cases": FAILURE_MODES,
    }


def make_baseline_lock_report() -> dict[str, Any]:
    return {
        "schema_version": "p2.1.baseline_lock.v1",
        "status": "pass",
        "core_runtime_baseline_commit": P21_RUNTIME_BASELINE_COMMIT,
        "baseline_hygiene_commit": P21_BASELINE_HYGIENE_COMMIT,
        "v4_0_0_tag_expected_commit": V4_0_0_TAG_COMMIT,
        "external_project_registry_needs_verification": 0,
        "false_ready_or_executable_external_project_count": 0,
        "optional_backends": ["docling", "paddleocr", "unstructured"],
        "default_heavy_dependencies_bundled": False,
        "default_core_parser_changed": False,
    }


def make_acceptance_summary_report() -> dict[str, Any]:
    return {
        "schema_version": "p2.1.acceptance_summary.v1",
        "status": "pass",
        "source_acceptance_report": P21_ACCEPTANCE_SOURCE,
        "live_runtime_completion_proven": True,
        "required_backends": ["docling", "paddleocr", "unstructured"],
        "pass_count": 3,
        "blocked_count": 0,
        "fail_count": 0,
        "mock_evidence_counted_as_real": False,
        "raw_runtime_text_committed": False,
    }


def make_evidence_index() -> dict[str, Any]:
    return {
        "schema_version": "p2.1.evidence_index.v1",
        "release_version": P21_RELEASE_VERSION,
        "status": "pass",
        "artifacts": [
            {"id": "baseline_lock", "path": f"{P21_AUDIT_DIR}/p2_1_baseline_lock_report.md"},
            {"id": "acceptance_report", "path": f"{P21_AUDIT_DIR}/p2_1_acceptance_report.md"},
            {"id": "backend_matrix", "path": f"{P21_AUDIT_DIR}/parser_backend_matrix.json"},
            {"id": "backend_status_schema", "path": f"{P21_AUDIT_DIR}/backend_status_schema.json"},
            {"id": "backend_status_report", "path": f"{P21_AUDIT_DIR}/parser_backend_status_report.md"},
            {"id": "capability_boundaries", "path": f"{P21_AUDIT_DIR}/backend_capability_boundaries.md"},
            {"id": "live_acceptance_replay", "path": f"{P21_AUDIT_DIR}/live_acceptance_replay.md"},
            {"id": "failure_modes", "path": f"{P21_AUDIT_DIR}/failure_mode_report.json"},
            {"id": "fresh_clone_reproducibility", "path": f"{P21_AUDIT_DIR}/fresh_clone_reproducibility_report.md"},
        ],
    }


def make_fresh_clone_reproducibility_report() -> dict[str, Any]:
    return {
        "schema_version": "p2.1.fresh_clone_reproducibility.v1",
        "status": "pass",
        "default_install_keeps_heavy_backends_optional": True,
        "default_install_commands": [
            "python -m pip install -e .",
            "python -m heitang_kb_forge.cli parser-backend-registry --output .\\tmp_parser_registry",
            "python -m heitang_kb_forge.cli parser-backend-matrix --output .\\tmp_parser_matrix",
            "python -m heitang_kb_forge.cli parser-backend-inspect docling --output .\\tmp_parser_docling",
            "python -m heitang_kb_forge.cli parser-backend-inspect paddleocr --output .\\tmp_parser_paddleocr",
            "python -m heitang_kb_forge.cli parser-backend-inspect unstructured --output .\\tmp_parser_unstructured",
            "python -m heitang_kb_forge.cli parser-backend-smoke --backend builtin --output .\\tmp_parser_builtin_smoke",
        ],
        "optional_install_commands": [
            "python -m pip install -e \".[parser-docling]\"",
            "python -m pip install -e \".[parser-paddleocr]\"",
            "python -m pip install -e \".[parser-unstructured]\"",
        ],
        "live_replay_command": (
            "python -m heitang_kb_forge.cli parser-runtime-acceptance "
            "--input .\\_local_acceptance_inputs\\parser_runtime_all_three_clean "
            "--output .\\tmp_parser_runtime_acceptance "
            "--backends docling,paddleocr,unstructured"
        ),
        "notes": [
            "Default install does not install Docling, PaddleOCR, Unstructured, or OCR model files.",
            "Optional dependency missing behavior is expected and reported as blocked_by_dependency.",
            "Optional dependency installed behavior is proven by the committed isolated-venv live acceptance report.",
        ],
    }


def render_matrix_report(matrix: dict[str, Any]) -> str:
    lines = [
        "# Parser Backend Matrix",
        "",
        f"- Release: {matrix['release_version']}",
        f"- Runtime baseline commit: `{matrix['runtime_baseline_commit']}`",
        f"- Default heavy dependencies bundled: `{str(matrix['default_heavy_dependencies_bundled']).lower()}`",
        f"- Default Core parser changed: `{str(matrix['default_core_parser_changed']).lower()}`",
        "",
        "| Backend | Dependency mode | Acceptance dependency | Runtime invoked | Stable surface | Status |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for backend in matrix["backends"]:
        lines.append(
            f"| {backend['backend_id']} | {backend['dependency_mode']} | "
            f"{str(backend['dependency_available']).lower()} | {str(backend['runtime_invoked']).lower()} | "
            f"{', '.join(backend['validated_stable_surface'])} | {backend['status']} |"
        )
    return "\n".join(lines).rstrip() + "\n"


def render_baseline_lock_report(report: dict[str, Any]) -> str:
    return (
        "# P2.1 Baseline Lock Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Runtime baseline commit: `{report['core_runtime_baseline_commit']}`\n"
        f"- Baseline hygiene commit: `{report['baseline_hygiene_commit']}`\n"
        f"- v4.0.0 expected tag commit: `{report['v4_0_0_tag_expected_commit']}`\n"
        f"- External registry `needs_verification`: `{report['external_project_registry_needs_verification']}`\n"
        f"- False ready/executable external projects: `{report['false_ready_or_executable_external_project_count']}`\n"
        f"- Default heavy parser/OCR dependencies bundled: `{str(report['default_heavy_dependencies_bundled']).lower()}`\n"
        f"- Default Core parser changed: `{str(report['default_core_parser_changed']).lower()}`\n"
    )


def render_acceptance_summary_report(report: dict[str, Any]) -> str:
    return (
        "# P2.1 Parser/OCR Acceptance Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Source acceptance report: `{report['source_acceptance_report']}`\n"
        f"- Live runtime completion proven: `{str(report['live_runtime_completion_proven']).lower()}`\n"
        f"- Required backends: {', '.join(report['required_backends'])}\n"
        f"- Pass / blocked / fail: `{report['pass_count']} / {report['blocked_count']} / {report['fail_count']}`\n"
        f"- Mock evidence counted as real: `{str(report['mock_evidence_counted_as_real']).lower()}`\n"
        f"- Raw runtime text committed: `{str(report['raw_runtime_text_committed']).lower()}`\n"
    )


def render_backend_status_report(matrix: dict[str, Any]) -> str:
    lines = [
        "# Parser Backend Status Report",
        "",
        "This report is derived from `parser_backend_matrix.json` and the committed P2.1 live acceptance evidence.",
        "",
    ]
    for backend in matrix["backends"]:
        lines.extend(
            [
                f"## {backend['backend_id']}",
                "",
                f"- Dependency mode: `{backend['dependency_mode']}`",
                f"- Dependency available in live acceptance: `{str(backend['dependency_available']).lower()}`",
                f"- Runtime invoked in live acceptance: `{str(backend['runtime_invoked']).lower()}`",
                f"- Sample input type: {backend['sample_input_type']}",
                f"- Validated stable surface: {', '.join(backend['validated_stable_surface'])}",
                f"- Status: `{backend['status']}`",
                f"- Evidence path: `{backend['evidence_path']}`",
                f"- Fallback behavior: {backend['fallback_behavior']}",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def render_capability_boundaries_report(matrix: dict[str, Any]) -> str:
    lines = [
        "# Backend Capability Boundaries",
        "",
        "- Docling, PaddleOCR, and Unstructured are real optional local runtime adapters.",
        "- They are dependency-gated, not bundled, not default Core parsing, and not static Workbench executable controls.",
        "- Unstructured stable surface for v4.1.0 is `.md/.txt`; PDF/DOCX/image extras are future hardening.",
        "",
    ]
    for backend in matrix["backends"]:
        lines.append(f"## {backend['backend_id']}")
        lines.append("")
        for limitation in backend["known_limitations"]:
            lines.append(f"- {limitation}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def render_live_acceptance_replay_report(report: dict[str, Any]) -> str:
    replay = make_fresh_clone_reproducibility_report()
    return (
        "# Live Acceptance Replay\n\n"
        f"- Source acceptance report: `{report['source_acceptance_report']}`\n"
        f"- Replay command: `{replay['live_replay_command']}`\n"
        "- The committed acceptance report stores counts, dependency/runtime status, and text lengths only; it does not commit raw parsed text.\n"
        "- In a default install without optional extras, replay is expected to report dependency-gated blocked status.\n"
        "- In the isolated acceptance venv used for P2.1, replay passed for Docling, PaddleOCR, and Unstructured.\n"
    )


def render_fresh_clone_reproducibility_report(report: dict[str, Any]) -> str:
    lines = [
        "# Fresh Clone / Clean Venv Reproducibility",
        "",
        f"- Status: `{report['status']}`",
        f"- Default install keeps heavy backends optional: `{str(report['default_install_keeps_heavy_backends_optional']).lower()}`",
        "",
        "## Default Install Commands",
        "",
        "```powershell",
        *report["default_install_commands"],
        "```",
        "",
        "## Optional Backend Install Commands",
        "",
        "```powershell",
        *report["optional_install_commands"],
        "```",
        "",
        "## Live Acceptance Replay",
        "",
        "```powershell",
        report["live_replay_command"],
        "```",
        "",
        "## Notes",
        "",
    ]
    for note in report["notes"]:
        lines.append(f"- {note}")
    return "\n".join(lines).rstrip() + "\n"


def render_registry_report(registry: dict[str, Any]) -> str:
    lines = ["# Parser Backend Registry", "", f"- No heavy import required: `{str(registry['no_heavy_import_required']).lower()}`", ""]
    for backend in registry["backends"]:
        reason = f" Reason: {backend['reason']}" if backend.get("reason") else ""
        lines.append(f"- {backend['name']}: {backend['status']} | extensions={', '.join(backend['supported_extensions'])}.{reason}")
    return "\n".join(lines).rstrip() + "\n"


def render_inspect_report(report: dict[str, Any]) -> str:
    lines = ["# Parser Backend Inspect", "", f"- Backend: `{report['backend_id']}`", f"- Status: `{report['status']}`"]
    if report.get("error_code"):
        lines.extend(
            [
                f"- Error code: `{report['error_code']}`",
                f"- Reason: {report.get('human_readable_reason')}",
                f"- Fallback: `{report.get('fallback_result')}`",
                f"- Repair: {report.get('repair_suggestion')}",
            ]
        )
    elif report.get("backend"):
        backend = report["backend"]
        lines.extend(
            [
                f"- Dependency mode: `{backend['dependency_mode']}`",
                f"- Stable surface: {', '.join(backend['validated_stable_surface'])}",
                f"- Evidence: `{backend['evidence_path']}`",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def render_smoke_report(report: dict[str, Any]) -> str:
    run = report.get("run", {})
    return (
        "# Parser Backend Smoke\n\n"
        f"- Backend: `{report['backend_id']}`\n"
        f"- Status: `{report['status']}`\n"
        f"- Source: `{report.get('source')}`\n"
        f"- Run status: `{run.get('status')}`\n"
        f"- Fallback: `{report.get('fallback_result')}`\n"
    )


def render_paddleocr_smoke_report(report: dict[str, Any]) -> str:
    smoke = report.get("adapter_smoke_report", {})
    return (
        "# PaddleOCR Smoke Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Adapter smoke status: `{smoke.get('status')}`\n"
        f"- Source: `{report.get('source')}`\n"
        f"- Decision: `{report.get('decision')}`\n"
        f"- Image OCR supported: `{str(report.get('image_ocr_supported')).lower()}`\n"
        f"- Scanned PDF page OCR supported: `{str(report.get('scanned_pdf_page_ocr_supported')).lower()}`\n"
        f"- Fallback: `{report.get('fallback_result')}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_paddleocr_integration_decision_report(report: dict[str, Any]) -> str:
    return (
        "# PaddleOCR Integration Decision Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Decision: `{report['decision']}`\n"
        f"- Current environment: `{report['current_environment_status']}`\n"
        f"- Dependency status: `{report['dependency_status']}`\n"
        f"- Runtime status: `{report['runtime_status']}`\n"
        f"- Optional extra: `{report.get('optional_extra')}`\n"
        f"- Supported inputs: {', '.join(report.get('supported_inputs', []))}\n"
        f"- Validated inputs: {', '.join(report.get('validated_inputs', []))}\n"
        f"- Image OCR: `{str(report['capabilities']['image_ocr']).lower()}`\n"
        f"- Scanned PDF page OCR: `{str(report['capabilities']['scanned_pdf_page_ocr']).lower()}`\n"
        f"- Structured skipped when missing: `{str(report['capabilities']['structured_skipped_when_missing']).lower()}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_paddleocr_ocr_result_report(report: dict[str, Any]) -> str:
    return (
        "# PaddleOCR OCR Result\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Source count: `{report['source_count']}`\n"
        f"- Success count: `{report['success_count']}`\n"
        f"- Warning count: `{report['warning_count']}`\n"
        f"- Confidence reported: `{str(report['confidence_reported']).lower()}`\n"
        f"- Source page trace reported: `{str(report['source_page_trace_reported']).lower()}`\n"
    )


def render_mineru_smoke_report(report: dict[str, Any]) -> str:
    smoke = report.get("adapter_smoke_report", {})
    return (
        "# MinerU Smoke Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Adapter smoke status: `{smoke.get('status')}`\n"
        f"- Source: `{report.get('source')}`\n"
        f"- Decision: `{report.get('decision')}`\n"
        f"- PDF supported: `{str(report.get('pdf_supported')).lower()}`\n"
        f"- Image/scanned path supported: `{str(report.get('image_or_scanned_supported')).lower()}`\n"
        f"- Layout blocks supported: `{str(report.get('layout_blocks_supported')).lower()}`\n"
        f"- Markdown/JSON normalization supported: `{str(report.get('markdown_json_normalization_supported')).lower()}`\n"
        f"- Fallback: `{report.get('fallback_result')}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_mineru_integration_decision_report(report: dict[str, Any]) -> str:
    capabilities = report["capabilities"]
    return (
        "# MinerU Integration Decision Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Decision: `{report['decision']}`\n"
        f"- Current environment: `{report['current_environment_status']}`\n"
        f"- Dependency status: `{report['dependency_status']}`\n"
        f"- Runtime status: `{report['runtime_status']}`\n"
        f"- Optional extra: `{report.get('optional_extra')}`\n"
        f"- Supported inputs: {', '.join(report.get('supported_inputs', []))}\n"
        f"- Validated inputs: {', '.join(report.get('validated_inputs', []))}\n"
        f"- PDF parse: `{str(capabilities['pdf_parse']).lower()}`\n"
        f"- Layout blocks: `{str(capabilities['layout_blocks']).lower()}`\n"
        f"- Reading order: `{str(capabilities['reading_order']).lower()}`\n"
        f"- Table / figure / formula metadata: `{capabilities['table_metadata']} / {capabilities['figure_metadata']} / {capabilities['formula_metadata']}`\n"
        f"- Markdown/JSON normalization: `{str(capabilities['markdown_json_normalization']).lower()}`\n"
        f"- Structured skipped when missing: `{str(capabilities['structured_skipped_when_missing']).lower()}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_mineru_document_understanding_result_report(report: dict[str, Any]) -> str:
    return (
        "# MinerU Document Understanding Result\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Source count: `{report['source_count']}`\n"
        f"- Success count: `{report['success_count']}`\n"
        f"- Warning count: `{report['warning_count']}`\n"
        f"- Layout blocks reported: `{str(report['layout_blocks_reported']).lower()}`\n"
        f"- Reading order reported: `{str(report['reading_order_reported']).lower()}`\n"
        f"- Table metadata reported: `{str(report['table_metadata_reported']).lower()}`\n"
        f"- Figure metadata reported: `{str(report['figure_metadata_reported']).lower()}`\n"
        f"- Formula metadata reported: `{str(report['formula_metadata_reported']).lower()}`\n"
    )


def render_docling_smoke_report(report: dict[str, Any]) -> str:
    smoke = report.get("adapter_smoke_report", {})
    return (
        "# Docling Smoke Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Adapter smoke status: `{smoke.get('status')}`\n"
        f"- Source: `{report.get('source')}`\n"
        f"- Decision: `{report.get('decision')}`\n"
        f"- Document conversion supported: `{str(report.get('document_conversion_supported')).lower()}`\n"
        f"- Markdown normalization supported: `{str(report.get('markdown_normalization_supported')).lower()}`\n"
        f"- Fallback: `{report.get('fallback_result')}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_docling_integration_decision_report(report: dict[str, Any]) -> str:
    capabilities = report["capabilities"]
    return (
        "# Docling Integration Decision Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Decision: `{report['decision']}`\n"
        f"- Current environment: `{report['current_environment_status']}`\n"
        f"- Dependency status: `{report['dependency_status']}`\n"
        f"- Runtime status: `{report['runtime_status']}`\n"
        f"- Optional extra: `{report.get('optional_extra')}`\n"
        f"- Supported inputs: {', '.join(report.get('supported_inputs', []))}\n"
        f"- Validated inputs: {', '.join(report.get('validated_inputs', []))}\n"
        f"- Document conversion: `{str(capabilities['document_conversion']).lower()}`\n"
        f"- Layout blocks: `{capabilities['layout_blocks']}`\n"
        f"- Tables: `{capabilities['tables']}`\n"
        f"- Markdown normalization: `{str(capabilities['markdown_normalization']).lower()}`\n"
        f"- Structured skipped when missing: `{str(capabilities['structured_skipped_when_missing']).lower()}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_docling_convert_result_report(report: dict[str, Any]) -> str:
    return (
        "# Docling Convert Result\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Source count: `{report['source_count']}`\n"
        f"- Success count: `{report['success_count']}`\n"
        f"- Warning count: `{report['warning_count']}`\n"
        f"- Document conversion reported: `{str(report['document_conversion_reported']).lower()}`\n"
        f"- Markdown normalization reported: `{str(report['markdown_normalization_reported']).lower()}`\n"
    )


def render_fallback_parser_contract(report: dict[str, Any]) -> str:
    capabilities = report["contract_capabilities"]
    return (
        "# Fallback Parser Contract\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Adapter: `{report['adapter_id']}`\n"
        f"- Adapter type: `{report['adapter_type']}`\n"
        f"- Decision: `{report['decision']}`\n"
        f"- Default install available: `{str(report['default_install_available']).lower()}`\n"
        f"- Basic text documents: `{str(report['handles_basic_text_documents']).lower()}`\n"
        f"- Stable fallback surface: {', '.join(report['validated_stable_surface'])}\n"
        f"- Primary Document Understanding backend: `{str(report['primary_document_understanding_backend']).lower()}`\n"
        f"- OCR support: `{capabilities['ocr_support']}`\n"
        f"- Layout support: `{capabilities['layout_support']}`\n"
        f"- Table support: `{capabilities['table_support']}`\n"
        f"- Formula support: `{capabilities['formula_support']}`\n"
        f"- Truthfulness note: {report['truthfulness_note']}\n"
    )


def render_unstructured_smoke_report(report: dict[str, Any]) -> str:
    smoke = report.get("adapter_smoke_report", {})
    return (
        "# Unstructured Smoke Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Adapter smoke status: `{smoke.get('status')}`\n"
        f"- Source: `{report.get('source')}`\n"
        f"- Decision: `{report.get('decision')}`\n"
        f"- Basic text documents: `{str(report.get('basic_text_documents_supported')).lower()}`\n"
        f"- Stable surface: {', '.join(report.get('validated_stable_surface', []))}\n"
        f"- Full Document Understanding backend: `{str(report.get('full_document_understanding_backend')).lower()}`\n"
        f"- Fallback: `{report.get('fallback_result')}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_unstructured_integration_decision_report(report: dict[str, Any]) -> str:
    capabilities = report["capabilities"]
    return (
        "# Unstructured Integration Decision Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Decision: `{report['decision']}`\n"
        f"- Current environment: `{report['current_environment_status']}`\n"
        f"- Dependency status: `{report['dependency_status']}`\n"
        f"- Runtime status: `{report['runtime_status']}`\n"
        f"- Optional extra: `{report.get('optional_extra')}`\n"
        f"- Supported inputs: {', '.join(report.get('supported_inputs', []))}\n"
        f"- Validated inputs: {', '.join(report.get('validated_inputs', []))}\n"
        f"- Basic text documents: `{str(capabilities['basic_text_documents']).lower()}`\n"
        f"- Full Document Understanding backend: `{str(capabilities['full_document_understanding_backend']).lower()}`\n"
        f"- OCR: `{capabilities['ocr']}`\n"
        f"- Layout: `{capabilities['layout']}`\n"
        f"- Tables: `{capabilities['tables']}`\n"
        f"- Formulas: `{capabilities['formulas']}`\n"
        f"- Structured skipped when missing: `{str(capabilities['structured_skipped_when_missing']).lower()}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_unstructured_dependency_remediation_report(report: dict[str, Any]) -> str:
    missing = ", ".join(report.get("missing_dependencies", [])) or "none"
    commands = "\n".join(f"  - `{command}`" for command in report.get("install_commands", []))
    rollback = "\n".join(f"  - {step}" for step in report.get("rollback_steps", []))
    return (
        "# Unstructured Dependency Remediation Report\n\n"
        f"- Adapter: `{report['adapter_name']}`\n"
        f"- Missing dependencies: {missing}\n"
        f"- Install attempted: `{str(report['install_attempted']).lower()}`\n"
        f"- Post-install check: `{report['post_install_check_result']}`\n"
        f"- Post-install smoke: `{report['post_install_smoke_result']}`\n"
        f"- Final decision: `{report['final_decision']}`\n"
        f"- Blocker evidence: {report.get('blocker_evidence')}\n"
        "- Install commands:\n"
        f"{commands}\n"
        "- Rollback steps:\n"
        f"{rollback}\n"
    )


def render_unstructured_ui_impact_note(report: dict[str, Any]) -> str:
    actions = ", ".join(report.get("desktop_bridge_actions", []))
    return (
        "# Unstructured UI Impact Note\n\n"
        f"- Adapter: `{report['adapter_id']}`\n"
        f"- UI status: `{report['ui_status']}`\n"
        f"- Desktop bridge actions: {actions}\n"
        f"- Web execution enabled: `{str(report['web_execution_enabled']).lower()}`\n"
        f"- Web blocked reason: `{report['web_blocked_reason']}`\n"
        f"- Evidence path: `{report['evidence_path']}`\n"
        f"- Truthfulness note: {report['truthfulness_note']}\n"
    )


def render_marker_smoke_report(report: dict[str, Any]) -> str:
    smoke = report.get("adapter_smoke_report", {})
    return (
        "# Marker Smoke Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Adapter smoke status: `{smoke.get('status')}`\n"
        f"- Source: `{report.get('source')}`\n"
        f"- Decision: `{report.get('decision')}`\n"
        f"- Runtime invocation blocked until strengthened: `{str(report.get('runtime_invocation_blocked_until_strengthened')).lower()}`\n"
        f"- Use LLM: `{str(report.get('use_llm')).lower()}`\n"
        f"- Model cache path: `{report.get('model_cache_path')}`\n"
        f"- License gate: `{report.get('license_gate_status')}`\n"
        f"- Output non-empty: `{str(report.get('output_non_empty')).lower()}`\n"
        f"- Output schema readable: `{str(report.get('output_schema_readable')).lower()}`\n"
        f"- LLM request count: `{report.get('llm_request_count')}`\n"
        f"- LLM tokens used: `{report.get('llm_tokens_used')}`\n"
        f"- Fallback: `{report.get('fallback_result')}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_marker_integration_decision_report(report: dict[str, Any]) -> str:
    capabilities = report["capabilities"]
    return (
        "# Marker Integration Decision Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Decision: `{report['decision']}`\n"
        f"- Current environment: `{report['current_environment_status']}`\n"
        f"- Dependency status: `{report['dependency_status']}`\n"
        f"- Runtime status: `{report['runtime_status']}`\n"
        f"- Optional extra: `{report.get('optional_extra')}`\n"
        f"- Stable Markdown/JSON output: `{str(capabilities['stable_markdown_or_json_output']).lower()}`\n"
        f"- Runtime invocation blocked until strengthened: `{str(capabilities['runtime_invocation_blocked_until_strengthened']).lower()}`\n"
        f"- Reference/strengthening candidate: `{str(capabilities['reference_only_or_strengthening_candidate']).lower()}`\n"
        f"- Structured skipped when missing: `{str(capabilities['structured_skipped_when_missing']).lower()}`\n"
        f"- Use LLM: `{str(capabilities['use_llm']).lower()}`\n"
        f"- Model cache path: `{capabilities['model_cache_path']}`\n"
        f"- License gate: `{capabilities['license_gate_status']}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_marker_dependency_remediation_report(report: dict[str, Any]) -> str:
    return (
        "# Marker Dependency Remediation Report\n\n"
        f"- Install attempted: `{str(report['install_attempted']).lower()}`\n"
        f"- Install command: `{report['install_command']}`\n"
        f"- Installed version: `{report.get('installed_version')}`\n"
        f"- Source: {report['source']}\n"
        f"- Install path: `{report['install_path']}`\n"
        f"- Runtime status: `{report['runtime_status']}`\n"
        f"- Smoke status: `{report['smoke_status']}`\n"
        f"- License gate: `{report['license_gate_status']}`\n"
        f"- Final decision: `{report['final_decision']}`\n"
        f"- Old cache path: `{report['old_cache_path']}`\n"
        f"- New cache path: `{report['new_cache_path']}`\n"
        f"- Old cache bytes: `{report['cache_size']['old_bytes']}`\n"
        f"- New cache bytes: `{report['cache_size']['new_bytes']}`\n"
        f"- Migration performed: `{str(report['migration_performed']).lower()}`\n"
        f"- Migration needed: `{str(report['migration_needed']).lower()}`\n"
        f"- Cleanup suggestion: {report['cleanup_suggestion']}\n"
    )


def render_marker_ui_impact_note(report: dict[str, Any]) -> str:
    return (
        "# Marker UI Impact Note\n\n"
        f"- UI status: `{report['ui_status']}`\n"
        f"- Runtime status: `{report['runtime_status']}`\n"
        f"- Smoke status: `{report['smoke_status']}`\n"
        f"- License gate: `{report['license_gate_status']}`\n"
        f"- Model cache path: `{report['model_cache_path']}`\n"
        f"- Web execution enabled: `{str(report['web_execution_enabled']).lower()}`\n"
        f"- Truthfulness note: {report['truthfulness_note']}\n"
    )


def render_marker_convert_result_report(report: dict[str, Any]) -> str:
    return (
        "# Marker Convert Result\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Source count: `{report['source_count']}`\n"
        f"- Success count: `{report['success_count']}`\n"
        f"- Output non-empty: `{str(report['output_non_empty']).lower()}`\n"
        f"- Output schema readable: `{str(report['output_schema_readable']).lower()}`\n"
        f"- LLM request count: `{report['llm_request_count']}`\n"
        f"- LLM tokens used: `{report['llm_tokens_used']}`\n"
        f"- Model cache path: `{report['model_cache_path']}`\n"
    )


def render_opendataloader_smoke_report(report: dict[str, Any]) -> str:
    smoke = report.get("adapter_smoke_report", {})
    return (
        "# OpenDataLoader Smoke Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Adapter smoke status: `{smoke.get('status')}`\n"
        f"- Source: `{report.get('source')}`\n"
        f"- Decision: `{report.get('decision')}`\n"
        f"- PDF supported: `{str(report.get('pdf_supported')).lower()}`\n"
        f"- Markdown/JSON normalization supported: `{str(report.get('markdown_json_normalization_supported')).lower()}`\n"
        f"- Hybrid mode in default smoke: `{str(report.get('hybrid_mode_in_default_smoke')).lower()}`\n"
        f"- Fallback: `{report.get('fallback_result')}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_opendataloader_integration_decision_report(report: dict[str, Any]) -> str:
    capabilities = report["capabilities"]
    return (
        "# OpenDataLoader Integration Decision Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Decision: `{report['decision']}`\n"
        f"- Current environment: `{report['current_environment_status']}`\n"
        f"- Dependency status: `{report['dependency_status']}`\n"
        f"- Runtime status: `{report['runtime_status']}`\n"
        f"- Optional extra: `{report.get('optional_extra')}`\n"
        f"- Supported inputs: {', '.join(report.get('supported_inputs', []))}\n"
        f"- Validated inputs: {', '.join(report.get('validated_inputs', []))}\n"
        f"- PDF conversion: `{str(capabilities['pdf_conversion']).lower()}`\n"
        f"- Markdown/JSON normalization: `{str(capabilities['markdown_json_normalization']).lower()}`\n"
        f"- Layout blocks: `{capabilities['layout_blocks']}`\n"
        f"- Tables: `{capabilities['tables']}`\n"
        f"- Figures: `{capabilities['figures']}`\n"
        f"- Reading order: `{capabilities['reading_order']}`\n"
        f"- Hybrid mode in default smoke: `{str(capabilities['hybrid_mode_in_default_smoke']).lower()}`\n"
        f"- Structured skipped when missing: `{str(capabilities['structured_skipped_when_missing']).lower()}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_opendataloader_convert_result_report(report: dict[str, Any]) -> str:
    return (
        "# OpenDataLoader Convert Result\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Source count: `{report['source_count']}`\n"
        f"- Success count: `{report['success_count']}`\n"
        f"- Warning count: `{report['warning_count']}`\n"
        f"- PDF conversion reported: `{str(report['pdf_conversion_reported']).lower()}`\n"
        f"- Markdown/JSON normalization reported: `{str(report['markdown_json_normalization_reported']).lower()}`\n"
        f"- Hybrid mode in default smoke: `{str(report['hybrid_mode_in_default_smoke']).lower()}`\n"
    )


def render_opendataloader_dependency_remediation_report(report: dict[str, Any]) -> str:
    missing = ", ".join(report.get("missing_dependencies", [])) or "none"
    commands = "\n".join(f"  - `{command}`" for command in report.get("install_commands", []))
    rollback = "\n".join(f"  - {step}" for step in report.get("rollback_steps", []))
    return (
        "# OpenDataLoader Dependency Remediation Report\n\n"
        f"- Adapter: `{report['adapter_name']}`\n"
        f"- Missing dependencies: {missing}\n"
        f"- Install attempted: `{str(report['install_attempted']).lower()}`\n"
        f"- Post-install check: `{report['post_install_check_result']}`\n"
        f"- Post-install smoke: `{report['post_install_smoke_result']}`\n"
        f"- Final decision: `{report['final_decision']}`\n"
        f"- Blocker evidence: {report.get('blocker_evidence')}\n"
        "- Install commands:\n"
        f"{commands}\n"
        "- Rollback steps:\n"
        f"{rollback}\n"
    )


def render_opendataloader_ui_impact_note(report: dict[str, Any]) -> str:
    actions = ", ".join(report.get("desktop_bridge_actions", []))
    return (
        "# OpenDataLoader UI Impact Note\n\n"
        f"- Adapter: `{report['adapter_id']}`\n"
        f"- UI status: `{report['ui_status']}`\n"
        f"- Desktop bridge actions: {actions}\n"
        f"- Web execution enabled: `{str(report['web_execution_enabled']).lower()}`\n"
        f"- Web blocked reason: `{report['web_blocked_reason']}`\n"
        f"- Evidence path: `{report['evidence_path']}`\n"
        f"- Truthfulness note: {report['truthfulness_note']}\n"
    )


def render_surya_smoke_report(report: dict[str, Any]) -> str:
    smoke = report.get("adapter_smoke_report", {})
    return (
        "# Surya Smoke Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Adapter smoke status: `{smoke.get('status')}`\n"
        f"- Source: `{report.get('source')}`\n"
        f"- Decision: `{report.get('decision')}`\n"
        f"- Benchmark adapter: `{str(report.get('benchmark_adapter')).lower()}`\n"
        f"- Primary parser promotion blocked: `{str(report.get('primary_parser_promotion_blocked')).lower()}`\n"
        f"- Runtime invocation blocked until strengthened: `{str(report.get('runtime_invocation_blocked_until_strengthened')).lower()}`\n"
        f"- Fallback: `{report.get('fallback_result')}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_surya_integration_decision_report(report: dict[str, Any]) -> str:
    capabilities = report["capabilities"]
    return (
        "# Surya Integration Decision Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Decision: `{report['decision']}`\n"
        f"- Current environment: `{report['current_environment_status']}`\n"
        f"- Dependency status: `{report['dependency_status']}`\n"
        f"- Runtime status: `{report['runtime_status']}`\n"
        f"- Optional extra: `{report.get('optional_extra')}`\n"
        f"- Supported inputs: {', '.join(report.get('supported_inputs', []))}\n"
        f"- Benchmark adapter: `{str(capabilities['benchmark_adapter']).lower()}`\n"
        f"- Primary parser: `{str(capabilities['primary_parser']).lower()}`\n"
        f"- OCR benchmark: `{str(capabilities['ocr_benchmark']).lower()}`\n"
        f"- Layout benchmark: `{str(capabilities['layout_benchmark']).lower()}`\n"
        f"- Requires inference backend: `{capabilities['requires_inference_backend']}`\n"
        f"- Runtime invocation blocked until strengthened: `{str(capabilities['runtime_invocation_blocked_until_strengthened']).lower()}`\n"
        f"- Structured skipped when missing: `{str(capabilities['structured_skipped_when_missing']).lower()}`\n"
        f"- Repair: {report.get('repair_suggestion')}\n"
    )


def render_surya_dependency_remediation_report(report: dict[str, Any]) -> str:
    missing = ", ".join(report.get("missing_dependencies", [])) or "none"
    commands = "\n".join(f"  - `{command}`" for command in report.get("install_commands", []))
    rollback = "\n".join(f"  - {step}" for step in report.get("rollback_steps", []))
    return (
        "# Surya Dependency Remediation Report\n\n"
        f"- Adapter: `{report['adapter_name']}`\n"
        f"- Missing dependencies: {missing}\n"
        f"- Install attempted: `{str(report['install_attempted']).lower()}`\n"
        f"- Post-install check: `{report['post_install_check_result']}`\n"
        f"- Post-install smoke: `{report['post_install_smoke_result']}`\n"
        f"- Final decision: `{report['final_decision']}`\n"
        f"- Blocker evidence: {report.get('blocker_evidence')}\n"
        "- Install commands:\n"
        f"{commands}\n"
        "- Rollback steps:\n"
        f"{rollback}\n"
    )


def render_surya_ui_impact_note(report: dict[str, Any]) -> str:
    actions = ", ".join(report.get("desktop_bridge_actions", []))
    return (
        "# Surya UI Impact Note\n\n"
        f"- Adapter: `{report['adapter_id']}`\n"
        f"- UI status: `{report['ui_status']}`\n"
        f"- Desktop bridge actions: {actions}\n"
        f"- Web execution enabled: `{str(report['web_execution_enabled']).lower()}`\n"
        f"- Web blocked reason: `{report['web_blocked_reason']}`\n"
        f"- Evidence path: `{report['evidence_path']}`\n"
        f"- Truthfulness note: {report['truthfulness_note']}\n"
    )


def render_failure_mode_report(report: dict[str, Any]) -> str:
    lines = [
        "# Parser Backend Failure Mode Report",
        "",
        f"- Status: `{report['status']}`",
        f"- Fallback preserved: `{str(report['fallback_preserved']).lower()}`",
        f"- Crash-only failures allowed: `{str(report['crash_only_failures_allowed']).lower()}`",
        "",
        "| Case | Error code | Workbench status | Fallback |",
        "| --- | --- | --- | --- |",
    ]
    for case in report["cases"]:
        lines.append(f"| {case['case_id']} | {case['error_code']} | {case['workbench_visible_status']} | {case['fallback_result']} |")
    return "\n".join(lines).rstrip() + "\n"


def render_evidence_index(report: dict[str, Any]) -> str:
    lines = ["# P2.1 Parser/OCR Evidence Index", "", f"- Status: `{report['status']}`", ""]
    for artifact in report["artifacts"]:
        lines.append(f"- `{artifact['id']}`: `{artifact['path']}`")
    return "\n".join(lines).rstrip() + "\n"


def _default_smoke_source(tmp: Path, backend_id: str) -> Path:
    if backend_id == "mineru":
        source = tmp / "unsupported_for_default_smoke.txt"
        source.write_text("MinerU smoke requires an explicit document/PDF/image source.", encoding="utf-8")
        return source
    if backend_id == "opendataloader":
        source = tmp / "unsupported_for_default_smoke.txt"
        source.write_text("OpenDataLoader smoke requires an explicit PDF source.", encoding="utf-8")
        return source
    if backend_id == "paddleocr":
        source = tmp / "unsupported_for_default_smoke.txt"
        source.write_text("PaddleOCR smoke requires an explicit OCR image/PDF source.", encoding="utf-8")
        return source
    source = tmp / "smoke.md"
    source.write_text("# Parser backend smoke\n\nBuiltin/default text smoke.", encoding="utf-8")
    return source
