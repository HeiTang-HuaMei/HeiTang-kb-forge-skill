from pathlib import Path

from heitang_kb_forge.runtime.prompt_builder import build_prompt
from heitang_kb_forge.runtime.retriever import retrieve
from heitang_kb_forge.schemas.runtime_schema import AnswerReport

RUNTIME_OUTPUT_FILES = ["answer.md", "answer_report.json", "retrieval_trace.json"]


def ask_package(package: Path, query: str, top_k: int = 5, provider: str = "fake", model: str = "fake-model") -> tuple[str, AnswerReport, dict]:
    records = retrieve(package, query, top_k)
    if not records:
        answer = "Insufficient context to answer from this knowledge package."
        report = AnswerReport(query=query, provider=provider, model=model, insufficient_context=True)
        return answer, report, {"query": query, "records": []}
    prompt = build_prompt(query, records)
    citations = [record.citation for record in records if record.citation]
    answer = _fake_answer(query, records, citations) if provider == "fake" else _openai_compatible_placeholder(provider)
    report = AnswerReport(query=query, provider=provider, model=model, citations=citations, insufficient_context=False)
    trace = {"query": query, "top_k": top_k, "prompt": prompt, "records": [record.model_dump(mode="json") for record in records]}
    return answer, report, trace


def _fake_answer(query: str, records: list, citations: list[str]) -> str:
    citation_block = "\n".join(f"- {citation}" for citation in citations)
    return f"""# Answer

Query: {query}

Based on the retrieved knowledge package, the most relevant context is:

{records[0].text}

## Citations

{citation_block}
"""


def _openai_compatible_placeholder(provider: str) -> str:
    raise RuntimeError(f"{provider} runtime calls are opt-in and not implemented for default offline tests")
