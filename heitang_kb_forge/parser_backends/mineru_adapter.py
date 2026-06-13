from __future__ import annotations

import json
import shutil
import subprocess
import sys
from importlib.util import find_spec
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any

from heitang_kb_forge.parser_backends.base import ParserBackend, ParserBackendRecord, failure_metadata
from heitang_kb_forge.parser_backends.normalize import column_safe_path, normalize_text, source_type


class MinerUParserBackend(ParserBackend):
    name = "mineru"
    version = "optional"
    description = "Optional MinerU CLI adapter for local document understanding when mineru is installed."
    supported_extensions = frozenset({".bmp", ".docx", ".jpeg", ".jpg", ".pdf", ".png", ".pptx", ".tif", ".tiff", ".xlsx"})
    adapter_type = "document_understanding"
    optional_dependency = "mineru"
    optional_extra = "parser-mineru"
    integration_decision = "real_integration"
    validated_extensions = frozenset({".pdf", ".png"})
    supported_outputs = ("normalized_text", "markdown", "layout_json")
    ocr_support = "supported"
    layout_support = "supported"
    table_support = "partial"
    figure_support = "partial"
    formula_support = "partial"
    reading_order_support = "supported"

    def is_available(self) -> tuple[bool, str | None]:
        if find_spec("mineru") is None or _find_mineru_cli() is None:
            return (
                False,
                "Optional dependency 'mineru' or its CLI is not installed. "
                "Install the parser-mineru extra or use backend=builtin.",
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
                [reason or "mineru_adapter_unavailable"],
                0.0,
                False,
                "optional_runtime_dependency_missing",
            )
        try:
            with TemporaryDirectory(prefix="heitang_mineru_") as tmp:
                output_dir = Path(tmp) / "mineru_output"
                _run_mineru(path, output_dir)
                normalized = _normalize_mineru_output(output_dir)
        except Exception as exc:
            return _record(
                self,
                path,
                command,
                "failed",
                [f"mineru_parse_failed:{exc}"],
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
            confidence=0.86 if text else 0.0,
            metadata=metadata
            if text
            else {
                **metadata,
                **failure_metadata(
                    self.name,
                    "empty_parse_result",
                    fallback_result="manual_review_required",
                    repair_suggestion="Inspect MinerU output files, verify model/runtime availability, or rerun with backend=builtin for supported text sources.",
                ),
            },
        )


def _run_mineru(path: Path, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    executable = _find_mineru_cli()
    if executable is None:
        raise RuntimeError("mineru_cli_not_found")
    command = [
        executable,
        "-p",
        str(path),
        "-o",
        str(output_dir),
        "--backend",
        "pipeline",
        "--device",
        "cpu",
    ]
    result = subprocess.run(command, cwd=Path.cwd(), text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=300)
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or f"exit_code={result.returncode}").strip()
        raise RuntimeError(detail[:500])


def _find_mineru_cli() -> str | None:
    executable = shutil.which("mineru")
    if executable:
        return executable
    scripts_dir = Path(sys.executable).resolve().parent
    for name in ("mineru.exe", "mineru"):
        candidate = scripts_dir / name
        if candidate.is_file():
            return str(candidate)
    return None


def _normalize_mineru_output(output_dir: Path) -> dict[str, Any]:
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
            if key in {"text", "content", "md_content"} and isinstance(item, str):
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
        "formula_count": 0,
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
        block_type = str(value.get("type") or value.get("block_type") or value.get("category") or "").lower()
        if block_type:
            counters["layout_block_count"] += 1
        if "table" in block_type:
            counters["table_count"] += 1
        if any(marker in block_type for marker in ("image", "figure")):
            counters["figure_count"] += 1
        if "formula" in block_type or "equation" in block_type:
            counters["formula_count"] += 1
        if value.get("order") is not None or value.get("reading_order") is not None:
            counters["reading_order_available"] = True
        page = value.get("page") if value.get("page") is not None else value.get("page_idx")
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
                repair_suggestion="Install parser-mineru, verify local MinerU model/runtime availability, or rerun with backend=builtin for supported text sources.",
            ),
        },
    )
