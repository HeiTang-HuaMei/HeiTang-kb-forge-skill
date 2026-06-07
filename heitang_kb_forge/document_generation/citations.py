from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Evidence:
    evidence_id: str
    chunk_id: str
    title: str
    source_path: str
    text: str
    citation: str


def citation_for(chunk: dict) -> str:
    source_path = str(chunk.get("source_path") or "unknown_source")
    chunk_id = str(chunk.get("chunk_id") or chunk.get("id") or "unknown_chunk")
    return f"{source_path}#chunk={chunk_id}"


def evidence_from_chunks(chunks: list[dict], limit: int = 8) -> list[Evidence]:
    evidence: list[Evidence] = []
    for index, chunk in enumerate(chunks[:limit], start=1):
        chunk_id = str(chunk.get("chunk_id") or chunk.get("id") or f"chunk_{index}")
        text = _compact(str(chunk.get("text") or chunk.get("summary") or ""))
        if not text:
            continue
        evidence.append(
            Evidence(
                evidence_id=f"E{index}",
                chunk_id=chunk_id,
                title=str(chunk.get("title") or f"Evidence {index}"),
                source_path=str(chunk.get("source_path") or "unknown_source"),
                text=text,
                citation=citation_for(chunk),
            )
        )
    return evidence


def _compact(text: str) -> str:
    return " ".join(text.split())
