from __future__ import annotations

import json
from pathlib import Path


def make_p0_package(tmp_path: Path) -> Path:
    package = tmp_path / "package"
    package.mkdir()
    chunks = [
        {
            "chunk_id": "c0",
            "source_path": "pricing.md",
            "source_type": "md",
            "title": "Pricing Policy",
            "text": "Pricing policy evidence for local RAG and Agent runtime.",
            "metadata": {"parent_section": "Pricing"},
        },
        {
            "chunk_id": "c1",
            "source_path": "privacy.md",
            "source_type": "md",
            "title": "Privacy Boundary",
            "text": "Local privacy boundary and optional LLM provider policy.",
            "metadata": {"parent_section": "Privacy"},
        },
    ]
    embedding_input = [
        {"embedding_id": "e0", "text": chunks[0]["text"], "source_path": "pricing.md", "chunk_id": "c0"},
        {"embedding_id": "e1", "text": chunks[1]["text"], "source_path": "privacy.md", "chunk_id": "c1"},
    ]
    embeddings = [
        {"embedding_id": "e0", "text_hash": "h0", "vector": [0.2, 0.1, 0.0, 0.4, 0.5, 0.1, 0.2, 0.3]},
        {"embedding_id": "e1", "text_hash": "h1", "vector": [0.1, 0.3, 0.1, 0.2, 0.1, 0.4, 0.2, 0.2]},
    ]
    vectors = [
        {
            "vector_record_id": f"v{index}",
            "embedding_id": item["embedding_id"],
            "vector": item["vector"],
            "metadata": {
                "source_asset_type": "chunk",
                "source_path": chunk["source_path"],
                "chunk_id": chunk["chunk_id"],
                "citation": f"{chunk['source_path']}#chunk={chunk['chunk_id']}",
            },
            "store": "local_json",
        }
        for index, (item, chunk) in enumerate(zip(embeddings, chunks, strict=True))
    ]
    write_jsonl(package / "chunks.jsonl", chunks)
    write_jsonl(package / "embedding_input.jsonl", embedding_input)
    write_jsonl(package / "embeddings.jsonl", embeddings)
    write_jsonl(package / "vector_store_records.jsonl", vectors)
    write_json(package / "manifest.json", {"package_id": "pkg-test", "package_version": "1", "generated_at": "2026-01-01T00:00:00Z", "overlap_chars": 120})
    write_json(package / "vector_store_manifest.json", {"store": "local_json", "total_records": len(vectors)})
    for name in ["new_sources.jsonl", "changed_sources.jsonl", "missing_sources.jsonl", "stale_chunks.jsonl"]:
        write_jsonl(package / name, [])
    write_json(package / "source_registry.json", {"sources": []})
    (package / "kb_index.jsonl").write_text(json.dumps({"chunk_id": "c0"}) + "\n", encoding="utf-8")
    (package / "v38_retrieval_quality").mkdir()
    write_json(package / "v38_retrieval_quality" / "rerank_report.json", {"status": "pass"})
    write_json(package / "v38_retrieval_quality" / "evidence_selection_trace.json", {"status": "pass"})
    (package / "v38_knowledge_accuracy").mkdir()
    write_json(package / "v38_knowledge_accuracy" / "knowledge_accuracy_report.json", {"status": "warning"})
    return package


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_jsonl(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(row, ensure_ascii=False) + "\n" for row in rows), encoding="utf-8")
