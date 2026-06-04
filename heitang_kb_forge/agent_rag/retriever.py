from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.agent_rag.citation import make_citation, make_citation_trace
from heitang_kb_forge.agent_rag.ranker import rank_records
from heitang_kb_forge.agent_rag.scope import record_matches_scope
from heitang_kb_forge.schemas.agent_rag_schema import AgentRAGRecord
from heitang_kb_forge.store.db import connect_store


AGENT_RAG_OUTPUT_FILES = [
    "retrieval_result.json",
    "retrieval_trace.json",
    "citation_trace.json",
    "answer.md",
    "answer_report.json",
    "agent_rag_config.yaml",
]


def retrieve_from_package(package: Path, query: str, top_k: int = 5, scope: dict | None = None) -> tuple[list[AgentRAGRecord], dict, dict]:
    records = _load_package_records(package)
    filtered = [record for record in records if record_matches_scope(record.model_dump(mode="json"), scope or {})]
    ranked = rank_records(filtered, query, top_k)
    trace = _trace(query, top_k, ranked, source="package", scope=scope or {})
    return ranked, trace, make_citation_trace([record.model_dump(mode="json") for record in ranked])


def retrieve_from_store(db_path: Path, query: str, top_k: int = 5, scope: dict | None = None) -> tuple[list[AgentRAGRecord], dict, dict]:
    records = _load_store_records(db_path)
    filtered = [record for record in records if record_matches_scope(record.model_dump(mode="json"), scope or {})]
    ranked = rank_records(filtered, query, top_k)
    trace = _trace(query, top_k, ranked, source="store", scope=scope or {})
    return ranked, trace, make_citation_trace([record.model_dump(mode="json") for record in ranked])


def _load_package_records(package: Path) -> list[AgentRAGRecord]:
    embedding_input = package / "embedding_input.jsonl"
    if embedding_input.exists():
        return [
            AgentRAGRecord(
                embedding_id=str(item.get("embedding_id")),
                text=str(item.get("text", "")),
                asset_type=str(item.get("asset_type", "chunk")),
                source_path=str(item.get("source_path", "")),
                chunk_id=str(item.get("chunk_id", "")),
                citation=str(item.get("citation") or make_citation(str(item.get("source_path", "")), str(item.get("chunk_id", "")))),
                metadata=item.get("metadata", {}),
            )
            for item in _read_jsonl(embedding_input)
            if item.get("text")
        ]
    return [
        AgentRAGRecord(
            embedding_id=str(item.get("chunk_id")),
            text=str(item.get("text", "")),
            asset_type="chunk",
            source_path=str(item.get("source_path", "")),
            chunk_id=str(item.get("chunk_id", "")),
            citation=make_citation(str(item.get("source_path", "")), str(item.get("chunk_id", ""))),
            metadata={"domain": item.get("domain"), "mode": item.get("mode")},
        )
        for item in _read_jsonl(package / "chunks.jsonl")
        if item.get("text")
    ]


def _load_store_records(db_path: Path) -> list[AgentRAGRecord]:
    with connect_store(db_path) as connection:
        rows = connection.execute(
            """
            SELECT chunks_index.*, packages.domain AS package_domain, packages.mode AS package_mode, packages.agent_type AS agent_type
            FROM chunks_index
            JOIN packages ON packages.package_id = chunks_index.package_id
            ORDER BY chunks_index.package_id, chunks_index.chunk_id
            """
        ).fetchall()
    return [
        AgentRAGRecord(
            embedding_id=f"{row['package_id']}:{row['chunk_id']}",
            text=str(row["text"] or ""),
            asset_type="chunk",
            source_path=str(row["source_path"] or ""),
            chunk_id=str(row["chunk_id"] or ""),
            citation=make_citation(str(row["source_path"] or ""), str(row["chunk_id"] or "")),
            metadata={
                "package_id": row["package_id"],
                "domain": row["package_domain"],
                "mode": row["package_mode"],
                "agent_type": row["agent_type"],
            },
        )
        for row in rows
        if row["text"]
    ]


def _trace(query: str, top_k: int, records: list[AgentRAGRecord], source: str, scope: dict) -> dict:
    return {
        "retrieval_trace_version": "1.5.0",
        "source": source,
        "query": query,
        "top_k": top_k,
        "scope": scope,
        "records": [record.model_dump(mode="json") for record in records],
    }


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
