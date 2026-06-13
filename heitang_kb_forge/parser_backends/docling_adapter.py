from __future__ import annotations

from importlib.util import find_spec
from pathlib import Path

from heitang_kb_forge.parser_backends.base import ParserBackend, ParserBackendRecord, failure_metadata
from heitang_kb_forge.parser_backends.normalize import column_safe_path, normalize_text, source_type


class DoclingParserBackend(ParserBackend):
    name = "docling"
    version = "optional"
    description = "Optional Docling runtime adapter using DocumentConverter when docling is installed."
    supported_extensions = frozenset({".docx", ".html", ".htm", ".md", ".pdf", ".pptx", ".txt"})
    adapter_type = "document_understanding"
    optional_dependency = "docling"
    optional_extra = "parser-docling"
    integration_decision = "real_integration"
    validated_extensions = frozenset({".md", ".txt"})
    supported_outputs = ("normalized_text", "markdown")
    layout_support = "unknown"
    table_support = "unknown"
    figure_support = "unknown"
    formula_support = "unknown"
    reading_order_support = "unknown"

    def is_available(self) -> tuple[bool, str | None]:
        if find_spec("docling") is None:
            return False, "Optional dependency 'docling' is not installed. Install the parser-docling extra or use backend=builtin."
        return True, None

    def parse_source(self, path: Path, command: str) -> ParserBackendRecord:
        available, reason = self.is_available()
        if not available:
            return ParserBackendRecord(
                source_path=column_safe_path(path),
                source_type=source_type(path),
                backend_name=self.name,
                backend_version=self.version,
                command=command,
                status="unavailable",
                warnings=[reason or "docling_adapter_unavailable"],
                confidence=0.0,
                metadata={
                    "adapter": "docling",
                    "runtime_invoked": False,
                    **failure_metadata(self.name, "optional_runtime_dependency_missing"),
                },
            )
        try:
            from docling.document_converter import DocumentConverter

            result = DocumentConverter().convert(str(path))
            text = normalize_text(_docling_result_text(result))
        except Exception as exc:
            return ParserBackendRecord(
                source_path=column_safe_path(path),
                source_type=source_type(path),
                backend_name=self.name,
                backend_version=self.version,
                command=command,
                status="failed",
                warnings=[f"docling_parse_failed:{exc}"],
                confidence=0.0,
                metadata={
                    "adapter": "docling",
                    "runtime_invoked": True,
                    **failure_metadata(self.name, "backend_runtime_exception"),
                },
            )
        return ParserBackendRecord(
            source_path=column_safe_path(path),
            source_type=source_type(path),
            backend_name=self.name,
            backend_version=self.version,
            command=command,
            status="success" if text else "empty",
            text=text,
            warnings=[] if text else ["empty_text"],
            confidence=0.88 if text else 0.0,
            metadata={"adapter": "docling", "runtime_invoked": True}
            if text
            else {
                "adapter": "docling",
                "runtime_invoked": True,
                **failure_metadata(self.name, "empty_parse_result"),
            },
        )


def _docling_result_text(result: object) -> str:
    document = getattr(result, "document", result)
    for method_name in ("export_to_markdown", "export_to_text"):
        method = getattr(document, method_name, None)
        if callable(method):
            text = method()
            if text:
                return str(text)
    text = getattr(document, "text", None)
    if text:
        return str(text)
    return str(document)
