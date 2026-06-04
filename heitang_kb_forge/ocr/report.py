from __future__ import annotations

from pathlib import Path
from typing import Any


def make_performance_report(records: list[dict[str, Any]]) -> str:
    pdf_count = sum(1 for item in records if item.get("source_type") == "pdf")
    total_pages = sum(int(item.get("total_pages", 0) or 0) for item in records)
    requested = sum(int(item.get("ocr_pages_requested", 0) or 0) for item in records)
    completed = sum(int(item.get("ocr_pages_completed", 0) or 0) for item in records)
    skipped = sum(int(item.get("ocr_pages_skipped", 0) or 0) for item in records)
    hits = sum(int(item.get("ocr_cache_hits", 0) or 0) for item in records)
    writes = sum(int(item.get("ocr_cache_writes", 0) or 0) for item in records)
    failed = sum(int(item.get("ocr_failed_pages", 0) or 0) for item in records)
    durations = [int(page.get("duration_ms", 0) or 0) for item in records for page in item.get("page_durations", [])]
    average = int(sum(durations) / len(durations)) if durations else 0
    slowest = sorted(
        [
            (page.get("source_path", item.get("source_path")), page.get("page_index"), page.get("duration_ms"))
            for item in records
            for page in item.get("page_durations", [])
        ],
        key=lambda item: int(item[2] or 0),
        reverse=True,
    )[:5]
    slowest_rows = "\n".join(f"- {Path(str(source)).name} page {int(page) + 1}: {duration} ms" for source, page, duration in slowest) or "- None"
    return f"""# Large File Performance Report

## Summary

- Source count: {len(records)}
- PDF count: {pdf_count}
- Total pages: {total_pages}
- OCR pages requested: {requested}
- OCR pages completed: {completed}
- OCR pages skipped: {skipped}
- OCR cache hits: {hits}
- OCR cache writes: {writes}
- OCR failed pages: {failed}
- Average duration per OCR page: {average} ms

## Slowest Pages

{slowest_rows}

## Recommendations

This report helps decide whether to run fast mode, production mode, increase workers, lower OCR scale, or use cache/resume.
"""


def make_resume_report(failed_pages: list[dict[str, Any]], cache_hits: int) -> str:
    failed = "\n".join(
        f"- {Path(item['source_path']).name} page {int(item['page_index']) + 1}: {item['error']}"
        for item in failed_pages
    ) or "- None"
    return f"""# OCR Resume Report

- Cache hits: {cache_hits}
- Failed pages: {len(failed_pages)}

## Failed Pages

{failed}
"""
