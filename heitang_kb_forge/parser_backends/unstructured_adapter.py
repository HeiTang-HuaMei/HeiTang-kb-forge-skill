from __future__ import annotations

from importlib.util import find_spec
from pathlib import Path

from heitang_kb_forge.parser_backends.base import ParserBackend, ParserBackendRecord, failure_metadata
from heitang_kb_forge.parser_backends.normalize import column_safe_path, normalize_text, source_type


class UnstructuredParserBackend(ParserBackend):
    name = "unstructured"
    version = "optional"
    description = "Optional Unstructured runtime adapter using unstructured.partition.auto.partition when installed."
    supported_extensions = frozenset({".md", ".txt"})
    adapter_type = "document_parser"
    optional_dependency = "unstructured"
    optional_extra = "parser-unstructured"
    integration_decision = "real_integration"
    validated_extensions = frozenset({".md", ".txt"})
    supported_outputs = ("normalized_text",)
    reading_order_support = "partial"

    def is_available(self) -> tuple[bool, str | None]:
        if find_spec("unstructured") is None:
            return False, "Optional dependency 'unstructured' is not installed. Install the parser-unstructured extra or use backend=builtin."
        return True, None

    def parse_source(self, path: Path, command: str) -> ParserBackendRecord:
        available, reason = self.is_available()
        if not available:
            return _unavailable_record(self, path, command, reason or "unstructured_adapter_unavailable")
        try:
            from unstructured.partition.auto import partition

            elements = partition(filename=str(path))
            text = normalize_text("\n\n".join(_element_text(element) for element in elements if _element_text(element)))
        except Exception as exc:
            return _failed_record(self, path, command, f"unstructured_parse_failed:{exc}")
        warnings = [] if text else ["empty_text"]
        return ParserBackendRecord(
            source_path=column_safe_path(path),
            source_type=source_type(path),
            backend_name=self.name,
            backend_version=self.version,
            command=command,
            status="success" if text else "empty",
            text=text,
            warnings=warnings,
            confidence=0.86 if text else 0.0,
            metadata={"adapter": "unstructured", "runtime_invoked": True, "element_count": len(elements)}
            if text
            else {
                "adapter": "unstructured",
                "runtime_invoked": True,
                "element_count": len(elements),
                **failure_metadata(
                    self.name,
                    "empty_parse_result",
                    repair_suggestion="Check the source text or rerun with backend=builtin for supported Markdown/TXT sources.",
                ),
            },
        )


def _element_text(element: object) -> str:
    text = getattr(element, "text", None)
    if text is not None:
        return str(text).strip()
    return str(element).strip()


def _unavailable_record(backend: ParserBackend, path: Path, command: str, reason: str) -> ParserBackendRecord:
    return ParserBackendRecord(
        source_path=column_safe_path(path),
        source_type=source_type(path),
        backend_name=backend.name,
        backend_version=backend.version,
        command=command,
        status="unavailable",
        warnings=[reason],
        confidence=0.0,
        metadata={
            "adapter": backend.name,
            "runtime_invoked": False,
            **failure_metadata(backend.name, "optional_runtime_dependency_missing"),
        },
    )


def _failed_record(backend: ParserBackend, path: Path, command: str, warning: str) -> ParserBackendRecord:
    return ParserBackendRecord(
        source_path=column_safe_path(path),
        source_type=source_type(path),
        backend_name=backend.name,
        backend_version=backend.version,
        command=command,
        status="failed",
        warnings=[warning],
        confidence=0.0,
        metadata={
            "adapter": backend.name,
            "runtime_invoked": True,
            **failure_metadata(backend.name, "backend_runtime_exception"),
        },
    )
