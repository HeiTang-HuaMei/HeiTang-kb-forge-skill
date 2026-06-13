from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
from html import unescape
from importlib.util import find_spec
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any

from heitang_kb_forge.parser_backends.base import ParserBackend, ParserBackendRecord, failure_metadata
from heitang_kb_forge.parser_backends.model_cache import resolve_backend_model_cache
from heitang_kb_forge.parser_backends.normalize import column_safe_path, normalize_text, source_type


class MarkerParserBackend(ParserBackend):
    name = "marker"
    version = "optional"
    description = "Optional Marker CLI adapter for local PDF document understanding without LLM use."
    supported_extensions = frozenset({".pdf"})
    adapter_type = "document_understanding"
    optional_dependency = "marker"
    optional_extra = "parser-marker"
    integration_decision = "real_integration"
    validated_extensions = frozenset({".pdf"})
    supported_outputs = ("normalized_text", "markdown", "layout_json")
    ocr_support = "supported"
    layout_support = "supported"
    table_support = "partial"
    figure_support = "partial"
    formula_support = "partial"
    reading_order_support = "supported"

    def __init__(self, cache_dir: Path | str | None = None) -> None:
        self.cache_dir = resolve_backend_model_cache(self.name, cache_dir)

    def is_available(self) -> tuple[bool, str | None]:
        if find_spec("marker") is None or _find_marker_cli() is None:
            return (
                False,
                "Optional dependency 'marker-pdf' or marker_single CLI is not installed. "
                "Install the parser-marker extra or use backend=builtin.",
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
                [reason or "marker_adapter_unavailable"],
                0.0,
                False,
                "optional_runtime_dependency_missing",
            )
        try:
            with TemporaryDirectory(prefix="heitang_marker_") as tmp:
                output_dir = Path(tmp) / "marker_output"
                _run_marker(path, output_dir, self.cache_dir)
                normalized = _normalize_marker_output(output_dir)
        except Exception as exc:
            return _record(
                self,
                path,
                command,
                "failed",
                [f"marker_parse_failed:{exc}"],
                0.0,
                True,
                "backend_runtime_exception",
            )
        text = normalized["text"]
        metadata = {
            "adapter": self.name,
            "runtime_invoked": True,
            "use_llm": False,
            "llm_request_count": normalized["llm_request_count"],
            "llm_error_count": normalized["llm_error_count"],
            "llm_tokens_used": normalized["llm_tokens_used"],
            "model_cache_path": str(self.cache_dir),
            "output_json_count": normalized["json_count"],
            "output_meta_json_count": normalized["meta_json_count"],
            "output_schema_readable": normalized["output_schema_readable"],
            "layout_block_count": normalized["layout_block_count"],
            "table_count": normalized["table_count"],
            "figure_count": normalized["figure_count"],
            "formula_count": normalized["formula_count"],
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
            confidence=0.87 if text else 0.0,
            metadata=metadata
            if text
            else {
                **metadata,
                **failure_metadata(
                    self.name,
                    "empty_parse_result",
                    fallback_result="manual_review_required",
                    repair_suggestion=(
                        "Inspect Marker JSON output, verify model cache availability, "
                        "or rerun with another verified document backend."
                    ),
                ),
            },
        )


def _find_marker_cli() -> str | None:
    executable = shutil.which("marker_single")
    if executable:
        return executable
    scripts_dir = Path(sys.executable).resolve().parent
    for name in ("marker_single.exe", "marker_single"):
        candidate = scripts_dir / name
        if candidate.is_file():
            return str(candidate)
    return None


def _run_marker(path: Path, output_dir: Path, cache_dir: Path) -> None:
    executable = _find_marker_cli()
    if executable is None:
        raise RuntimeError("marker_single_cli_not_found")
    output_dir.mkdir(parents=True, exist_ok=True)
    command = [
        executable,
        str(path),
        "--output_dir",
        str(output_dir),
        "--output_format",
        "json",
        "--disable_multiprocessing",
        "--disable_image_extraction",
    ]
    environment = os.environ.copy()
    environment["TORCH_DEVICE"] = "cpu"
    cache_dir.mkdir(parents=True, exist_ok=True)
    environment["HEITANG_MARKER_MODEL_CACHE"] = str(cache_dir)
    environment["MODEL_CACHE_DIR"] = str(cache_dir)
    result = subprocess.run(
        command,
        cwd=Path.cwd(),
        env=environment,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=900,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or f"exit_code={result.returncode}").strip()
        raise RuntimeError(detail[:500])


def _normalize_marker_output(output_dir: Path) -> dict[str, Any]:
    json_files = sorted(path for path in output_dir.rglob("*.json") if not path.name.endswith("_meta.json"))
    meta_files = sorted(output_dir.rglob("*_meta.json"))
    text_values: list[str] = []
    readable_json_count = 0
    counters = {
        "layout_block_count": 0,
        "table_count": 0,
        "figure_count": 0,
        "formula_count": 0,
        "reading_order_available": False,
        "first_page": None,
    }
    for path in json_files:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        readable_json_count += 1
        _walk_marker_payload(payload, text_values, counters)
    llm_counts = {
        "llm_request_count": 0,
        "llm_error_count": 0,
        "llm_tokens_used": 0,
    }
    readable_meta_count = 0
    for path in meta_files:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        readable_meta_count += 1
        for page_stat in payload.get("page_stats", []):
            block_metadata = page_stat.get("block_metadata", {})
            for key in llm_counts:
                llm_counts[key] += int(block_metadata.get(key, 0) or 0)
    text = normalize_text("\n".join(dict.fromkeys(value for value in text_values if value)))
    return {
        "text": text,
        "json_count": len(json_files),
        "meta_json_count": len(meta_files),
        "output_schema_readable": (
            bool(json_files)
            and readable_json_count == len(json_files)
            and readable_meta_count == len(meta_files)
        ),
        **llm_counts,
        **counters,
    }


def _walk_marker_payload(value: Any, text_values: list[str], counters: dict[str, Any]) -> None:
    if isinstance(value, dict):
        block_type = str(value.get("block_type") or value.get("type") or "")
        lowered = block_type.lower()
        if block_type:
            counters["layout_block_count"] += 1
        if "table" in lowered:
            counters["table_count"] += 1
        if any(marker in lowered for marker in ("picture", "figure", "image")):
            counters["figure_count"] += 1
        if any(marker in lowered for marker in ("equation", "formula", "math")):
            counters["formula_count"] += 1
        identifier = str(value.get("id") or "")
        match = re.search(r"/page/(\d+)/", identifier, flags=re.IGNORECASE)
        if match:
            page = int(match.group(1)) + 1
            if counters["first_page"] is None:
                counters["first_page"] = page
        children = value.get("children")
        if isinstance(children, list) and children:
            counters["reading_order_available"] = True
        html = value.get("html")
        if isinstance(html, str):
            plain = normalize_text(unescape(re.sub(r"<[^>]+>", " ", html)))
            if plain:
                text_values.append(plain)
        for item in value.values():
            _walk_marker_payload(item, text_values, counters)
    elif isinstance(value, list):
        for item in value:
            _walk_marker_payload(item, text_values, counters)


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
            "use_llm": False,
            "model_cache_path": str(getattr(backend, "cache_dir", resolve_backend_model_cache("marker"))),
            **failure_metadata(
                backend.name,
                error_code,
                repair_suggestion=(
                    "Install parser-marker, verify marker_single and local model availability, "
                    "or use another verified document backend."
                ),
            ),
        },
    )
