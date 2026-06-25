from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.native_knowledge_format_schema import (
    NativeKnowledgeFormatPackage,
    NativeKnowledgeFormatReport,
)


NATIVE_KNOWLEDGE_FORMAT_BOUNDARY = {
    "ui_change": "not_required",
    "runtime_change": "not_required",
    "external_service_call": "not_required",
    "llm_api_call": "not_required",
    "vector_db_call": "not_required",
    "local_model": "forbidden",
    "gpu": "forbidden",
    "redis_service_packaging": "forbidden",
    "vector_service_packaging": "forbidden",
}


def validate_native_knowledge_format(
    payload: NativeKnowledgeFormatPackage | dict,
    output: Path | None = None,
) -> NativeKnowledgeFormatReport:
    data = payload if isinstance(payload, NativeKnowledgeFormatPackage) else NativeKnowledgeFormatPackage.model_validate(payload)
    failed_checks: list[str] = []
    chunk_ids = _chunk_ids(data.chunks)
    source_trace_ids = {entry.source_id for entry in data.source_trace}
    source_trace_keys = {_trace_key(entry.source_path, entry.chunk_id, entry.citation) for entry in data.source_trace}
    entity_ids = {entry.entity_id for entry in data.entities}

    duplicate_groups = {
        "duplicate_chunk_id": _duplicates([str(item.get("chunk_id", "")) for item in data.chunks]),
        "duplicate_source_id": _duplicates([entry.source_id for entry in data.source_trace]),
        "duplicate_entity_id": _duplicates([entry.entity_id for entry in data.entities]),
        "duplicate_relation_id": _duplicates([entry.relation_id for entry in data.relations]),
        "duplicate_question_id": _duplicates([entry.question_id for entry in data.compound_questions]),
        "duplicate_summary_id": _duplicates([entry.summary_id for entry in data.cross_doc_summaries]),
        "duplicate_memory_card_id": _duplicates([entry.memory_card_id for entry in data.memory_cards]),
    }
    for check_name, duplicates in duplicate_groups.items():
        if duplicates:
            failed_checks.append(check_name)

    missing_trace_ids = _missing_trace_ids(data, chunk_ids, source_trace_keys)
    missing_entity_ids = _missing_entity_ids(data, entity_ids)
    unresolved_relation_ids = [
        relation.relation_id
        for relation in data.relations
        if relation.source_entity_id not in entity_ids or relation.target_entity_id not in entity_ids
    ]
    unresolved_question_ids = [
        question.question_id
        for question in data.compound_questions
        if any(entity_id not in entity_ids for entity_id in question.required_entity_ids)
        or not _has_trace(question.source_path, question.chunk_id, question.citation, chunk_ids, source_trace_keys)
    ]
    unresolved_memory_card_ids = [
        card.memory_card_id
        for card in data.memory_cards
        if any(entity_id not in entity_ids for entity_id in card.entity_ids)
        or not _has_trace(card.source_path, card.chunk_id, card.citation, chunk_ids, source_trace_keys)
    ]
    unresolved_summary_ids = [
        summary.summary_id
        for summary in data.cross_doc_summaries
        if any(source_id not in source_trace_ids for source_id in summary.source_ids) or not summary.citation.strip()
    ]

    if not data.chunks:
        failed_checks.append("chunks_required")
    if not data.source_trace:
        failed_checks.append("source_trace_required")
    if missing_trace_ids:
        failed_checks.append("source_trace_backlink_missing")
    if missing_entity_ids:
        failed_checks.append("entity_backlink_missing")
    if unresolved_relation_ids:
        failed_checks.append("relation_entity_reference_missing")
    if unresolved_question_ids:
        failed_checks.append("compound_question_reference_missing")
    if unresolved_memory_card_ids:
        failed_checks.append("memory_card_reference_missing")
    if unresolved_summary_ids:
        failed_checks.append("cross_doc_summary_reference_missing")

    report = NativeKnowledgeFormatReport(
        status="passed" if not failed_checks else "failed",
        checked_counts={
            "chunk_count": len(data.chunks),
            "source_trace_count": len(data.source_trace),
            "entity_count": len(data.entities),
            "relation_count": len(data.relations),
            "compound_question_count": len(data.compound_questions),
            "cross_doc_summary_count": len(data.cross_doc_summaries),
            "memory_card_count": len(data.memory_cards),
        },
        failed_checks=failed_checks,
        missing_trace_ids=missing_trace_ids,
        missing_entity_ids=missing_entity_ids,
        unresolved_relation_ids=unresolved_relation_ids,
        unresolved_question_ids=unresolved_question_ids,
        unresolved_memory_card_ids=unresolved_memory_card_ids,
        unresolved_summary_ids=unresolved_summary_ids,
        boundary=NATIVE_KNOWLEDGE_FORMAT_BOUNDARY,
        output_files=["native_knowledge_format_semantic_schema_report.json"],
    )
    if output:
        output.mkdir(parents=True, exist_ok=True)
        write_json(output / "native_knowledge_format_semantic_schema_report.json", report)
    return report


def _chunk_ids(chunks: list[dict]) -> set[str]:
    return {str(item.get("chunk_id", "")).strip() for item in chunks if str(item.get("chunk_id", "")).strip()}


def _missing_trace_ids(data: NativeKnowledgeFormatPackage, chunk_ids: set[str], source_trace_keys: set[str]) -> list[str]:
    missing: list[str] = []
    for entry in data.source_trace:
        if entry.chunk_id not in chunk_ids or not entry.citation.strip():
            missing.append(entry.source_id)
    return missing


def _missing_entity_ids(data: NativeKnowledgeFormatPackage, entity_ids: set[str]) -> list[str]:
    missing: list[str] = []
    for entity in data.entities:
        if not _has_trace(entity.source_path, entity.chunk_id, entity.citation, _chunk_ids(data.chunks), {_trace_key(trace.source_path, trace.chunk_id, trace.citation) for trace in data.source_trace}):
            missing.append(entity.entity_id)
    return missing


def _has_trace(
    source_path: str,
    chunk_id: str,
    citation: str,
    chunk_ids: set[str],
    source_trace_keys: set[str],
) -> bool:
    return bool(chunk_id in chunk_ids and citation.strip() and _trace_key(source_path, chunk_id, citation) in source_trace_keys)


def _trace_key(source_path: str, chunk_id: str, citation: str) -> str:
    return "|".join(str(value).strip().lower() for value in [source_path, chunk_id, citation])


def _duplicates(values: list[str]) -> list[str]:
    seen: set[str] = set()
    duplicates: list[str] = []
    for value in values:
        if not value:
            continue
        if value in seen and value not in duplicates:
            duplicates.append(value)
        seen.add(value)
    return duplicates
