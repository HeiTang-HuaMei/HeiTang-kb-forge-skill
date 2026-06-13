from __future__ import annotations

import shutil
from pathlib import Path

from heitang_kb_forge.parser_backends.base import ParserBackend, ParserBackendRecord
from heitang_kb_forge.parser_backends.model_cache import resolve_backend_model_cache
from heitang_kb_forge.parser_backends.normalize import column_safe_path, source_type


class SuryaParserBackend(ParserBackend):
    name = "surya"
    version = "optional"
    description = "Optional Surya OCR/layout benchmark adapter. It is not promoted as a primary parser backend."
    supported_extensions = frozenset({".jpeg", ".jpg", ".pdf", ".png", ".tif", ".tiff"})
    adapter_type = "document_understanding_benchmark"
    optional_dependency = "surya-ocr"
    optional_extra = "parser-surya"
    integration_decision = "needs_strengthening"
    validated_extensions = frozenset()
    supported_outputs = ("ocr_json", "layout_json", "table_json")
    ocr_support = "partial"
    layout_support = "partial"
    table_support = "partial"
    figure_support = "unknown"
    formula_support = "unknown"
    reading_order_support = "unknown"

    def __init__(self, cache_dir: Path | str | None = None) -> None:
        self.cache_dir = resolve_backend_model_cache(self.name, cache_dir)

    def is_available(self) -> tuple[bool, str | None]:
        missing = []
        if shutil.which("surya_ocr") is None:
            missing.append("surya_ocr")
        if shutil.which("vllm") is None and shutil.which("llama-server") is None:
            missing.append("vllm_or_llama_server")
        if missing:
            return (
                False,
                "Optional dependency 'surya-ocr' or its vllm/llama.cpp inference backend is not installed. "
                "Keep Surya as a benchmark candidate until dependency remediation and smoke evidence are complete.",
            )
        return False, "Surya dependencies are present, but this benchmark adapter is intentionally blocked before main parser promotion."

    def parse_source(self, path: Path, command: str) -> ParserBackendRecord:
        available, reason = self.is_available()
        return ParserBackendRecord(
            source_path=column_safe_path(path),
            source_type=source_type(path),
            backend_name=self.name,
            backend_version=self.version,
            command=command,
            status="unavailable" if not available else "disabled",
            warnings=[reason or "surya_benchmark_adapter_unavailable"],
            confidence=0.0,
            metadata={
                "adapter": self.name,
                "runtime_invoked": False,
                "model_cache_path": str(self.cache_dir),
            },
        )
