from heitang_kb_forge.rag.exporter import RAGOptions, make_rag_export
from heitang_kb_forge.schemas.card_schema import KnowledgeCard
from heitang_kb_forge.schemas.chunk_schema import Chunk
from heitang_kb_forge.schemas.qa_schema import QAPair


def test_rag_export_builds_records_metadata_citation_map_and_manifest():
    chunks = [_chunk("chunk-a", "Chunk fixture text")]
    cards = [
        KnowledgeCard(
            card_id="card-a",
            chunk_id="chunk-a",
            title="Card title",
            summary="Card summary",
            source_path="source.md",
            domain="education",
            mode="teaching",
            tags=["tag"],
            citation="source.md#chunk=chunk-a",
        )
    ]
    qa_pairs = [
        QAPair(
            qa_id="qa-a",
            chunk_id="chunk-a",
            question="What is the fixture?",
            answer="A RAG fixture.",
            source_path="source.md",
            domain="education",
            mode="teaching",
            citation="source.md#chunk=chunk-a",
        )
    ]
    glossary = [
        {
            "term": "RAG",
            "definition": "Retrieval augmented generation",
            "source_path": "source.md",
            "chunk_id": "chunk-a",
            "citation": "source.md#chunk=chunk-a",
        }
    ]

    result = make_rag_export(
        chunks=chunks,
        cards=cards,
        qa_pairs=qa_pairs,
        glossary=glossary,
        quality_report={"quality_score": 90, "quality_level": "excellent"},
        options=RAGOptions(enabled=True),
    )

    asset_types = {record.asset_type for record in result.embedding_inputs}
    assert asset_types == {"chunk", "card", "qa_pair", "glossary"}
    assert len(result.embedding_inputs) == len(result.retrieval_metadata)
    embedding_ids = {record.embedding_id for record in result.embedding_inputs}
    metadata_ids = {record.embedding_id for record in result.retrieval_metadata}
    assert embedding_ids == metadata_ids
    first_id = result.embedding_inputs[0].embedding_id
    assert result.citation_map["by_embedding_id"][first_id]["citation"]
    assert result.rag_manifest["total_records"] == 4
    assert result.rag_manifest["asset_type_counts"] == {
        "chunk": 1,
        "card": 1,
        "qa_pair": 1,
        "glossary": 1,
    }


def test_rag_export_includes_llm_assets_when_requested():
    chunks = [_chunk("chunk-a", "Chunk fixture text")]
    llm_outputs = {
        "cards": [_llm_item(title="LLM card", summary="LLM summary")],
        "qa_pairs": [_llm_item(question="LLM question?", answer="LLM answer")],
        "glossary": [_llm_item(term="LLM term", definition="LLM definition")],
        "frameworks": [_llm_item(name="LLM framework", summary="LLM framework summary")],
        "case_cards": [_llm_item(title="LLM case", case_summary="LLM case summary")],
        "metrics": [_llm_item(name="LLM metric", definition="LLM metric definition")],
    }

    result = make_rag_export(
        chunks=chunks,
        cards=[],
        qa_pairs=[],
        glossary=[],
        quality_report={"quality_score": 90, "quality_level": "excellent"},
        options=RAGOptions(enabled=True, include_llm=True),
        llm_outputs=llm_outputs,
    )

    asset_types = {record.asset_type for record in result.embedding_inputs}
    assert {
        "llm_card",
        "llm_qa_pair",
        "llm_glossary",
        "framework",
        "case_card",
        "metric",
    }.issubset(asset_types)
    assert any(metadata.from_llm for metadata in result.retrieval_metadata)


def test_rag_export_rejects_unsupported_profile():
    try:
        make_rag_export(
            chunks=[],
            cards=[],
            qa_pairs=[],
            glossary=[],
            quality_report={},
            options=RAGOptions(enabled=True, profile="advanced"),
        )
    except ValueError as exc:
        assert str(exc) == "Unsupported RAG profile: advanced"
    else:
        raise AssertionError("Expected unsupported RAG profile error")


def _chunk(chunk_id, text):
    return Chunk(
        chunk_id=chunk_id,
        source_path="source.md",
        source_type="md",
        domain="education",
        mode="teaching",
        title="Source",
        text=text,
        order=0,
        char_count=len(text),
    )


def _llm_item(**values):
    values.update(
        {
            "source_path": "source.md",
            "chunk_id": "chunk-a",
            "citation": "source.md#chunk=chunk-a",
            "llm_provider": "fake",
            "llm_model": "fake-model",
        }
    )
    return values
