from heitang_kb_forge.schemas.agent_rag_schema import AgentRAGRecord


STOPWORDS = {
    "a",
    "an",
    "and",
    "are",
    "does",
    "is",
    "of",
    "or",
    "says",
    "source",
    "the",
    "this",
    "to",
    "what",
    "which",
}


def rank_records(records: list[AgentRAGRecord], query: str, top_k: int) -> list[AgentRAGRecord]:
    terms = [term for term in query.lower().replace("?", " ").replace("？", " ").split() if term.strip() and term not in STOPWORDS]
    ranked: list[AgentRAGRecord] = []
    for record in records:
        text = record.text.lower()
        score = sum(1 for term in terms if term in text)
        ranked.append(record.model_copy(update={"score": score}))
    return sorted(ranked, key=lambda item: item.score, reverse=True)[:top_k]
