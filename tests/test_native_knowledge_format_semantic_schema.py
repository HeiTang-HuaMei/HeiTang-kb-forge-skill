from heitang_kb_forge.native_knowledge_format import validate_native_knowledge_format
from tests.v17_helpers import read_json


def test_native_knowledge_format_accepts_semantic_backlinks(tmp_path):
    report = validate_native_knowledge_format(_valid_payload(), output=tmp_path)

    persisted = read_json(tmp_path / "native_knowledge_format_semantic_schema_report.json")
    assert report.status == "passed"
    assert report.failed_checks == []
    assert report.checked_counts["chunk_count"] == 2
    assert report.checked_counts["entity_count"] == 2
    assert persisted["schema_version"] == "native_knowledge_format_semantic_schema.v1"
    assert persisted["boundary"]["llm_api_call"] == "not_required"
    assert persisted["boundary"]["vector_db_call"] == "not_required"


def test_native_knowledge_format_rejects_missing_source_trace():
    payload = _valid_payload()
    payload["source_trace"] = []

    report = validate_native_knowledge_format(payload)

    assert report.status == "failed"
    assert "source_trace_required" in report.failed_checks
    assert "entity_backlink_missing" in report.failed_checks


def test_native_knowledge_format_rejects_unresolved_relation_entity():
    payload = _valid_payload()
    payload["relations"][0]["target_entity_id"] = "entity_missing"

    report = validate_native_knowledge_format(payload)

    assert report.status == "failed"
    assert "relation_entity_reference_missing" in report.failed_checks
    assert report.unresolved_relation_ids == ["relation_1"]


def test_native_knowledge_format_rejects_unresolved_memory_and_question_refs():
    payload = _valid_payload()
    payload["compound_questions"][0]["required_entity_ids"] = ["entity_missing"]
    payload["memory_cards"][0]["chunk_id"] = "chunk_missing"

    report = validate_native_knowledge_format(payload)

    assert report.status == "failed"
    assert "compound_question_reference_missing" in report.failed_checks
    assert "memory_card_reference_missing" in report.failed_checks
    assert report.unresolved_question_ids == ["question_1"]
    assert report.unresolved_memory_card_ids == ["memory_card_1"]


def test_native_knowledge_format_rejects_unresolved_summary_source():
    payload = _valid_payload()
    payload["cross_doc_summaries"][0]["source_ids"] = ["source_missing"]

    report = validate_native_knowledge_format(payload)

    assert report.status == "failed"
    assert "cross_doc_summary_reference_missing" in report.failed_checks
    assert report.unresolved_summary_ids == ["summary_1"]


def _valid_payload() -> dict:
    return {
        "chunks": [
            {
                "chunk_id": "chunk_1",
                "source_path": "input/a.md",
                "source_type": "md",
                "domain": "product",
                "mode": "analysis",
                "text": "Anchor entity evidence.",
                "order": 0,
                "char_count": 23,
            },
            {
                "chunk_id": "chunk_2",
                "source_path": "input/b.md",
                "source_type": "md",
                "domain": "product",
                "mode": "analysis",
                "text": "Related entity evidence.",
                "order": 1,
                "char_count": 24,
            },
        ],
        "source_trace": [
            {
                "source_id": "source_1",
                "source_path": "input/a.md",
                "chunk_id": "chunk_1",
                "citation": "input/a.md#chunk=chunk_1",
            },
            {
                "source_id": "source_2",
                "source_path": "input/b.md",
                "chunk_id": "chunk_2",
                "citation": "input/b.md#chunk=chunk_2",
            },
        ],
        "entities": [
            {
                "entity_id": "entity_anchor",
                "name": "Anchor",
                "entity_type": "concept",
                "source_path": "input/a.md",
                "chunk_id": "chunk_1",
                "citation": "input/a.md#chunk=chunk_1",
            },
            {
                "entity_id": "entity_evidence",
                "name": "Evidence",
                "entity_type": "concept",
                "source_path": "input/b.md",
                "chunk_id": "chunk_2",
                "citation": "input/b.md#chunk=chunk_2",
            },
        ],
        "relations": [
            {
                "relation_id": "relation_1",
                "source_entity_id": "entity_anchor",
                "target_entity_id": "entity_evidence",
                "relation_type": "supported_by",
                "source_path": "input/b.md",
                "chunk_id": "chunk_2",
                "citation": "input/b.md#chunk=chunk_2",
            }
        ],
        "compound_questions": [
            {
                "question_id": "question_1",
                "question": "How does the anchor connect to evidence?",
                "required_entity_ids": ["entity_anchor", "entity_evidence"],
                "source_path": "input/a.md",
                "chunk_id": "chunk_1",
                "citation": "input/a.md#chunk=chunk_1",
            }
        ],
        "cross_doc_summaries": [
            {
                "summary_id": "summary_1",
                "summary": "Anchor and evidence are connected across documents.",
                "source_ids": ["source_1", "source_2"],
                "citation": "input/a.md#chunk=chunk_1",
            }
        ],
        "memory_cards": [
            {
                "memory_card_id": "memory_card_1",
                "title": "Anchor to evidence",
                "summary": "Use Anchor -> Entity -> Evidence -> Answer.",
                "entity_ids": ["entity_anchor", "entity_evidence"],
                "source_path": "input/b.md",
                "chunk_id": "chunk_2",
                "citation": "input/b.md#chunk=chunk_2",
            }
        ],
    }
