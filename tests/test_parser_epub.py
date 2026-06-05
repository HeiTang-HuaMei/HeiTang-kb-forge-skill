from zipfile import ZipFile

from heitang_kb_forge.parsers.hardening import parse_epub


def test_epub_parser_extracts_html_sections(tmp_path):
    path = tmp_path / "sample.epub"
    with ZipFile(path, "w") as archive:
        archive.writestr("chapter1.xhtml", "<html><body>KB Forge EPUB Fixture</body></html>")

    text = parse_epub(path)

    assert "KB Forge EPUB Fixture" in text
    assert "EPUB Section" in text
