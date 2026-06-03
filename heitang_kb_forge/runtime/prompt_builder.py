from heitang_kb_forge.schemas.runtime_schema import RetrievedRecord


def build_prompt(query: str, records: list[RetrievedRecord]) -> str:
    context = "\n\n".join(f"[{index}] {record.text}\nCitation: {record.citation}" for index, record in enumerate(records, start=1))
    return f"""Answer the query using only the retrieved context. Include citations.

Query: {query}

Context:
{context}
"""
