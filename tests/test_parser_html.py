from heitang_kb_forge.parsers.hardening import parse_html


def test_html_parser_extracts_text(tmp_path):
    path = tmp_path / "sample.html"
    path.write_text("<html><body><h1>KB Forge HTML Fixture</h1><p>main content</p></body></html>", encoding="utf-8")

    text = parse_html(path)

    assert "KB Forge HTML Fixture" in text
    assert "main content" in text
