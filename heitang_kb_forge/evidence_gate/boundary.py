import re


def judge_boundary(query: str, evidence_records: list[dict]) -> dict:
    query_tokens = set(_tokens(query))
    evidence_tokens = set()
    for record in evidence_records:
        evidence_tokens.update(_tokens(record.get("text", "")))
    overlap = len(query_tokens & evidence_tokens)
    if not query_tokens:
        boundary = "unclear"
    elif overlap:
        boundary = "inside"
    else:
        boundary = "outside"
    return {
        "boundary": boundary,
        "overlap": overlap,
        "reason": "query overlaps package evidence" if overlap else "query has no package evidence overlap",
    }


def _tokens(value: str) -> list[str]:
    return [token.lower() for token in re.findall(r"[\w\u4e00-\u9fff]+", value) if len(token) > 1]
