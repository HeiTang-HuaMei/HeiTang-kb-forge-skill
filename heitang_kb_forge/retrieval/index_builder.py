from collections import Counter
from pathlib import Path
import json
import re

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.retrieval.context_pack import make_context_pack
from heitang_kb_forge.retrieval.query_router import route_query
from heitang_kb_forge.retrieval.ranker import rank_records
from heitang_kb_forge.retrieval.trace import make_retrieval_trace
from heitang_kb_forge.schemas.retrieval_schema import RetrievalIndexRecord, RetrievalManifest


RETRIEVAL_OUTPUT_FILES = [
    "retrieval_index.jsonl",
    "retrieval_manifest.json",
    "context_pack.json",
    "context_pack.md",
    "retrieval_trace.json",
]


def build_retrieval_outputs(package: Path, output: Path, query: str = "Summarize this knowledge package.") -> dict:
    output.mkdir(parents=True, exist_ok=True)
    records = build_retrieval_index(package)
    records_json = [record.model_dump(mode="json") for record in records]
    selected = rank_records(records_json, query)
    route = route_query(query)
    context_pack, context_md = make_context_pack(package, records_json, query)
    trace = make_retrieval_trace(query, route, selected)
    counts = Counter(record.asset_type for record in records)
    manifest = RetrievalManifest(
        package=str(package).replace("\\", "/"),
        total_records=len(records),
        asset_type_counts=dict(counts),
    )
    write_jsonl(output / "retrieval_index.jsonl", records)
    write_json(output / "retrieval_manifest.json", manifest.model_dump(mode="json"))
    write_json(output / "context_pack.json", context_pack)
    (output / "context_pack.md").write_text(context_md, encoding="utf-8")
    write_json(output / "retrieval_trace.json", trace.model_dump(mode="json"))
    return manifest.model_dump(mode="json")


def build_retrieval_index(package: Path) -> list[RetrievalIndexRecord]:
    records = []
    for index, chunk in enumerate(_load_jsonl(package / "chunks.jsonl")):
        text = str(chunk.get("text", "")).strip()
        if not text:
            continue
        chunk_id = str(chunk.get("chunk_id", ""))
        source_path = str(chunk.get("source_path", ""))
        records.append(
            RetrievalIndexRecord(
                retrieval_id=f"chunk_{index}",
                asset_type="chunk",
                text=text,
                source_path=source_path,
                chunk_id=chunk_id,
                citation=_citation(source_path, chunk_id),
                keywords=_keywords(text),
                confidence="high",
                review_required=bool(chunk.get("metadata", {}).get("review_required")),
            )
        )
    for name, asset_type, text_fn in [
        ("cards.jsonl", "card", lambda item: f"{item.get('title', '')}\n{item.get('summary', '')}"),
        ("qa_pairs.jsonl", "qa_pair", lambda item: f"Q: {item.get('question', '')}\nA: {item.get('answer', '')}"),
        ("glossary.jsonl", "glossary", lambda item: f"{item.get('term', '')}\n{item.get('definition', '')}"),
    ]:
        for item in _load_jsonl(package / name):
            text = text_fn(item).strip()
            if not text:
                continue
            chunk_id = str(item.get("chunk_id", ""))
            source_path = str(item.get("source_path", ""))
            records.append(
                RetrievalIndexRecord(
                    retrieval_id=f"{asset_type}_{len(records)}",
                    asset_type=asset_type,
                    text=text,
                    source_path=source_path,
                    chunk_id=chunk_id,
                    citation=str(item.get("citation") or _citation(source_path, chunk_id)),
                    keywords=_keywords(text),
                    confidence="medium",
                    review_required=bool(item.get("review_required")),
                )
            )
    return records


def _load_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _keywords(value: str) -> list[str]:
    words = [word.lower() for word in re.findall(r"[\w\u4e00-\u9fff]+", value) if len(word) > 1]
    seen = []
    for word in words:
        if word not in seen:
            seen.append(word)
    return seen[:24]


def _citation(source_path: str, chunk_id: str) -> str:
    return f"{source_path}#chunk={chunk_id}" if source_path or chunk_id else ""
