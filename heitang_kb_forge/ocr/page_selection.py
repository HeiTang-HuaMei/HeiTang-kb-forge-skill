from __future__ import annotations


def parse_page_ranges(value: str | None) -> set[int]:
    if not value:
        return set()
    pages: set[int] = set()
    for part in value.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            start_raw, end_raw = part.split("-", 1)
            start = int(start_raw)
            end = int(end_raw)
            pages.update(range(start - 1, end))
        else:
            pages.add(int(part) - 1)
    return {page for page in pages if page >= 0}


def select_ocr_pages(
    *,
    mode: str,
    total_pages: int,
    needs_ocr_pages: list[int],
    max_pages: int | None = None,
    selected_pages: str | None = None,
) -> list[int]:
    if mode == "off":
        return []
    if mode == "selected-pages":
        pages = sorted(page for page in parse_page_ranges(selected_pages) if page < total_pages)
    elif mode == "first-pages":
        limit = max_pages or total_pages
        pages = list(range(min(limit, total_pages)))
    elif mode == "full":
        pages = list(range(total_pages))
    else:
        pages = sorted(page for page in needs_ocr_pages if page < total_pages)
    if max_pages is not None and mode != "selected-pages":
        pages = pages[:max_pages]
    return pages
