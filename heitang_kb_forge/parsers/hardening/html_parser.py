from html.parser import HTMLParser
from pathlib import Path


class _TextHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.parts: list[str] = []

    def handle_data(self, data: str) -> None:
        text = data.strip()
        if text:
            self.parts.append(text)


def parse_html(path: Path) -> str:
    try:
        parser = _TextHTMLParser()
        parser.feed(path.read_text(encoding="utf-8", errors="ignore"))
        return "\n".join(parser.parts)
    except Exception:
        return ""
