from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.parser_backends.base import ParserBackend, ParserBackendRun, skipped_record_from_contract
from heitang_kb_forge.parser_backends.builtin_adapter import BUILTIN_PARSERS, BuiltinParserBackend
from heitang_kb_forge.parser_backends.docling_adapter import DoclingParserBackend
from heitang_kb_forge.parser_backends.marker_adapter import MarkerParserBackend
from heitang_kb_forge.parser_backends.mineru_adapter import MinerUParserBackend
from heitang_kb_forge.parser_backends.opendataloader_adapter import OpenDataLoaderParserBackend
from heitang_kb_forge.parser_backends.paddleocr_adapter import PaddleOCRParserBackend
from heitang_kb_forge.parser_backends.surya_adapter import SuryaParserBackend
from heitang_kb_forge.parser_backends.unstructured_adapter import UnstructuredParserBackend


BACKENDS: dict[str, type[ParserBackend]] = {
    "builtin": BuiltinParserBackend,
    "docling": DoclingParserBackend,
    "marker": MarkerParserBackend,
    "mineru": MinerUParserBackend,
    "opendataloader": OpenDataLoaderParserBackend,
    "paddleocr": PaddleOCRParserBackend,
    "surya": SuryaParserBackend,
    "unstructured": UnstructuredParserBackend,
}


def get_backend(name: str) -> ParserBackend:
    normalized = name.strip().lower()
    backend_class = BACKENDS.get(normalized)
    if backend_class is None:
        raise ValueError(f"Unsupported parser backend: {name}")
    return backend_class()


def list_backends() -> list[dict]:
    rows = []
    for name in sorted(BACKENDS):
        backend = get_backend(name)
        available, reason = backend.is_available()
        contract = backend.capability_contract().model_dump(mode="json")
        rows.append(
            {
                "name": backend.name,
                "version": backend.version,
                "available": available,
                "status": "available" if available else "unavailable",
                "contract_status": contract["runtime_status"],
                "description": backend.description,
                "supported_extensions": sorted(backend.supported_extensions or frozenset(BUILTIN_PARSERS)),
                "reason": reason,
                "capability_contract": contract,
            }
        )
    return rows


def collect_backend_sources(input_path: Path, backend_name: str = "builtin") -> list[Path]:
    backend = get_backend(backend_name)
    supported_extensions = backend.supported_extensions or frozenset(BUILTIN_PARSERS)
    if input_path.is_file():
        return [input_path] if input_path.suffix.lower() in supported_extensions else []
    return sorted(path for path in input_path.rglob("*") if path.is_file() and path.suffix.lower() in supported_extensions)


def parse_sources_with_backend(input_path: Path, backend_name: str, command: str, sources: list[Path] | None = None) -> ParserBackendRun:
    try:
        backend = get_backend(backend_name)
    except ValueError:
        return ParserBackendRun(
            backend_name=backend_name.strip().lower(),
            backend_version="unknown",
            command=command,
            status="failed",
            source_count=0,
            records=[],
            warnings=[f"invalid_backend_id:{backend_name}"],
            error_code="invalid_backend_id",
            fallback_result="builtin_available",
            repair_suggestion="Run parser-backend-list or parser-backend-registry and retry with a listed backend_id.",
            audit_trace="parser_backends.registry.parse_sources_with_backend",
        )
    source_files = sources if sources is not None else collect_backend_sources(input_path, backend.name)
    available, reason = backend.is_available()
    contract = backend.capability_contract().model_dump(mode="json")
    warnings = [] if available else [reason or f"{backend.name}_unavailable"]
    if contract["integration_decision"] != "real_integration":
        warning = contract.get("fallback_reason") or reason or f"{backend.name}_adapter_not_integrated"
        records = [
            skipped_record_from_contract(
                backend,
                source,
                command,
                contract,
                warning=warning,
                error_code="adapter_not_integrated",
            )
            for source in source_files
        ]
        warnings = [warning] if source_files else warnings
    else:
        records = [backend.parse_source(source, command) for source in source_files]
        for record in records:
            record.adapter_contract = contract
    if not source_files:
        warnings.append("no_supported_sources")
    if not source_files:
        status = "warning"
    elif not available:
        status = "unavailable"
    elif any(record.status in {"disabled", "unavailable"} for record in records):
        status = "unavailable"
    elif any(record.status == "failed" for record in records):
        status = "warning"
    elif any(record.status in {"empty", "unsupported"} for record in records):
        status = "warning"
    else:
        status = "success"
    error_code = "unsupported_file_type" if not source_files else None
    return ParserBackendRun(
        backend_name=backend.name,
        backend_version=backend.version,
        command=command,
        status=status,
        source_count=len(source_files),
        records=records,
        warnings=warnings,
        error_code=error_code,
        fallback_result="builtin_available_when_supported" if error_code else None,
        repair_suggestion="Use a supported file extension or select a backend with matching supported_extensions." if error_code else None,
        audit_trace="parser_backends.registry.collect_backend_sources" if error_code else None,
        adapter_contract=contract,
    )
