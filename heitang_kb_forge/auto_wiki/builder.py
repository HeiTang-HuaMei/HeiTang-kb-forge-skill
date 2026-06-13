from __future__ import annotations

import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


AUTO_WIKI_OUTPUT_FILES = [
    "auto_wiki_manifest.json",
    "auto_wiki_pages.jsonl",
    "knowledge_graph_snapshot.json",
    "rag_trace_summary.json",
    "visual_trace_manifest.json",
    "weknora_capability_fusion_report.json",
    "weknora_capability_fusion_report.md",
]


def build_auto_wiki_bundle(package_dir: Path, *, query: str = "Summarize this knowledge package.") -> dict[str, Any]:
    package_dir = Path(package_dir)
    if not package_dir.exists():
        raise FileNotFoundError(f"knowledge package does not exist: {package_dir}")
    if not package_dir.is_dir():
        raise NotADirectoryError(f"knowledge package must be a directory: {package_dir}")

    manifest = _read_json(package_dir / "manifest.json", default={})
    cards = _read_jsonl(package_dir / "cards.jsonl")
    glossary = _read_jsonl(package_dir / "glossary.jsonl")
    chunks = _read_jsonl(package_dir / "chunks.jsonl")
    evidence_map = _read_json(package_dir / "evidence_map.json", default={"chunks": {}})
    retrieval_trace = _read_json(package_dir / "retrieval_trace.json", default={})
    pages = _wiki_pages(cards, chunks)
    graph = _knowledge_graph_snapshot(pages, glossary)
    rag_trace = _rag_trace_summary(query, retrieval_trace, chunks, evidence_map)
    visual_trace = _visual_trace_manifest(pages, graph, rag_trace)
    now = datetime.now(timezone.utc).isoformat()
    report = {
        "schema_version": "weknora_capability_fusion_report.v1",
        "status": "passed" if pages else "failed",
        "project_source": "weknora",
        "integration_mode": "capability_fusion",
        "vendor_runtime_integrated": False,
        "external_code_copied": False,
        "llm_required": False,
        "network_required": False,
        "external_runtime_required": False,
        "generated_at": now,
        "knowledge_package": str(package_dir),
        "package_id": manifest.get("package_id"),
        "auto_wiki_page_count": len(pages),
        "graph_entity_count": graph["entity_count"],
        "graph_relation_count": graph["relation_count"],
        "rag_trace_record_count": rag_trace["record_count"],
        "visual_trace_available": visual_trace["visual_trace_available"],
        "source_trace_preserved": all(page["source_path"] for page in pages) if pages else False,
        "outputs": AUTO_WIKI_OUTPUT_FILES,
        "final_target_not_downgraded": True,
        "remaining_gap": "This advances Section 5 item 5.2 WeKnora as local Auto Wiki, Knowledge Graph, and RAG trace capability fusion. It does not accept Campaign 3 or prove full UI, Core Bridge, configuration, Full Gate, EXE, or release readiness.",
        "next_required_e2e_step": "Process Section 5 item 5.3 AnySearchSkill only after the WeKnora decision and UI impact evidence are accepted.",
        "not_goal_complete": True,
    }
    auto_wiki_manifest = {
        "schema_version": "auto_wiki_manifest.v1",
        "status": report["status"],
        "generated_at": now,
        "package_id": manifest.get("package_id"),
        "page_count": len(pages),
        "source_count": manifest.get("source_count", len({page["source_path"] for page in pages if page["source_path"]})),
        "weknora_runtime_integrated": False,
        "output_files": AUTO_WIKI_OUTPUT_FILES,
    }
    return {
        "auto_wiki_manifest": auto_wiki_manifest,
        "auto_wiki_pages": pages,
        "knowledge_graph_snapshot": graph,
        "rag_trace_summary": rag_trace,
        "visual_trace_manifest": visual_trace,
        "weknora_capability_fusion_report": report,
    }


def write_auto_wiki_outputs(package_dir: Path, output: Path, *, query: str = "Summarize this knowledge package.") -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    bundle = build_auto_wiki_bundle(package_dir, query=query)
    write_json(output / "auto_wiki_manifest.json", bundle["auto_wiki_manifest"])
    write_jsonl(output / "auto_wiki_pages.jsonl", bundle["auto_wiki_pages"])
    write_json(output / "knowledge_graph_snapshot.json", bundle["knowledge_graph_snapshot"])
    write_json(output / "rag_trace_summary.json", bundle["rag_trace_summary"])
    write_json(output / "visual_trace_manifest.json", bundle["visual_trace_manifest"])
    write_json(output / "weknora_capability_fusion_report.json", bundle["weknora_capability_fusion_report"])
    (output / "weknora_capability_fusion_report.md").write_text(_render_report(bundle), encoding="utf-8")
    return {
        "status": bundle["weknora_capability_fusion_report"]["status"],
        "output_files": AUTO_WIKI_OUTPUT_FILES,
        **bundle,
    }


def _wiki_pages(cards: list[dict[str, Any]], chunks: list[dict[str, Any]]) -> list[dict[str, Any]]:
    if cards:
        return [
            {
                "page_id": str(card.get("card_id") or f"page_{index}"),
                "title": str(card.get("title") or f"Page {index}"),
                "summary": str(card.get("summary") or "")[:500],
                "source_path": str(card.get("source_path") or ""),
                "chunk_id": str(card.get("chunk_id") or ""),
                "citation": str(card.get("citation") or ""),
                "tags": list(card.get("tags") or []),
            }
            for index, card in enumerate(cards, start=1)
        ]
    return [
        {
            "page_id": f"page_{index}",
            "title": str(chunk.get("title") or f"Chunk {index}"),
            "summary": _sentence_summary(str(chunk.get("text") or "")),
            "source_path": str(chunk.get("source_path") or ""),
            "chunk_id": str(chunk.get("chunk_id") or ""),
            "citation": f"{chunk.get('source_path', '')}#chunk={chunk.get('chunk_id', '')}",
            "tags": _tags(str(chunk.get("text") or "")),
        }
        for index, chunk in enumerate(chunks, start=1)
        if chunk.get("text")
    ]


def _knowledge_graph_snapshot(pages: list[dict[str, Any]], glossary: list[dict[str, Any]]) -> dict[str, Any]:
    entities = []
    seen = set()
    for page in pages:
        entity_id = _entity_id(page["title"], "page")
        if entity_id in seen:
            continue
        seen.add(entity_id)
        entities.append(
            {
                "entity_id": entity_id,
                "name": page["title"],
                "entity_type": _entity_type(page["title"]),
                "source_path": page["source_path"],
                "chunk_id": page["chunk_id"],
                "citation": page["citation"],
            }
        )
    for term in glossary[:20]:
        name = str(term.get("term") or "").strip()
        if not name:
            continue
        entity_id = _entity_id(name, "term")
        if entity_id in seen:
            continue
        seen.add(entity_id)
        entities.append(
            {
                "entity_id": entity_id,
                "name": name,
                "entity_type": _entity_type(name),
                "source_path": str(term.get("source_path") or ""),
                "chunk_id": str(term.get("chunk_id") or ""),
                "citation": str(term.get("citation") or ""),
            }
        )
    relations = [
        {
            "relation_id": f"relation_{index}",
            "source_entity_id": entities[0]["entity_id"],
            "target_entity_id": entity["entity_id"],
            "relation_type": "related_to",
            "source_path": entity["source_path"],
            "chunk_id": entity["chunk_id"],
            "citation": entity["citation"],
        }
        for index, entity in enumerate(entities[1:], start=1)
    ] if len(entities) > 1 else []
    counts = Counter(entity["entity_type"] for entity in entities)
    return {
        "schema_version": "knowledge_graph_snapshot.v1",
        "entity_count": len(entities),
        "relation_count": len(relations),
        "entity_type_counts": dict(counts),
        "entities": entities,
        "relations": relations,
        "weknora_runtime_integrated": False,
    }


def _rag_trace_summary(query: str, trace: dict[str, Any], chunks: list[dict[str, Any]], evidence_map: dict[str, Any]) -> dict[str, Any]:
    selected = trace.get("selected_ids") or [chunk.get("chunk_id") for chunk in chunks[:5]]
    evidence_chunks = evidence_map.get("chunks", {})
    records = []
    for selected_id in selected:
        chunk = _find_chunk(chunks, str(selected_id))
        chunk_id = str(chunk.get("chunk_id") or selected_id)
        evidence = evidence_chunks.get(chunk_id, {})
        records.append(
            {
                "selected_id": str(selected_id),
                "chunk_id": chunk_id,
                "source_path": evidence.get("source_file") or chunk.get("source_path") or "",
                "text_preview": str(chunk.get("text") or "")[:240],
                "source_trace_present": bool(evidence.get("source_file") or chunk.get("source_path")),
            }
        )
    return {
        "schema_version": "rag_trace_summary.v1",
        "query": trace.get("query") or query,
        "route": trace.get("route") or "package",
        "record_count": len(records),
        "source_trace_preserved": all(record["source_trace_present"] for record in records) if records else False,
        "records": records,
    }


def _visual_trace_manifest(pages: list[dict[str, Any]], graph: dict[str, Any], rag_trace: dict[str, Any]) -> dict[str, Any]:
    nodes = [
        {"node_id": entity["entity_id"], "label": entity["name"], "type": entity["entity_type"]}
        for entity in graph["entities"][:50]
    ]
    edges = [
        {
            "edge_id": relation["relation_id"],
            "source": relation["source_entity_id"],
            "target": relation["target_entity_id"],
            "type": relation["relation_type"],
        }
        for relation in graph["relations"][:50]
    ]
    return {
        "schema_version": "visual_trace_manifest.v1",
        "visual_trace_available": bool(nodes),
        "page_count": len(pages),
        "node_count": len(nodes),
        "edge_count": len(edges),
        "rag_record_count": rag_trace["record_count"],
        "nodes": nodes,
        "edges": edges,
    }


def _render_report(bundle: dict[str, Any]) -> str:
    report = bundle["weknora_capability_fusion_report"]
    return f"""# WeKnora Capability Fusion Report

- Status: {report['status']}
- Integration mode: {report['integration_mode']}
- Vendor runtime integrated: {report['vendor_runtime_integrated']}
- External code copied: {report['external_code_copied']}
- Auto Wiki pages: {report['auto_wiki_page_count']}
- Graph entities: {report['graph_entity_count']}
- Graph relations: {report['graph_relation_count']}
- RAG trace records: {report['rag_trace_record_count']}
- Visual trace available: {report['visual_trace_available']}

This report captures WeKnora-inspired Auto Wiki, Knowledge Graph, RAG trace, and visual trace structures as local HeiTang outputs. It does not embed or execute the WeKnora runtime.
"""


def _read_json(path: Path, *, default: Any) -> Any:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8-sig").splitlines() if line.strip()]


def _sentence_summary(text: str) -> str:
    return re.split(r"(?<=[.!?。！？])\s+", text.strip())[0][:500] if text.strip() else ""


def _tags(text: str) -> list[str]:
    return re.findall(r"[A-Za-z][A-Za-z0-9_-]{2,}", text)[:8]


def _entity_id(name: str, prefix: str) -> str:
    slug = re.sub(r"\W+", "_", name.lower(), flags=re.UNICODE).strip("_")[:60] or "entity"
    return f"{prefix}_{slug}"


def _entity_type(name: str) -> str:
    if re.search(r"workflow|process|method|流程|方法", name, re.IGNORECASE):
        return "process"
    if re.search(r"claim|evidence|trace|证据", name, re.IGNORECASE):
        return "evidence"
    if re.search(r"metric|score|指标", name, re.IGNORECASE):
        return "metric"
    return "concept"


def _find_chunk(chunks: list[dict[str, Any]], selected_id: str) -> dict[str, Any]:
    normalized = selected_id.replace("chunk_", "")
    for index, chunk in enumerate(chunks):
        chunk_id = str(chunk.get("chunk_id") or "")
        if selected_id == chunk_id or normalized == str(index):
            return chunk
    return chunks[0] if chunks else {}
