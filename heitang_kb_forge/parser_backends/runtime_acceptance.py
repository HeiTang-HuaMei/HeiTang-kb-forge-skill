from __future__ import annotations

from pathlib import Path
from typing import Sequence

from heitang_kb_forge.parser_backends.registry import collect_backend_sources, get_backend, parse_sources_with_backend


PARSER_RUNTIME_ACCEPTANCE_VERSION = "p2.1-parser-runtime.1"
PARSER_RUNTIME_BACKENDS = ("docling", "paddleocr", "unstructured")


def make_parser_runtime_acceptance_report(
    input_path: Path,
    backend_names: Sequence[str] | None = None,
    command: str = "parser-runtime-acceptance",
) -> dict:
    names = [name.strip().lower() for name in (backend_names or PARSER_RUNTIME_BACKENDS) if name.strip()]
    entries = [_backend_acceptance_entry(input_path, name, command) for name in names]
    status = _overall_status(entries)
    return {
        "acceptance_version": PARSER_RUNTIME_ACCEPTANCE_VERSION,
        "status": status,
        "live_runtime_completion_proven": status == "pass",
        "input": str(input_path),
        "required_backends": names,
        "entry_count": len(entries),
        "pass_count": sum(1 for entry in entries if entry["status"] == "pass"),
        "blocked_count": sum(1 for entry in entries if entry["status"] == "blocked"),
        "fail_count": sum(1 for entry in entries if entry["status"] == "fail"),
        "default_core_parser_changed": False,
        "external_runtime_bundled": False,
        "provider_network_api_required": False,
        "entries": entries,
    }


def render_parser_runtime_acceptance_report(report: dict) -> str:
    lines = [
        "# Parser Runtime Acceptance",
        "",
        f"- Status: {report['status']}",
        f"- Live runtime completion proven: {str(report['live_runtime_completion_proven']).lower()}",
        f"- Input: {report['input']}",
        f"- Backends: {', '.join(report['required_backends'])}",
        "",
        "## Backends",
        "",
    ]
    for entry in report["entries"]:
        blocker = f" | blocker: {entry['blocked_reason']}" if entry.get("blocked_reason") else ""
        lines.append(
            f"- {entry['backend_name']}: {entry['status']} | "
            f"dependency_available={str(entry['dependency_available']).lower()} | "
            f"runtime_invoked={str(entry['runtime_invoked']).lower()} | "
            f"text_length={entry['text_length']}{blocker}"
        )
    return "\n".join(lines).rstrip() + "\n"


def _backend_acceptance_entry(input_path: Path, backend_name: str, command: str) -> dict:
    backend = get_backend(backend_name)
    available, reason = backend.is_available()
    sources = collect_backend_sources(input_path, backend.name)
    run = parse_sources_with_backend(input_path, backend.name, command) if sources else None
    records = run.records if run is not None else []
    runtime_invoked_count = sum(1 for record in records if record.metadata.get("runtime_invoked") is True)
    text_length = sum(len(record.text) for record in records)
    warnings = list(run.warnings) if run is not None else []
    for record in records:
        warnings.extend(record.warnings)

    if not available:
        status = "blocked"
        blocked_reason = "optional_runtime_dependency_missing"
    elif not sources:
        status = "blocked"
        blocked_reason = "no_supported_sources"
    elif run is None:
        status = "fail"
        blocked_reason = "missing_parse_run"
    elif any(record.status == "failed" for record in records):
        status = "fail"
        blocked_reason = "runtime_parse_failed"
    elif runtime_invoked_count != len(records):
        status = "fail"
        blocked_reason = "runtime_not_invoked"
    elif text_length <= 0:
        status = "fail"
        blocked_reason = "no_text_extracted"
    elif run.status == "success":
        status = "pass"
        blocked_reason = None
    else:
        status = "fail"
        blocked_reason = f"unexpected_parse_status:{run.status}"

    return {
        "backend_name": backend.name,
        "backend_version": backend.version,
        "status": status,
        "blocked_reason": blocked_reason,
        "dependency_available": available,
        "dependency_reason": reason,
        "supported_extensions": sorted(backend.supported_extensions),
        "source_count": len(sources),
        "parse_status": run.status if run is not None else "not_run",
        "success_count": len([record for record in records if record.status == "success"]),
        "runtime_invoked": runtime_invoked_count == len(records) and bool(records),
        "runtime_invoked_count": runtime_invoked_count,
        "text_length": text_length,
        "warnings": warnings,
    }


def _overall_status(entries: list[dict]) -> str:
    if entries and all(entry["status"] == "pass" for entry in entries):
        return "pass"
    if any(entry["status"] == "fail" for entry in entries):
        return "fail"
    return "blocked"
