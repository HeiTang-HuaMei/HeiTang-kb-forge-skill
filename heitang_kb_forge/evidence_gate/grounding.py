from heitang_kb_forge.retrieval.ranker import rank_records


def find_grounding(query: str, records: list[dict], top_k: int = 5) -> list[dict]:
    return [record for record in rank_records(records, query, top_k) if record.get("score", 0) > 0]
