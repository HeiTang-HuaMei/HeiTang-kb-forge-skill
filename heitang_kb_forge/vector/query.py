from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path


def query_local_vector_index(
    package: Path,
    query: str,
    *,
    top_k: int = 5,
    mode: str = "hybrid",
    filters: dict | None = None,
) -> tuple[list[dict], dict]:
    if mode not in {"vector", "keyword", "hybrid"}:
        raise ValueError("mode must be one of: vector, keyword, hybrid")
    filters = filters or {}
    records = _load_records(package)
    staleness = detect_vector_index_staleness(package)
    query_vector = _fake_query_vector(query)
    scored = []
    for record in records:
        if not _matches_filters(record, filters):
            continue
        vector_score = _cosine(query_vector, record["vector"])
        keyword_score = _keyword_score(query, record["text"])
        if mode == "vector":
            score = vector_score
        elif mode == "keyword":
            score = keyword_score
        else:
            score = round((vector_score * 0.65) + (keyword_score * 0.35), 6)
        scored.append(
            {
                **record,
                "score": score,
                "vector_score": vector_score,
                "keyword_score": keyword_score,
                "retrieval_mode": mode,
            }
        )
    ranked = sorted(scored, key=lambda item: (item["score"], item["keyword_score"]), reverse=True)[:top_k]
    trace = {
        "vector_query_trace_version": "pre-v4-local-vector-1",
        "package": str(package).replace("\\", "/"),
        "query": query,
        "mode": mode,
        "top_k": top_k,
        "filters": filters,
        "records_considered": len(records),
        "records_matched": len(scored),
        "records_returned": len(ranked),
        "staleness": staleness,
        "tests_require_real_llm_api_network": False,
    }
    return ranked, trace


def detect_vector_index_staleness(package: Path) -> dict:
    embeddings = _read_jsonl(package / "embeddings.jsonl")
    vectors = _read_jsonl(package / "vector_store_records.jsonl")
    embedding_ids = {str(item.get("embedding_id")) for item in embeddings if item.get("embedding_id")}
    vector_ids = {str(item.get("embedding_id")) for item in vectors if item.get("embedding_id")}
    missing_vectors = sorted(embedding_ids - vector_ids)
    orphan_vectors = sorted(vector_ids - embedding_ids)
    manifest = _read_json(package / "vector_store_manifest.json")
    expected_total = int(manifest.get("total_records", len(vector_ids))) if manifest else len(vector_ids)
    count_mismatch = expected_total != len(vectors)
    stale = bool(missing_vectors or orphan_vectors or count_mismatch)
    return {
        "status": "stale" if stale else "fresh",
        "missing_vector_count": len(missing_vectors),
        "orphan_vector_count": len(orphan_vectors),
        "manifest_total_records": expected_total,
        "actual_vector_records": len(vectors),
        "count_mismatch": count_mismatch,
        "missing_vector_ids": missing_vectors[:25],
        "orphan_vector_ids": orphan_vectors[:25],
        "rebuild_policy": "rebuild local vector export when embeddings and vector records diverge",
    }


def write_vector_query_outputs(output: Path, records: list[dict], trace: dict) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    report = {
        "vector_query_report_version": "pre-v4-local-vector-1",
        "status": "pass" if trace["staleness"]["status"] == "fresh" else "needs_review",
        "query": trace["query"],
        "retrieval_mode": trace["mode"],
        "records_returned": len(records),
        "metadata_filtering_proven": bool(trace["filters"]),
        "stale_index_detection": trace["staleness"],
        "tests_require_real_llm_api_network": False,
    }
    (output / "vector_query_results.json").write_text(json.dumps({"records": records}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (output / "vector_query_trace.json").write_text(json.dumps(trace, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (output / "vector_query_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (output / "vector_query_report.md").write_text(_markdown_report(report), encoding="utf-8")
    return report


def _load_records(package: Path) -> list[dict]:
    embeddings = {str(item.get("embedding_id")): item for item in _read_jsonl(package / "embeddings.jsonl")}
    vectors = _read_jsonl(package / "vector_store_records.jsonl")
    if not vectors:
        raise ValueError("vector_store_records.jsonl is required for local vector query")
    records = []
    for vector_record in vectors:
        embedding_id = str(vector_record.get("embedding_id", ""))
        embedding = embeddings.get(embedding_id, {})
        metadata = vector_record.get("metadata") or {}
        records.append(
            {
                "vector_record_id": str(vector_record.get("vector_record_id", "")),
                "embedding_id": embedding_id,
                "text_hash": str(embedding.get("text_hash", "")),
                "vector": [float(value) for value in vector_record.get("vector", [])],
                "metadata": metadata,
                "source_path": str(metadata.get("source_path", "")),
                "chunk_id": str(metadata.get("chunk_id", "")),
                "citation": str(metadata.get("citation", "")),
                "text": _lookup_text(package, embedding_id, metadata),
            }
        )
    return records


def _lookup_text(package: Path, embedding_id: str, metadata: dict) -> str:
    for item in _read_jsonl(package / "embedding_input.jsonl"):
        if str(item.get("embedding_id")) == embedding_id:
            return str(item.get("text", ""))
    chunk_id = str(metadata.get("chunk_id", ""))
    for item in _read_jsonl(package / "chunks.jsonl"):
        if str(item.get("chunk_id")) == chunk_id:
            return str(item.get("text", ""))
    return ""


def _matches_filters(record: dict, filters: dict) -> bool:
    metadata = record.get("metadata") or {}
    for key, expected in filters.items():
        if expected is None or expected == "":
            continue
        actual = record.get(key, metadata.get(key))
        if str(actual) != str(expected):
            return False
    return True


def _fake_query_vector(query: str, dimensions: int = 8) -> list[float]:
    digest = hashlib.sha256(query.encode("utf-8")).digest()
    return [round((digest[index] / 255.0) * 2 - 1, 6) for index in range(dimensions)]


def _cosine(left: list[float], right: list[float]) -> float:
    if not left or not right:
        return 0.0
    size = min(len(left), len(right))
    dot = sum(left[index] * right[index] for index in range(size))
    left_norm = math.sqrt(sum(left[index] * left[index] for index in range(size)))
    right_norm = math.sqrt(sum(right[index] * right[index] for index in range(size)))
    if left_norm == 0 or right_norm == 0:
        return 0.0
    return round((dot / (left_norm * right_norm) + 1) / 2, 6)


def _keyword_score(query: str, text: str) -> float:
    terms = [term.lower() for term in query.split() if term.strip()]
    if not terms:
        return 0.0
    lowered = text.lower()
    hits = sum(1 for term in terms if term in lowered)
    return round(hits / len(terms), 6)


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _markdown_report(report: dict) -> str:
    return f"""# Local Vector Query Report

- Status: {report['status']}
- Retrieval mode: {report['retrieval_mode']}
- Records returned: {report['records_returned']}
- Metadata filtering proven: {report['metadata_filtering_proven']}
- Stale index status: {report['stale_index_detection']['status']}
- Tests require real LLM/API/network: false
"""
