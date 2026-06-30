from heitang_kb_forge.schemas.agent_rag_schema import AgentRAGAnswerReport, AgentRAGRecord


def answer_from_records(query: str, records: list[AgentRAGRecord], top_k: int, citation_required: bool = False) -> tuple[str, AgentRAGAnswerReport]:
    positive_records = [record for record in records if record.score > 0]
    citation_records = positive_records if citation_required else records
    citations = [record.citation for record in citation_records if record.citation]
    has_positive_context = any(record.score > 0 for record in records)
    insufficient = not records or (citation_required and (not citations or not has_positive_context))
    if insufficient:
        answer = "Insufficient cited context to answer from this knowledge package."
    else:
        citation_block = "\n".join(f"- {citation}" for citation in citations)
        answer = f"""# Answer

Query: {query}

{records[0].text}

## Citations

{citation_block}
"""
    report = AgentRAGAnswerReport(
        query=query,
        top_k=top_k,
        citation_required=citation_required,
        insufficient_context=insufficient,
        citation_count=len(citations),
        output_files=["answer.md", "answer_report.json", "retrieval_trace.json", "citation_trace.json"],
    )
    return answer, report
