from __future__ import annotations

from importlib.util import find_spec
from pathlib import Path

from heitang_kb_forge.parser_backends.base import ParserBackend, ParserBackendRecord
from heitang_kb_forge.parser_backends.normalize import column_safe_path, source_type


class DoclingParserBackend(ParserBackend):
    name = "docling"
    version = "optional"
    description = "Optional Docling adapter. It is unavailable unless the local docling package is installed."

    def is_available(self) -> tuple[bool, str | None]:
        if find_spec("docling") is None:
            return False, "Optional dependency 'docling' is not installed. Install the parser-docling extra or use backend=builtin."
        return False, "Docling is installed, but this adapter intentionally requires an explicit local integration before live parsing."

    def parse_source(self, path: Path, command: str) -> ParserBackendRecord:
        available, reason = self.is_available()
        return ParserBackendRecord(
            source_path=column_safe_path(path),
            source_type=source_type(path),
            backend_name=self.name,
            backend_version=self.version,
            command=command,
            status="unavailable" if not available else "disabled",
            warnings=[reason or "docling_adapter_unavailable"],
            confidence=0.0,
        )

