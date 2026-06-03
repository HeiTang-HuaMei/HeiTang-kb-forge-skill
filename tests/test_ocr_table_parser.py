import sys
import types

from heitang_kb_forge.parsers.ocr_table import OCR_TABLE_WARNING, extract_image_table_text


def test_ocr_table_parser_groups_word_boxes(monkeypatch):
    data = {
        "text": ["Product", "Price", "Book", "59"],
        "conf": ["95", "95", "95", "95"],
        "left": [10, 100, 10, 100],
        "top": [10, 10, 30, 30],
        "width": [40, 40, 40, 20],
    }
    fake_pytesseract = types.SimpleNamespace(
        Output=types.SimpleNamespace(DICT="dict"),
        image_to_data=lambda image, output_type=None: data,
    )
    monkeypatch.setitem(sys.modules, "pytesseract", fake_pytesseract)

    text, warnings = extract_image_table_text(object(), page_label="Page 1")

    assert warnings == []
    assert "Page 1. OCR Table 1. Row 1. Column A: Product. Column B: Price." in text
    assert "Page 1. OCR Table 1. Row 2. Column A: Book. Column B: 59." in text


def test_ocr_table_parser_falls_back_when_data_unusable(monkeypatch):
    fake_pytesseract = types.SimpleNamespace(
        Output=types.SimpleNamespace(DICT="dict"),
        image_to_data=lambda image, output_type=None: {"text": [], "conf": [], "left": [], "top": [], "width": []},
    )
    monkeypatch.setitem(sys.modules, "pytesseract", fake_pytesseract)

    text, warnings = extract_image_table_text(object())

    assert text == ""
    assert warnings == [OCR_TABLE_WARNING]
