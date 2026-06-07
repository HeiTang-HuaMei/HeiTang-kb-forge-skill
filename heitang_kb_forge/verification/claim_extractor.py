from __future__ import annotations

import json
import re
from pathlib import Path


def extract_claims(package: Path, *, max_claims: int = 50) -> list[dict]:
    claims: list[dict] = []
    for row in _read_jsonl(package / "chunks.jsonl"):
        text = str(row.get("text", ""))
        for sentence in _sentences(text):
            claim = _claim(sentence, row, len(claims) + 1)
            if claim:
                claims.append(claim)
            if len(claims) >= max_claims:
                return claims
    for row in _read_jsonl(package / "cards.jsonl"):
        text = f"{row.get('title', '')}. {row.get('summary', '')}"
        for sentence in _sentences(text):
            claim = _claim(sentence, row, len(claims) + 1)
            if claim:
                claims.append(claim)
            if len(claims) >= max_claims:
                return claims
    return claims


def _claim(sentence: str, source: dict, index: int) -> dict | None:
    cleaned = sentence.strip(" -")
    if len(cleaned) < 12:
        return None
    if not _looks_like_claim(cleaned):
        return None
    source_path = str(source.get("source_path", ""))
    chunk_id = str(source.get("chunk_id", ""))
    return {
        "claim_id": f"claim_{index}",
        "claim_text": cleaned,
        "source_path": source_path,
        "chunk_id": chunk_id,
        "citation": f"{source_path}#chunk={chunk_id}" if source_path or chunk_id else "",
        "evidence_text": cleaned,
        "metadata": source.get("metadata", {}) if isinstance(source.get("metadata"), dict) else {},
    }


def _looks_like_claim(sentence: str) -> bool:
    lowered = sentence.lower()
    return any(marker in lowered for marker in [" is ", " are ", " has ", " have ", " must ", " should ", "支持", "是", "为"]) or bool(re.search(r"\d", sentence))


def _sentences(text: str) -> list[str]:
    return [part.strip() for part in re.split(r"(?<=[.!?。！？])\s+|[\n\r]+", text) if part.strip()]


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
