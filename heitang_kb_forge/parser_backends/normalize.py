from __future__ import annotations

from pathlib import Path
import re


def normalize_text(text: str) -> str:
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def source_type(path: Path) -> str:
    return path.suffix.lower().lstrip(".") or "unknown"


def column_safe_path(path: Path) -> str:
    return str(path).replace("\\", "/")

