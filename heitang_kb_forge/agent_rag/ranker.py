from heitang_kb_forge.schemas.agent_rag_schema import AgentRAGRecord


def rank_records(records: list[AgentRAGRecord], query: str, top_k: int) -> list[AgentRAGRecord]:
    terms = [term.lower() for term in query.split() if term.strip()]
    ranked: list[AgentRAGRecord] = []
    for record in records:
        text = record.text.lower()
        score = sum(1 for term in terms if term in text)
        ranked.append(record.model_copy(update={"score": score or 1}))
    return sorted(ranked, key=lambda item: item.score, reverse=True)[:top_k]
