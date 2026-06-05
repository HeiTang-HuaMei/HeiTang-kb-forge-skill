from pathlib import Path
from zipfile import ZipFile

from heitang_kb_forge.parsers.hardening.html_parser import _TextHTMLParser


def parse_epub(path: Path) -> str:
    try:
        sections: list[str] = []
        with ZipFile(path) as archive:
            for name in sorted(archive.namelist()):
                if not name.lower().endswith((".html", ".htm", ".xhtml")):
                    continue
                parser = _TextHTMLParser()
                parser.feed(archive.read(name).decode("utf-8", errors="ignore"))
                text = "\n".join(parser.parts).strip()
                if text:
                    sections.append(f"EPUB Section: {name}\n{text}")
        return "\n\n".join(sections)
    except Exception:
        return ""
