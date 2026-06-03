from collections import Counter

from heitang_kb_forge.schemas.downstream_schema import LangChainDocument, LlamaIndexDocument

DOWNSTREAM_OUTPUT_FILES = [
    "langchain_documents.jsonl",
    "llamaindex_documents.jsonl",
    "generic_rag_package.json",
    "openai_files_manifest.json",
]


def make_downstream_exports(chunks: list, cards: list, qa_pairs: list, glossary: list[dict], quality_report: dict) -> dict:
    records = _records(chunks, cards, qa_pairs, glossary)
    langchain = [
        LangChainDocument(
            page_content=record["text"],
            metadata={key: value for key, value in record.items() if key != "text"},
        )
        for record in records
    ]
    llamaindex = [
        LlamaIndexDocument(
            text=record["text"],
            doc_id=record["id"],
            metadata={key: value for key, value in record.items() if key not in {"text", "id"}},
        )
        for record in records
    ]
    citations = {record["id"]: record.get("citation", "") for record in records}
    counts = Counter(record["asset_type"] for record in records)
    generic = {
        "documents": records,
        "chunks": [record for record in records if record["asset_type"] == "chunk"],
        "citations": citations,
        "metadata": {"total_records": len(records), "asset_type_counts": dict(counts)},
        "quality_summary": {
            "quality_score": quality_report.get("quality_score"),
            "quality_level": quality_report.get("quality_level"),
        },
    }
    openai_manifest = {
        "files": [
            {"file": "langchain_documents.jsonl", "purpose": "downstream_import"},
            {"file": "llamaindex_documents.jsonl", "purpose": "downstream_import"},
            {"file": "generic_rag_package.json", "purpose": "rag_intermediate"},
        ],
        "upload_performed": False,
    }
    return {
        "langchain_documents": langchain,
        "llamaindex_documents": llamaindex,
        "generic_rag_package": generic,
        "openai_files_manifest": openai_manifest,
    }


def _records(chunks: list, cards: list, qa_pairs: list, glossary: list[dict]) -> list[dict]:
    records: list[dict] = []
    for chunk in chunks:
        records.append(
            {
                "id": chunk.chunk_id,
                "text": chunk.text,
                "asset_type": "chunk",
                "source_path": chunk.source_path,
                "chunk_id": chunk.chunk_id,
                "citation": f"{chunk.source_path}#chunk={chunk.chunk_id}",
            }
        )
    for card in cards:
        records.append(
            {
                "id": card.card_id,
                "text": f"{card.title}\n{card.summary}",
                "asset_type": "card",
                "source_path": card.source_path,
                "chunk_id": card.chunk_id,
                "citation": card.citation,
            }
        )
    for pair in qa_pairs:
        records.append(
            {
                "id": pair.qa_id,
                "text": f"Question: {pair.question}\nAnswer: {pair.answer}",
                "asset_type": "qa_pair",
                "source_path": pair.source_path,
                "chunk_id": pair.chunk_id,
                "citation": pair.citation,
            }
        )
    for index, item in enumerate(glossary, start=1):
        records.append(
            {
                "id": f"glossary_{index}",
                "text": f"{item.get('term', '')}: {item.get('definition', '')}",
                "asset_type": "glossary",
                "source_path": item.get("source_path", ""),
                "chunk_id": item.get("chunk_id", ""),
                "citation": item.get("citation", ""),
            }
        )
    return records
