from heitang_kb_forge.ocr.page_selection import parse_page_ranges, select_ocr_pages


def test_parse_page_ranges_returns_zero_based_indexes():
    assert parse_page_ranges("1,3-5") == {0, 2, 3, 4}


def test_select_ocr_pages_supports_modes_and_limits():
    assert select_ocr_pages(mode="off", total_pages=5, needs_ocr_pages=[0, 1]) == []
    assert select_ocr_pages(mode="first-pages", total_pages=5, needs_ocr_pages=[], max_pages=2) == [0, 1]
    assert select_ocr_pages(mode="selected-pages", total_pages=5, needs_ocr_pages=[], selected_pages="2,4") == [1, 3]
    assert select_ocr_pages(mode="full", total_pages=3, needs_ocr_pages=[], max_pages=2) == [0, 1]
    assert select_ocr_pages(mode="auto", total_pages=5, needs_ocr_pages=[1, 3], max_pages=1) == [1]
