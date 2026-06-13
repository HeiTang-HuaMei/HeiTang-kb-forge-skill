from __future__ import annotations

from collections import Counter
from datetime import datetime, timezone
from hashlib import sha256
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.parser_backends.registry import list_backends


SCHEMA_VERSION = "document_batch_import.v1"

SUPPORTED_DOCUMENT_EXTENSIONS = {
    ".bmp",
    ".csv",
    ".docx",
    ".htm",
    ".html",
    ".jpeg",
    ".jpg",
    ".markdown",
    ".md",
    ".pdf",
    ".png",
    ".ppt",
    ".pptx",
    ".tif",
    ".tiff",
    ".tsv",
    ".txt",
    ".xlsx",
}

TEXT_EXTENSIONS = {".htm", ".html", ".markdown", ".md", ".txt"}
TABLE_EXTENSIONS = {".csv", ".tsv", ".xlsx"}
IMAGE_EXTENSIONS = {".bmp", ".jpeg", ".jpg", ".png", ".tif", ".tiff"}
OFFICE_EXTENSIONS = {".docx", ".ppt", ".pptx", ".xlsx"}


def preflight_documents(input_path: Path, output: Path, default_backend: str = "builtin") -> dict[str, Any]:
    report = build_document_preflight(input_path, default_backend)
    write_document_preflight_outputs(report, output, include_batch_report=False)
    return report


def batch_import_documents(input_path: Path, output: Path, default_backend: str = "builtin") -> dict[str, Any]:
    report = build_document_preflight(input_path, default_backend)
    batch_report = make_batch_import_report(report)
    write_document_preflight_outputs(report, output, include_batch_report=True, batch_report=batch_report)
    return batch_report


def build_document_preflight(input_path: Path, default_backend: str = "builtin") -> dict[str, Any]:
    source_root = input_path if input_path.is_dir() else input_path.parent
    paths = _collect_document_paths(input_path)
    backend_rows = {row["name"]: row for row in list_backends()}
    fingerprint_index: dict[str, str] = {}
    files = []
    preflights = []
    recommendations = []

    for index, path in enumerate(paths, start=1):
        inventory = _inventory_row(path, source_root, index)
        fingerprint = inventory.get("sha256")
        if fingerprint and fingerprint in fingerprint_index:
            inventory["duplicate_of"] = fingerprint_index[fingerprint]
            inventory["status"] = "duplicate"
        elif fingerprint:
            fingerprint_index[fingerprint] = inventory["relative_path"]

        preflight = _preflight_row(inventory)
        recommendation = _backend_recommendation(preflight, backend_rows, default_backend)
        inventory["recommended_backend"] = recommendation["selected_backend"]
        inventory["backend_recommendation_status"] = recommendation["recommendation_status"]
        files.append(inventory)
        preflights.append(preflight)
        recommendations.append(recommendation)

    unsupported = [row for row in files if row["status"] == "unsupported"]
    duplicates = [row for row in files if row["status"] == "duplicate"]
    failed = [row for row in files if row["status"] == "failed"]
    ready = [row for row in files if row["status"] == "ready"]
    generated_at = datetime.now(timezone.utc).isoformat()
    status = "fail" if not files else "warning" if unsupported or duplicates or failed else "pass"
    return {
        "schema_version": SCHEMA_VERSION,
        "status": status,
        "generated_at": generated_at,
        "input_path": _safe_path(input_path),
        "default_backend": default_backend,
        "document_inventory": {
            "schema_version": f"{SCHEMA_VERSION}.inventory",
            "input_path": _safe_path(input_path),
            "total_files": len(files),
            "ready_count": len(ready),
            "unsupported_count": len(unsupported),
            "duplicate_count": len(duplicates),
            "failed_count": len(failed),
            "files": files,
        },
        "file_type_report": _file_type_report(files),
        "document_preflight": {
            "schema_version": f"{SCHEMA_VERSION}.preflight",
            "status": status,
            "files": preflights,
        },
        "backend_recommendation": {
            "schema_version": f"{SCHEMA_VERSION}.backend_recommendation",
            "status": status,
            "recommendations": recommendations,
        },
        "unsupported_file_report": _unsupported_file_report(unsupported),
    }


def make_batch_import_report(preflight_report: dict[str, Any]) -> dict[str, Any]:
    inventory = preflight_report["document_inventory"]
    files = inventory["files"]
    imported = [row for row in files if row["status"] in {"ready", "duplicate"}]
    failed = [row for row in files if row["status"] in {"unsupported", "failed"}]
    status = "completed" if files and not failed else "completed_with_issues" if imported else "failed"
    items = []
    for row in files:
        item_status = "imported" if row["status"] == "ready" else row["status"]
        items.append(
            {
                "item_id": f"doc-{row['index']:04d}",
                "source_path": row["source_path"],
                "relative_path": row["relative_path"],
                "status": item_status,
                "file_type": row["file_type"],
                "recommended_backend": row.get("recommended_backend"),
                "duplicate_of": row.get("duplicate_of"),
                "error": row.get("error"),
            }
        )
    return {
        "schema_version": f"{SCHEMA_VERSION}.batch_import_report",
        "status": status,
        "input_path": preflight_report["input_path"],
        "total_files": inventory["total_files"],
        "imported_count": len(imported),
        "failed_count": len(failed),
        "unsupported_count": inventory["unsupported_count"],
        "duplicate_count": inventory["duplicate_count"],
        "single_file_failure_isolated": True,
        "llm_required": False,
        "items": items,
        "output_files": [
            "document_inventory.json",
            "file_type_report.json",
            "document_preflight.json",
            "backend_recommendation.json",
            "unsupported_file_report.json",
            "unsupported_file_report.md",
            "preflight_report.md",
            "batch_import_report.json",
            "batch_import_report.md",
            "batch_import_log.jsonl",
        ],
    }


def write_document_preflight_outputs(
    report: dict[str, Any],
    output: Path,
    *,
    include_batch_report: bool,
    batch_report: dict[str, Any] | None = None,
) -> None:
    output.mkdir(parents=True, exist_ok=True)
    write_json(output / "document_inventory.json", report["document_inventory"])
    write_json(output / "file_type_report.json", report["file_type_report"])
    write_json(output / "document_preflight.json", report["document_preflight"])
    write_json(output / "backend_recommendation.json", report["backend_recommendation"])
    write_json(output / "unsupported_file_report.json", report["unsupported_file_report"])
    (output / "unsupported_file_report.md").write_text(
        render_unsupported_file_report(report["unsupported_file_report"]),
        encoding="utf-8",
    )
    (output / "preflight_report.md").write_text(render_preflight_report(report), encoding="utf-8")
    if include_batch_report:
        batch_report = batch_report or make_batch_import_report(report)
        write_json(output / "batch_import_report.json", batch_report)
        (output / "batch_import_report.md").write_text(render_batch_import_report(batch_report), encoding="utf-8")
        write_jsonl(output / "batch_import_log.jsonl", batch_report["items"])


def render_preflight_report(report: dict[str, Any]) -> str:
    inventory = report["document_inventory"]
    lines = [
        "# Document Preflight Report",
        "",
        f"- Status: `{report['status']}`",
        f"- Input: `{report['input_path']}`",
        f"- Total files: `{inventory['total_files']}`",
        f"- Ready: `{inventory['ready_count']}`",
        f"- Unsupported: `{inventory['unsupported_count']}`",
        f"- Duplicates: `{inventory['duplicate_count']}`",
        f"- Failed: `{inventory['failed_count']}`",
        "",
        "| File | Type | OCR | Tables | Recommendation | Status |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    recommendations = {
        row["relative_path"]: row for row in report["backend_recommendation"]["recommendations"]
    }
    for row in report["document_preflight"]["files"]:
        rec = recommendations[row["relative_path"]]
        lines.append(
            f"| {row['relative_path']} | {row['file_type']} | "
            f"{str(row['needs_ocr']).lower()} | {str(row['contains_tables']).lower()} | "
            f"{rec['selected_backend']} | {row['status']} |"
        )
    return "\n".join(lines).rstrip() + "\n"


def render_unsupported_file_report(report: dict[str, Any]) -> str:
    lines = [
        "# Unsupported File Report",
        "",
        f"- Status: `{report['status']}`",
        f"- Unsupported count: `{report['unsupported_count']}`",
        "",
    ]
    if not report["files"]:
        lines.append("- No unsupported files detected.")
    else:
        lines.extend(["| File | Extension | Reason |", "| --- | --- | --- |"])
        for row in report["files"]:
            lines.append(f"| {row['relative_path']} | {row['extension']} | {row['reason']} |")
    return "\n".join(lines).rstrip() + "\n"


def render_batch_import_report(report: dict[str, Any]) -> str:
    lines = [
        "# Batch Import Report",
        "",
        f"- Status: `{report['status']}`",
        f"- Total files: `{report['total_files']}`",
        f"- Imported: `{report['imported_count']}`",
        f"- Failed: `{report['failed_count']}`",
        f"- Unsupported: `{report['unsupported_count']}`",
        f"- Duplicates: `{report['duplicate_count']}`",
        f"- Single file failure isolated: `{str(report['single_file_failure_isolated']).lower()}`",
        f"- LLM required: `{str(report['llm_required']).lower()}`",
        "",
        "| Item | File | Backend | Status | Error |",
        "| --- | --- | --- | --- | --- |",
    ]
    for item in report["items"]:
        lines.append(
            f"| {item['item_id']} | {item['relative_path']} | {item.get('recommended_backend')} | "
            f"{item['status']} | {item.get('error') or ''} |"
        )
    return "\n".join(lines).rstrip() + "\n"


def _collect_document_paths(input_path: Path) -> list[Path]:
    if input_path.is_file():
        return [input_path]
    return sorted(path for path in input_path.rglob("*") if path.is_file())


def _inventory_row(path: Path, source_root: Path, index: int) -> dict[str, Any]:
    suffix = path.suffix.lower()
    row = {
        "index": index,
        "source_path": _safe_path(path),
        "relative_path": _relative_path(path, source_root),
        "filename": path.name,
        "extension": suffix,
        "file_type": _file_type(suffix),
        "size_bytes": 0,
        "sha256": None,
        "status": "ready" if suffix in SUPPORTED_DOCUMENT_EXTENSIONS else "unsupported",
        "error": None,
        "duplicate_of": None,
    }
    try:
        data = path.read_bytes()
        row["size_bytes"] = len(data)
        row["sha256"] = sha256(data).hexdigest()
    except Exception as exc:
        row["status"] = "failed"
        row["error"] = f"read_failed:{exc}"
    if suffix not in SUPPORTED_DOCUMENT_EXTENSIONS and row["status"] != "failed":
        row["error"] = "unsupported_file_extension"
    return row


def _preflight_row(inventory: dict[str, Any]) -> dict[str, Any]:
    suffix = inventory["extension"]
    name = inventory["filename"].lower()
    is_image = suffix in IMAGE_EXTENSIONS
    is_pdf = suffix == ".pdf"
    contains_tables = suffix in TABLE_EXTENSIONS or "table" in name
    contains_images = is_image or suffix in {".ppt", ".pptx"} or any(marker in name for marker in ["image", "figure"])
    contains_formulas = any(marker in name for marker in ["formula", "equation"])
    multi_column = any(marker in name for marker in ["multi", "column", "layout", "complex"])
    is_scanned = is_image or (is_pdf and any(marker in name for marker in ["scan", "scanned", "ocr", "image"]))
    mixed_layout = is_pdf and (contains_tables or contains_images or contains_formulas or multi_column)
    return {
        "source_path": inventory["source_path"],
        "relative_path": inventory["relative_path"],
        "extension": suffix,
        "file_type": inventory["file_type"],
        "status": inventory["status"],
        "is_scanned": is_scanned,
        "contains_tables": contains_tables,
        "contains_images": contains_images,
        "contains_formulas": contains_formulas,
        "multi_column_layout": multi_column,
        "mixed_layout_document": mixed_layout,
        "needs_ocr": is_scanned,
        "duplicate_of": inventory.get("duplicate_of"),
        "error": inventory.get("error"),
    }


def _backend_recommendation(
    preflight: dict[str, Any],
    backend_rows: dict[str, dict[str, Any]],
    default_backend: str,
) -> dict[str, Any]:
    suffix = preflight["extension"]
    selected = _select_backend(preflight, default_backend)
    backend_row = backend_rows.get(selected) if selected else None
    contract = backend_row.get("capability_contract", {}) if backend_row else {}
    selected_available = bool(backend_row.get("available")) if backend_row else False
    fallback_backend = "builtin" if _builtin_supports(suffix) else None
    recommendation_status = (
        "unsupported"
        if preflight["status"] == "unsupported"
        else "failed"
        if preflight["status"] == "failed"
        else "available"
        if selected_available
        else "dependency_missing"
        if contract.get("dependency_status") == "missing"
        else "manual_review_required"
    )
    return {
        "source_path": preflight["source_path"],
        "relative_path": preflight["relative_path"],
        "selected_backend": selected,
        "selected_backend_available": selected_available,
        "dependency_status": contract.get("dependency_status"),
        "runtime_status": contract.get("runtime_status"),
        "integration_decision": contract.get("integration_decision"),
        "fallback_backend": fallback_backend,
        "recommendation_status": recommendation_status,
        "review_required": preflight["status"] != "ready" or not selected_available or preflight["mixed_layout_document"],
        "reason": _recommendation_reason(preflight, selected),
        "repair_suggestion": contract.get("repair_suggestion")
        or "Install the selected optional backend, choose backend=builtin for supported text sources, or mark for manual review.",
    }


def _select_backend(preflight: dict[str, Any], default_backend: str) -> str | None:
    if preflight["status"] in {"unsupported", "failed"}:
        return None
    suffix = preflight["extension"]
    if preflight["needs_ocr"]:
        return "paddleocr"
    if suffix == ".pdf" and preflight["mixed_layout_document"]:
        return "mineru"
    if suffix == ".pdf":
        return "docling"
    if suffix in TABLE_EXTENSIONS:
        return "builtin"
    if suffix in OFFICE_EXTENSIONS:
        return "docling"
    if suffix in TEXT_EXTENSIONS:
        return default_backend
    return default_backend


def _recommendation_reason(preflight: dict[str, Any], selected: str | None) -> str:
    if selected is None:
        return preflight.get("error") or "unsupported_or_failed_source"
    if preflight["needs_ocr"]:
        return "ocr_required"
    if preflight["mixed_layout_document"]:
        return "complex_layout_or_table_document"
    if preflight["file_type"] == "table_document":
        return "table_document_builtin_parser"
    if preflight["file_type"] == "office_document":
        return "office_document_adapter_preferred"
    return "basic_text_or_default_document_path"


def _file_type_report(files: list[dict[str, Any]]) -> dict[str, Any]:
    by_extension = Counter(row["extension"] or "<none>" for row in files)
    by_type = Counter(row["file_type"] for row in files)
    return {
        "schema_version": f"{SCHEMA_VERSION}.file_type_report",
        "status": "pass" if files else "warning",
        "counts_by_extension": dict(sorted(by_extension.items())),
        "counts_by_file_type": dict(sorted(by_type.items())),
        "total_files": len(files),
    }


def _unsupported_file_report(files: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "schema_version": f"{SCHEMA_VERSION}.unsupported_file_report",
        "status": "warning" if files else "pass",
        "unsupported_count": len(files),
        "files": [
            {
                "source_path": row["source_path"],
                "relative_path": row["relative_path"],
                "extension": row["extension"],
                "reason": row.get("error") or "unsupported_file_extension",
            }
            for row in files
        ],
    }


def _file_type(suffix: str) -> str:
    if suffix == ".pdf":
        return "pdf"
    if suffix in TEXT_EXTENSIONS:
        return "text_document"
    if suffix in TABLE_EXTENSIONS:
        return "table_document"
    if suffix in IMAGE_EXTENSIONS:
        return "image_or_scanned_document"
    if suffix in OFFICE_EXTENSIONS:
        return "office_document"
    return "unsupported"


def _builtin_supports(suffix: str) -> bool:
    return suffix in SUPPORTED_DOCUMENT_EXTENSIONS - {".tif", ".tiff", ".bmp"}


def _relative_path(path: Path, source_root: Path) -> str:
    try:
        return path.relative_to(source_root).as_posix()
    except ValueError:
        return path.name


def _safe_path(path: Path) -> str:
    return str(path).replace("\\", "/")
