from pathlib import Path
from zipfile import ZipFile

from heitang_kb_forge.parsers.hardening.html_parser import _TextHTMLParser


TEXT_SUFFIXES = {".md", ".markdown", ".txt", ".csv", ".tsv", ".html", ".htm"}


def parse_zip(path: Path) -> str:
    try:
        sections: list[str] = []
        with ZipFile(path) as archive:
            for name in sorted(archive.namelist()):
                suffix = Path(name).suffix.lower()
                if suffix not in TEXT_SUFFIXES:
                    continue
                raw = archive.read(name).decode("utf-8", errors="ignore")
                text = _html_text(raw) if suffix in {".html", ".htm"} else raw.strip()
                if text:
                    sections.append(f"ZIP Source: {name}\n{text}")
        return "\n\n".join(sections)
    except Exception:
        return ""


def _html_text(raw: str) -> str:
    parser = _TextHTMLParser()
    parser.feed(raw)
    return "\n".join(parser.parts).strip()
