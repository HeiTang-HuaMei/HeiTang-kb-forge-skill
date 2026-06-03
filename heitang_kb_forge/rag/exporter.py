from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

from heitang_kb_forge.schemas.card_schema import KnowledgeCard
from heitang_kb_forge.schemas.chunk_schema import Chunk
from heitang_kb_forge.schemas.qa_schema import QAPair
from heitang_kb_forge.schemas.rag_schema import EmbeddingInputRecord, RetrievalMetadataRecord

RAG_OUTPUT_FILES = [
    "embedding_input.jsonl",
    "retrieval_metadata.jsonl",
    "citation_map.json",
    "rag_manifest.json",
]
COMPATIBLE_TARGETS = ["faiss", "qdrant", "chroma", "milvus"]


@dataclass
class RAGOptions:
    enabled: bool = False
    profile: str = "basic"
    include_llm: bool = False


@dataclass
class RAGExportResult:
    embedding_inputs: list[EmbeddingInputRecord] = field(default_factory=list)
    retrieval_metadata: list[RetrievalMetadataRecord] = field(default_factory=list)
    citation_map: dict = field(default_factory=dict)
    rag_manifest: dict = field(default_factory=dict)
    warnings: list[str] = field(default_factory=list)
    output_files: list[str] = field(default_factory=lambda: list(RAG_OUTPUT_FILES))


def make_rag_export(
    *,
    chunks: list[Chunk],
    cards: list[KnowledgeCard],
    qa_pairs: list[QAPair],
    glossary: list[dict],
    quality_report: dict,
    options: RAGOptions,
    llm_outputs: dict[str, list[dict]] | None = None,
) -> RAGExportResult:
    if options.profile != "basic":
        raise ValueError(f"Unsupported RAG profile: {options.profile}")

    result = RAGExportResult()
    created_at = datetime.now(timezone.utc).isoformat()
    records: list[tuple[str, str, str | None, str, str, str, dict, list[str], bool, str | None, str | None]] = []

    for chunk in chunks:
        records.append(
            (
                "chunk",
                chunk.text,
                chunk.title,
                chunk.source_path,
                chunk.chunk_id,
                _citation(chunk.source_path, chunk.chunk_id),
                chunk.metadata,
                [],
                False,
                None,
                None,
            )
        )
    for card in cards:
        records.append(
            (
                "card",
                f"{card.title}\n{card.summary}",
                card.title,
                card.source_path,
                card.chunk_id,
                card.citation or _citation(card.source_path, card.chunk_id),
                {"card_id": card.card_id, "card_type": card.card_type},
                card.tags,
                False,
                None,
                None,
            )
        )
    for pair in qa_pairs:
        records.append(
            (
                "qa_pair",
                f"Q: {pair.question}\nA: {pair.answer}",
                pair.question,
                pair.source_path,
                pair.chunk_id,
                pair.citation or _citation(pair.source_path, pair.chunk_id),
                {"qa_id": pair.qa_id, "qa_type": pair.qa_type},
                [],
                False,
                None,
                None,
            )
        )
    for item in glossary:
        records.append(
            (
                "glossary",
                _join_text(item.get("term"), item.get("definition")),
                item.get("term"),
                str(item.get("source_path", "")),
                str(item.get("chunk_id", "")),
                str(item.get("citation") or _citation(str(item.get("source_path", "")), str(item.get("chunk_id", "")))),
                {},
                [],
                False,
                None,
                None,
            )
        )

    if options.include_llm and llm_outputs:
        records.extend(_llm_records(llm_outputs))
    elif options.include_llm and not llm_outputs:
        result.warnings.append("RAG include LLM requested but LLM is not enabled")

    for index, record in enumerate(records):
        (
            asset_type,
            text,
            title,
            source_path,
            chunk_id,
            citation,
            metadata,
            tags,
            from_llm,
            provider,
            model,
        ) = record
        text = text.strip()
        if not text:
            continue
        embedding_id = f"{asset_type}_{index}"
        result.embedding_inputs.append(
            EmbeddingInputRecord(
                embedding_id=embedding_id,
                text=text,
                asset_type=asset_type,
                source_path=source_path,
                chunk_id=chunk_id,
                citation=citation,
                title=title,
                metadata=metadata,
                quality_score=quality_report.get("quality_score"),
                created_at=created_at,
            )
        )
        result.retrieval_metadata.append(
            RetrievalMetadataRecord(
                embedding_id=embedding_id,
                asset_type=asset_type,
                source_path=source_path,
                chunk_id=chunk_id,
                citation=citation,
                domain=_metadata_value(chunks, chunk_id, "domain"),
                mode=_metadata_value(chunks, chunk_id, "mode"),
                quality_score=quality_report.get("quality_score"),
                quality_level=quality_report.get("quality_level"),
                tags=tags,
                provider=provider,
                model=model,
                from_llm=from_llm,
                source_file_type=_source_file_type(source_path),
            )
        )

    result.citation_map = _citation_map(result.embedding_inputs)
    counts = Counter(record.asset_type for record in result.embedding_inputs)
    result.rag_manifest = {
        "rag_export_version": "0.6.0",
        "generated_at": created_at,
        "rag_profile": options.profile,
        "include_llm": options.include_llm,
        "embedding_input_file": "embedding_input.jsonl",
        "retrieval_metadata_file": "retrieval_metadata.jsonl",
        "citation_map_file": "citation_map.json",
        "total_records": len(result.embedding_inputs),
        "asset_type_counts": dict(counts),
        "source_count": len({chunk.source_path for chunk in chunks}),
        "chunk_count": len(chunks),
        "quality_score": quality_report.get("quality_score"),
        "quality_level": quality_report.get("quality_level"),
        "compatible_targets": COMPATIBLE_TARGETS,
    }
    return result


def _llm_records(llm_outputs: dict[str, list[dict]]) -> list[tuple]:
    mapping = {
        "cards": ("llm_card", lambda item: _join_text(item.get("title"), item.get("summary")), "title"),
        "qa_pairs": ("llm_qa_pair", lambda item: f"Q: {item.get('question', '')}\nA: {item.get('answer', '')}", "question"),
        "glossary": ("llm_glossary", lambda item: _join_text(item.get("term"), item.get("definition")), "term"),
        "frameworks": ("framework", lambda item: _join_text(item.get("name"), item.get("summary")), "name"),
        "case_cards": ("case_card", lambda item: _join_text(item.get("title"), item.get("case_summary")), "title"),
        "metrics": ("metric", lambda item: _join_text(item.get("name"), item.get("definition")), "name"),
    }
    records = []
    for output_name, items in llm_outputs.items():
        asset_type, text_fn, title_field = mapping[output_name]
        for item in items:
            records.append(
                (
                    asset_type,
                    text_fn(item),
                    item.get(title_field),
                    str(item.get("source_path", "")),
                    str(item.get("chunk_id", "")),
                    str(item.get("citation", "")),
                    {"llm_id": item.get("llm_id"), "extraction_type": item.get("extraction_type")},
                    [],
                    True,
                    item.get("llm_provider"),
                    item.get("llm_model"),
                )
            )
    return records


def _citation_map(records: list[EmbeddingInputRecord]) -> dict:
    by_embedding_id = {}
    by_chunk_id: dict[str, list[str]] = defaultdict(list)
    by_source_path: dict[str, list[str]] = defaultdict(list)
    for record in records:
        by_embedding_id[record.embedding_id] = {
            "citation": record.citation,
            "source_path": record.source_path,
            "chunk_id": record.chunk_id,
        }
        by_chunk_id[record.chunk_id].append(record.embedding_id)
        by_source_path[record.source_path].append(record.embedding_id)
    return {
        "by_embedding_id": by_embedding_id,
        "by_chunk_id": dict(by_chunk_id),
        "by_source_path": dict(by_source_path),
    }


def _metadata_value(chunks: list[Chunk], chunk_id: str, field: str) -> str:
    for chunk in chunks:
        if chunk.chunk_id == chunk_id:
            return str(getattr(chunk, field))
    return ""


def _source_file_type(source_path: str) -> str | None:
    suffix = Path(source_path).suffix.lower().lstrip(".")
    return suffix or None


def _citation(source_path: str, chunk_id: str) -> str:
    return f"{source_path}#chunk={chunk_id}"


def _join_text(*values) -> str:
    return "\n".join(str(value).strip() for value in values if str(value or "").strip())
