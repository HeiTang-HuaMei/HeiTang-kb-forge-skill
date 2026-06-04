from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

from heitang_kb_forge.ocr.cache import OCRPageCache
from heitang_kb_forge.ocr.page_selection import select_ocr_pages
from heitang_kb_forge.ocr.worker import OCRPageResult, ocr_pil_image, safe_worker_count
from heitang_kb_forge.parsers.pdf_preflight import preflight_pdf
from heitang_kb_forge.parsers.pdf_table_parser import PDF_TABLE_DEPENDENCY_WARNING, extract_pdf_tables
from heitang_kb_forge.progress.events import ProgressEvent

PDF_OCR_DEPENDENCY_ERROR = 'PDF OCR dependencies are not installed. Install with: pip install -e ".[ocr]"'
TEXT_OCR_THRESHOLD = 20


@dataclass
class PDFParseOptions:
    profile: str = "production"
    ocr_mode: str = "auto"
    ocr_lang: str = "chi_sim+eng"
    timeout_per_page: int = 120
    max_pages: int | None = None
    selected_pages: str | None = None
    workers: int = 1
    scale: float = 1.5
    cache_enabled: bool = False
    cache_dir: Path | None = None
    resume: bool = False
    skip_empty_pages: bool = True
    skip_low_text_pages: bool = False
    output_dir: Path | None = None
    performance_records: list[dict] = field(default_factory=list)
    failed_pages: list[dict] = field(default_factory=list)
    preflight_reports: list[dict] = field(default_factory=list)
    page_classifications: list[dict] = field(default_factory=list)
    cache_hits: int = 0
    cache_writes: int = 0


ProgressCallback = Callable[[ProgressEvent], None]


def parse_pdf(
    path: Path,
    *,
    progress_callback: ProgressCallback | None = None,
    options: PDFParseOptions | None = None,
) -> str:
    options_provided = options is not None
    options = options or PDFParseOptions()
    _emit(progress_callback, "extract_pdf_text", "running", "Extracting PDF text layer", current_file=str(path))
    text = _extract_text_pdf(path)
    if not _needs_ocr_fallback(text) and options.ocr_mode != "full":
        _emit(progress_callback, "extract_pdf_text", "success", "PDF text layer is sufficient", current_file=str(path))
        table_text, warnings = extract_pdf_tables(path)
        parts = [text]
        if table_text:
            parts.append(table_text)
        parts.extend(
            f"[Warning] {warning}"
            for warning in warnings
            if warning != PDF_TABLE_DEPENDENCY_WARNING and not warning.startswith("PDF table extraction failed for ")
        )
        _record_performance(options, path, total_pages=0, requested=0, completed=0, skipped=0)
        return "\n\n".join(part for part in parts if part)
    if options.ocr_mode == "off":
        warning = "OCR is disabled by --ocr-mode off."
        _emit(progress_callback, "ocr_pdf", "skipped", warning, current_file=str(path), warning=warning)
        _record_performance(options, path, total_pages=0, requested=0, completed=0, skipped=0)
        return text
    if not options_provided and progress_callback is None:
        return _ocr_pdf_pages(path)
    return _ocr_pdf_pages(
        path,
        progress_callback=progress_callback,
        ocr_lang=options.ocr_lang,
        timeout_per_page=options.timeout_per_page,
        max_pages=options.max_pages,
        ocr_mode=options.ocr_mode,
        selected_pages=options.selected_pages,
        workers=options.workers,
        scale=options.scale,
        cache_enabled=options.cache_enabled,
        cache_dir=options.cache_dir,
        resume=options.resume,
        skip_empty_pages=options.skip_empty_pages,
        skip_low_text_pages=options.skip_low_text_pages,
        options=options,
    )


def _extract_text_pdf(path: Path) -> str:
    try:
        from pypdf import PdfReader

        reader = PdfReader(path)
        pages = [page.extract_text() or "" for page in reader.pages]
    except Exception:
        return ""

    return "\n\n".join(page.strip() for page in pages if page.strip())


def _needs_ocr_fallback(text: str) -> bool:
    normalized = " ".join(text.split())
    return len(normalized) < TEXT_OCR_THRESHOLD


def _ocr_pdf_pages(
    path: Path,
    progress_callback: ProgressCallback | None = None,
    ocr_lang: str = "chi_sim+eng",
    timeout_per_page: int = 120,
    max_pages: int | None = None,
    ocr_mode: str = "auto",
    selected_pages: str | None = None,
    workers: int = 1,
    scale: float = 2.0,
    cache_enabled: bool = False,
    cache_dir: Path | None = None,
    resume: bool = False,
    skip_empty_pages: bool = True,
    skip_low_text_pages: bool = False,
    options: PDFParseOptions | None = None,
) -> str:
    try:
        import pypdfium2 as pdfium
        import pytesseract  # noqa: F401
    except ImportError as exc:
        raise RuntimeError(PDF_OCR_DEPENDENCY_ERROR) from exc

    try:
        document = pdfium.PdfDocument(path)
    except Exception as exc:
        raise RuntimeError(f"PDF OCR failed for {path}: {exc}") from exc

    total_pages = len(document)
    preflight_report, page_records = preflight_pdf(path, skip_empty_pages=skip_empty_pages, skip_low_text_pages=skip_low_text_pages)
    if options:
        options.preflight_reports.append(preflight_report)
        options.page_classifications.extend(page_records)
    needs_ocr = [int(page["page_index"]) for page in page_records if page["needs_ocr"]] if page_records else list(range(total_pages))
    selected = select_ocr_pages(
        mode=ocr_mode,
        total_pages=total_pages,
        needs_ocr_pages=needs_ocr,
        max_pages=max_pages,
        selected_pages=selected_pages,
    )
    _emit(progress_callback, "pdf_preflight", "success", "PDF preflight complete", current_file=str(path), total_pages=total_pages, metadata=preflight_report)
    _emit(progress_callback, "ocr_pdf", "started", f"OCR PDF pages: {len(selected)}/{total_pages}", current_file=str(path), total_pages=total_pages)

    cache = OCRPageCache(cache_dir or Path(".heitang_cache") / "ocr", path, ocr_lang, scale) if cache_enabled or resume else None
    page_results: list[OCRPageResult] = []
    failed_pages: list[dict] = []
    cache_hits = 0
    cache_writes = 0
    durations: list[dict] = []
    pending: list[tuple[int, object]] = []
    for page_index in selected:
        cached = cache.read(page_index) if cache else None
        if cached is not None:
            cache_hits += 1
            _emit(progress_callback, "ocr_cache_hit", "success", f"OCR cache hit page {page_index + 1}", current_file=str(path), current_page=page_index + 1, total_pages=total_pages)
            page_results.append(OCRPageResult(page_index=page_index, text=cached, duration_ms=0))
            continue
        _emit(progress_callback, "ocr_page", "running", f"OCR page {page_index + 1}/{total_pages}", current_file=str(path), current_page=page_index + 1, total_pages=total_pages)
        page = document[page_index]
        pending.append((page_index, page.render(scale=scale).to_pil()))

    worker_count = min(safe_worker_count(workers), max(1, len(pending)))
    if worker_count == 1:
        for page_index, pil_image in pending:
            result = ocr_pil_image(pil_image, page_index=page_index, ocr_lang=ocr_lang, timeout_per_page=timeout_per_page)
            _record_page_result(path, result, cache, progress_callback, total_pages, failed_pages, durations)
            if cache and result.text and not result.error:
                cache.write(result.page_index, result.text, result.duration_ms)
                cache_writes += 1
                _emit(progress_callback, "ocr_cache_write", "success", f"OCR cache write page {result.page_index + 1}", current_file=str(path), current_page=result.page_index + 1, total_pages=total_pages)
            page_results.append(result)
    else:
        with ThreadPoolExecutor(max_workers=worker_count) as executor:
            futures = {
                executor.submit(ocr_pil_image, pil_image, page_index=page_index, ocr_lang=ocr_lang, timeout_per_page=timeout_per_page): page_index
                for page_index, pil_image in pending
            }
            for future in as_completed(futures):
                result = future.result()
                _record_page_result(path, result, cache, progress_callback, total_pages, failed_pages, durations)
                if cache and result.text and not result.error:
                    cache.write(result.page_index, result.text, result.duration_ms)
                    cache_writes += 1
                    _emit(progress_callback, "ocr_cache_write", "success", f"OCR cache write page {result.page_index + 1}", current_file=str(path), current_page=result.page_index + 1, total_pages=total_pages)
                page_results.append(result)

    page_results = sorted(page_results, key=lambda item: item.page_index)
    completed = sum(1 for result in page_results if result.text)
    skipped = max(0, total_pages - len(selected))
    if options:
        options.failed_pages.extend(failed_pages)
        options.cache_hits += cache_hits
        options.cache_writes += cache_writes
        options.performance_records.append(
            {
                "source_type": "pdf",
                "source_path": str(path).replace("\\", "/"),
                "total_pages": total_pages,
                "ocr_pages_requested": len(selected),
                "ocr_pages_completed": completed,
                "ocr_pages_skipped": skipped,
                "ocr_cache_hits": cache_hits,
                "ocr_cache_writes": cache_writes,
                "ocr_failed_pages": len(failed_pages),
                "page_durations": durations,
            }
        )
    _emit(progress_callback, "ocr_pdf", "success", f"OCR PDF complete: {completed}/{len(selected)} pages", current_file=str(path), total_pages=total_pages)
    return "\n\n".join(result.text for result in page_results if result.text)


def _record_page_result(
    path: Path,
    result: OCRPageResult,
    cache: OCRPageCache | None,
    progress_callback: ProgressCallback | None,
    total_pages: int,
    failed_pages: list[dict],
    durations: list[dict],
) -> None:
    durations.append({"source_path": str(path).replace("\\", "/"), "page_index": result.page_index, "duration_ms": result.duration_ms})
    if result.error:
        item = {
            "source_path": str(path).replace("\\", "/"),
            "page_index": result.page_index,
            "error": result.error,
            "duration_ms": result.duration_ms,
            "retry_hint": "Enable --ocr-cache --resume and rerun after fixing OCR dependencies.",
        }
        failed_pages.append(item)
        _emit(progress_callback, "ocr_page", "warning", f"OCR page {result.page_index + 1} failed", current_file=str(path), current_page=result.page_index + 1, total_pages=total_pages, warning=result.error)
        return
    _emit(progress_callback, "ocr_page", "success", f"OCR page {result.page_index + 1}/{total_pages} complete", current_file=str(path), current_page=result.page_index + 1, total_pages=total_pages, duration_ms=result.duration_ms)


def _record_performance(options: PDFParseOptions, path: Path, total_pages: int, requested: int, completed: int, skipped: int) -> None:
    options.performance_records.append(
        {
            "source_type": "pdf",
            "source_path": str(path).replace("\\", "/"),
            "total_pages": total_pages,
            "ocr_pages_requested": requested,
            "ocr_pages_completed": completed,
            "ocr_pages_skipped": skipped,
            "ocr_cache_hits": 0,
            "ocr_cache_writes": 0,
            "ocr_failed_pages": 0,
            "page_durations": [],
        }
    )


def _emit(progress_callback: ProgressCallback | None, stage: str, status: str, message: str, **kwargs) -> None:
    if progress_callback:
        progress_callback(ProgressEvent(stage=stage, status=status, message=message, **kwargs))
