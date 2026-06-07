from __future__ import annotations

from pathlib import Path


def select_parser_backend(path: Path) -> dict:
    suffix = path.suffix.lower()
    name = path.name.lower()
    if suffix == ".pdf" and ("scan" in name or "image" in name):
        return _selection(path, "ocr_required", "scanned_or_image_pdf", 0.45, True)
    if suffix == ".pdf" and any(marker in name for marker in ["table", "formula", "layout", "complex"]):
        return _selection(path, "complex_parser_required", "complex_layout_or_formula_pdf", 0.5, True)
    if suffix == ".pdf":
        return _selection(path, "lightweight_local_pdf_text_scan", "text_pdf", 0.7, False)
    if suffix in {".md", ".txt"}:
        return _selection(path, "builtin_text_markdown", "text_document", 0.95, False)
    if suffix in {".docx", ".pptx", ".xlsx"}:
        return _selection(path, "structured_document_adapter_required", "office_document", 0.55, True)
    return _selection(path, "fallback_review_required", "unknown_or_unsupported", 0.2, True)


def build_parser_backend_benchmark(paths: list[Path]) -> dict:
    rows = []
    for path in paths:
        selected = select_parser_backend(path)
        rows.append(
            {
                "backend_name": selected["selected_backend"],
                "document_type": selected["document_type"],
                "source_path": path.as_posix(),
                "supported": selected["selected_backend"] not in {"fallback_review_required"},
                "confidence": selected["confidence"],
                "fallback_reason": selected["fallback_reason"],
                "token_reduction_estimate": selected["token_reduction_estimate"],
                "review_required": selected["review_required"],
                "no_upload_guarantee": True,
            }
        )
    return {
        "parser_backend_benchmark_report_version": "3.9.0-alpha.1",
        "benchmarks": rows,
        "mandatory_external_dependencies": [],
        "optional_future_adapters": ["LiteDoc", "PaddleOCR", "MinerU", "Marker", "Docling"],
        "tests_require_real_llm_api_network": False,
    }


def _selection(path: Path, backend: str, document_type: str, confidence: float, review_required: bool) -> dict:
    return {
        "parser_backend_selection_report_version": "3.9.0-alpha.1",
        "source_path": path.as_posix(),
        "selected_backend": backend,
        "document_type": document_type,
        "confidence": confidence,
        "fallback_reason": "review_required" if review_required else "none",
        "review_required": review_required,
        "token_reduction_estimate": 0.65 if path.suffix.lower() == ".pdf" else 0.25,
        "no_cloud_upload": True,
    }
