from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any

from heitang_kb_forge.parser_backends.base import ParserBackend, ParserBackendRecord, failure_metadata
from heitang_kb_forge.parser_backends.normalize import column_safe_path, normalize_text, source_type


class OpenDataLoaderParserBackend(ParserBackend):
    name = "opendataloader"
    version = "optional"
    description = "Optional OpenDataLoader PDF CLI adapter for local PDF to Markdown/JSON conversion."
    supported_extensions = frozenset({".pdf"})
    adapter_type = "document_understanding"
    optional_dependency = "opendataloader-pdf"
    optional_extra = "parser-opendataloader"
    integration_decision = "real_integration"
    validated_extensions = frozenset({".pdf"})
    supported_outputs = ("normalized_text", "markdown", "json")
    ocr_support = "unsupported"
    layout_support = "partial"
    table_support = "partial"
    figure_support = "partial"
    formula_support = "unknown"
    reading_order_support = "partial"

    def is_available(self) -> tuple[bool, str | None]:
        missing = []
        if shutil.which("opendataloader-pdf") is None:
            missing.append("opendataloader-pdf")
        if shutil.which("java") is None:
            missing.append("Java 11+")
        if missing:
            return (
                False,
                "Optional dependency 'opendataloader-pdf' or Java 11+ is not installed. "
                "Install the parser-opendataloader extra, ensure Java is on PATH, or use backend=builtin.",
            )
        return True, None

    def parse_source(self, path: Path, command: str) -> ParserBackendRecord:
        available, reason = self.is_available()
        if not available:
            return _record(
                self,
                path,
                command,
                "unavailable",
                [reason or "opendataloader_adapter_unavailable"],
                0.0,
                False,
                "optional_runtime_dependency_missing",
            )
        try:
            with TemporaryDirectory(prefix="heitang_opendataloader_") as tmp:
                output_dir = Path(tmp) / "opendataloader_output"
                _run_opendataloader(path, output_dir)
                normalized = _normalize_opendataloader_output(output_dir)
        except Exception as exc:
            return _record(
                self,
                path,
                command,
                "failed",
                [f"opendataloader_parse_failed:{exc}"],
                0.0,
                True,
                "backend_runtime_exception",
            )
        text = normalized["text"]
        metadata = {
            "adapter": self.name,
            "runtime_invoked": True,
            "output_markdown_count": normalized["markdown_count"],
            "output_json_count": normalized["json_count"],
            "layout_block_count": normalized["layout_block_count"],
            "table_count": normalized["table_count"],
            "figure_count": normalized["figure_count"],
            "reading_order_available": normalized["reading_order_available"],
            "page": normalized["first_page"],
        }
        return ParserBackendRecord(
            source_path=column_safe_path(path),
            source_type=source_type(path),
            backend_name=self.name,
            backend_version=self.version,
            command=command,
            status="success" if text else "empty",
            text=text,
            warnings=[] if text else ["empty_text"],
            confidence=0.84 if text else 0.0,
            metadata=metadata
            if text
            else {
                **metadata,
                **failure_metadata(
                    self.name,
                    "empty_parse_result",
                    fallback_result="manual_review_required",
                    repair_suggestion=(
                        "Inspect OpenDataLoader output files, verify the PDF is readable, "
                        "or rerun with backend=builtin for supported text sources."
                    ),
                ),
            },
        )


def _run_opendataloader(path: Path, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    command = ["opendataloader-pdf", str(path), "-o", str(output_dir), "-f", "json,markdown"]
    result = subprocess.run(command, cwd=Path.cwd(), text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or f"exit_code={result.returncode}").strip()
        raise RuntimeError(detail[:500])


def _normalize_opendataloader_output(output_dir: Path) -> dict[str, Any]:
    markdown_files = sorted(output_dir.rglob("*.md"))
    json_files = sorted(output_dir.rglob("*.json"))
    markdown_texts = [path.read_text(encoding="utf-8", errors="replace") for path in markdown_files]
    text = normalize_text("\n\n".join(item for item in markdown_texts if item.strip()))
    if not text:
        text = normalize_text(_json_text_fallback(json_files))
    counters = _count_json_features(json_files)
    return {
        "text": text,
        "markdown_count": len(markdown_files),
        "json_count": len(json_files),
        **counters,
    }


def _json_text_fallback(json_files: list[Path]) -> str:
    values: list[str] = []
    for path in json_files:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        _collect_json_text(payload, values)
    return "\n".join(values)


def _collect_json_text(value: Any, values: list[str]) -> None:
    if isinstance(value, dict):
        for key, item in value.items():
            if key in {"text", "content"} and isinstance(item, str):
                values.append(item)
            else:
                _collect_json_text(item, values)
    elif isinstance(value, list):
        for item in value:
            _collect_json_text(item, values)


def _count_json_features(json_files: list[Path]) -> dict[str, Any]:
    counters = {
        "layout_block_count": 0,
        "table_count": 0,
        "figure_count": 0,
        "reading_order_available": False,
        "first_page": None,
    }
    for path in json_files:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        _walk_feature_payload(payload, counters)
    return counters


def _walk_feature_payload(value: Any, counters: dict[str, Any]) -> None:
    if isinstance(value, dict):
        block_type = str(value.get("type") or "").lower()
        if block_type:
            counters["layout_block_count"] += 1
        if "table" in block_type:
            counters["table_count"] += 1
        if "image" in block_type or "figure" in block_type:
            counters["figure_count"] += 1
        if value.get("order") is not None or value.get("reading_order") is not None:
            counters["reading_order_available"] = True
        page = value.get("page number") if value.get("page number") is not None else value.get("page")
        if counters["first_page"] is None and page is not None:
            try:
                counters["first_page"] = int(page)
            except (TypeError, ValueError):
                counters["first_page"] = None
        for item in value.values():
            _walk_feature_payload(item, counters)
    elif isinstance(value, list):
        for item in value:
            _walk_feature_payload(item, counters)


def _record(
    backend: ParserBackend,
    path: Path,
    command: str,
    status: str,
    warnings: list[str],
    confidence: float,
    runtime_invoked: bool,
    error_code: str,
) -> ParserBackendRecord:
    return ParserBackendRecord(
        source_path=column_safe_path(path),
        source_type=source_type(path),
        backend_name=backend.name,
        backend_version=backend.version,
        command=command,
        status=status,
        warnings=warnings,
        confidence=confidence,
        metadata={
            "adapter": backend.name,
            "runtime_invoked": runtime_invoked,
            **failure_metadata(
                backend.name,
                error_code,
                repair_suggestion=(
                    "Install parser-opendataloader, ensure Java 11+ is on PATH, "
                    "or rerun with backend=builtin for supported text sources."
                ),
            ),
        },
    )
