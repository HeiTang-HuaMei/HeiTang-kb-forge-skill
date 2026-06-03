from heitang_kb_forge.schemas.retrieval_eval_schema import RetrievalEvalRecord

RETRIEVAL_EVAL_OUTPUT_FILES = ["retrieval_eval_set.jsonl", "golden_qa.jsonl", "citation_eval_set.jsonl"]


def make_retrieval_eval_set(qa_pairs: list, cards: list, glossary: list[dict], llm_outputs: dict | None = None) -> tuple[list[RetrievalEvalRecord], list[RetrievalEvalRecord], list[RetrievalEvalRecord]]:
    records: list[RetrievalEvalRecord] = []
    for pair in qa_pairs:
        if not pair.chunk_id or not pair.citation:
            continue
        records.append(
            RetrievalEvalRecord(
                question=pair.question,
                expected_chunk_id=pair.chunk_id,
                expected_citation=pair.citation,
                answer_hint=pair.answer,
                source_path=pair.source_path,
                asset_type="qa_pair",
            )
        )
    for card in cards:
        if not card.chunk_id or not card.citation:
            continue
        records.append(
            RetrievalEvalRecord(
                question=f"What should be known about {card.title}?",
                expected_chunk_id=card.chunk_id,
                expected_citation=card.citation,
                answer_hint=card.summary,
                source_path=card.source_path,
                asset_type="card",
            )
        )
    for item in glossary:
        if not item.get("chunk_id") or not item.get("citation"):
            continue
        records.append(
            RetrievalEvalRecord(
                question=f"What does {item.get('term')} mean?",
                expected_chunk_id=str(item.get("chunk_id")),
                expected_citation=str(item.get("citation")),
                answer_hint=str(item.get("definition", "")),
                source_path=str(item.get("source_path", "")),
                asset_type="glossary",
            )
        )
    return records, [record for record in records if record.asset_type == "qa_pair"], records
