import hashlib
import re
from pathlib import Path

from kb_forge.schemas.chunk_schema import Chunk


def stable_chunk_id(source_path: str, order: int, text: str) -> str:
    payload = f"{source_path}\n{order}\n{text}".encode("utf-8")
    return hashlib.sha256(payload).hexdigest()[:24]


def chunk_text(
    text: str,
    source_path: Path | str,
    source_type: str,
    domain: str,
    mode: str,
    max_chars: int = 1200,
    overlap_chars: int = 120,
) -> list[Chunk]:
    if max_chars <= 0:
        raise ValueError("max_chars must be greater than 0")
    if overlap_chars < 0 or overlap_chars >= max_chars:
        raise ValueError("overlap_chars must be non-negative and smaller than max_chars")

    blocks = [block.strip() for block in re.split(r"\n\s*\n", text) if block.strip()]
    chunks: list[str] = []
    current = ""

    for block in blocks:
        if not current:
            current = block
            continue
        candidate = f"{current}\n\n{block}"
        if len(candidate) <= max_chars:
            current = candidate
        else:
            chunks.extend(_split_large_block(current, max_chars, overlap_chars))
            current = block

    if current:
        chunks.extend(_split_large_block(current, max_chars, overlap_chars))

    source = str(source_path).replace("\\", "/")
    title = _infer_title(text)
    return [
        Chunk(
            chunk_id=stable_chunk_id(source, order, chunk),
            source_path=source,
            source_type=source_type,
            domain=domain,
            mode=mode,
            title=title,
            text=chunk,
            order=order,
            char_count=len(chunk),
        )
        for order, chunk in enumerate(chunks)
        if chunk.strip()
    ]


def _split_large_block(block: str, max_chars: int, overlap_chars: int) -> list[str]:
    if len(block) <= max_chars:
        return [block]

    result: list[str] = []
    start = 0
    while start < len(block):
        end = min(start + max_chars, len(block))
        window = block[start:end]
        split_at = max(window.rfind("\n"), window.rfind("。"), window.rfind("."), window.rfind(" "))
        if split_at > max_chars * 0.5 and end < len(block):
            end = start + split_at + 1
        result.append(block[start:end].strip())
        if end >= len(block):
            break
        start = max(0, end - overlap_chars)
    return [item for item in result if item]


def _infer_title(text: str) -> str | None:
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        return line.lstrip("#").strip()[:120] or None
    return None
