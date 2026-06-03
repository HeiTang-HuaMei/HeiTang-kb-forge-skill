import builtins
import sys
import types

import pytest

from heitang_kb_forge.parsers.image_parser import OCR_DEPENDENCY_ERROR, parse_image


def test_image_parser_uses_ocr_text(monkeypatch, tmp_path):
    image_path = tmp_path / "sample.png"
    image_path.write_bytes(b"not a real image because OCR is mocked")

    class FakeImage:
        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc, tb):
            return None

    fake_pil = types.ModuleType("PIL")
    fake_image_module = types.SimpleNamespace(open=lambda path: FakeImage())
    fake_pil.Image = fake_image_module
    fake_tesseract = types.SimpleNamespace(image_to_string=lambda image: " OCR Image Fixture ")
    monkeypatch.setitem(sys.modules, "PIL", fake_pil)
    monkeypatch.setitem(sys.modules, "PIL.Image", fake_image_module)
    monkeypatch.setitem(sys.modules, "pytesseract", fake_tesseract)

    assert parse_image(image_path) == "OCR Image Fixture"


def test_image_parser_reports_missing_ocr_dependencies(monkeypatch, tmp_path):
    image_path = tmp_path / "sample.png"
    image_path.write_bytes(b"not a real image")
    original_import = builtins.__import__

    def fake_import(name, *args, **kwargs):
        if name in {"PIL", "pytesseract"}:
            raise ImportError(name)
        return original_import(name, *args, **kwargs)

    monkeypatch.setattr(builtins, "__import__", fake_import)

    with pytest.raises(RuntimeError, match=r"OCR dependencies are not installed"):
        parse_image(image_path)

    with pytest.raises(RuntimeError) as exc_info:
        parse_image(image_path)
    assert str(exc_info.value) == OCR_DEPENDENCY_ERROR
