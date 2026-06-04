from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_installation_quickstart_and_ocr_docs_exist_and_cover_system_deps():
    install = (ROOT / "docs" / "INSTALLATION.md").read_text(encoding="utf-8")
    quickstart = (ROOT / "docs" / "QUICKSTART.md").read_text(encoding="utf-8")
    ocr = (ROOT / "docs" / "OCR_SETUP.md").read_text(encoding="utf-8")

    assert "python -m pip install -e ." in install
    assert ".[dev]" in install
    assert ".[ocr,pdf-table]" in install
    assert "Tesseract OCR itself is a system dependency" in install
    assert "doctor --output" in quickstart
    assert "tools export" in quickstart
    assert "tesseract --list-langs" in ocr
    assert "chi_sim" in ocr
    assert "Text-based PDF parsing is tried first" in ocr
