import json
from pathlib import Path

from heitang_kb_forge.schemas.runtime_schema import RetrievedRecord


def retrieve(package: Path, query: str, top_k: int = 5) -> list[RetrievedRecord]:
    records = _load_records(package)
    terms = [term.lower() for term in query.split() if term.strip()]
    scored = []
    for record in records:
        text = record["text"].lower()
        score = sum(1 for term in terms if term in text)
        if score == 0:
            score = 1 if records else 0
        scored.append((score, record))
    return [
        RetrievedRecord(
            record_id=str(record.get("id", record.get("chunk_id", ""))),
            text=str(record.get("text", "")),
            score=score,
            source_path=str(record.get("source_path", "")),
            chunk_id=str(record.get("chunk_id", "")),
            citation=str(record.get("citation", "")) or _citation(str(record.get("source_path", "")), str(record.get("chunk_id", ""))),
        )
        for score, record in sorted(scored, key=lambda item: item[0], reverse=True)[:top_k]
        if record.get("text")
    ]


def _load_records(package: Path) -> list[dict]:
    embedding_input = package / "embedding_input.jsonl"
    if embedding_input.exists():
        return [
            {
                "id": item.get("embedding_id"),
                "text": item.get("text"),
                "source_path": item.get("source_path"),
                "chunk_id": item.get("chunk_id"),
                "citation": item.get("citation"),
            }
            for item in _read_jsonl(embedding_input)
        ]
    chunks = package / "chunks.jsonl"
    return [
        {
            "id": item.get("chunk_id"),
            "text": item.get("text"),
            "source_path": item.get("source_path"),
            "chunk_id": item.get("chunk_id"),
            "citation": _citation(str(item.get("source_path", "")), str(item.get("chunk_id", ""))),
        }
        for item in _read_jsonl(chunks)
    ]


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _citation(source_path: str, chunk_id: str) -> str:
    return f"{source_path}#chunk={chunk_id}"
