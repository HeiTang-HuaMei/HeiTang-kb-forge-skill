import re


def rank_records(records: list[dict], query: str, top_k: int = 5) -> list[dict]:
    query_tokens = set(_tokens(query))
    ranked = []
    for record in records:
        tokens = set(record.get("keywords", [])) or set(_tokens(record.get("text", "")))
        overlap = len(query_tokens & tokens)
        confidence_bonus = {"high": 2, "medium": 1, "low": 0}.get(record.get("confidence", "medium"), 1)
        review_penalty = 2 if record.get("review_required") else 0
        score = overlap * 3 + confidence_bonus - review_penalty
        ranked.append((score, record))
    ranked.sort(key=lambda item: (item[0], item[1].get("retrieval_id", "")), reverse=True)
    selected = []
    for score, record in ranked[:top_k]:
        item = dict(record)
        item["score"] = score
        selected.append(item)
    return selected


def _tokens(value: str) -> list[str]:
    return [token.lower() for token in re.findall(r"[\w\u4e00-\u9fff]+", value) if len(token) > 1]
