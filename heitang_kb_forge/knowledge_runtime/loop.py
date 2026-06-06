from __future__ import annotations

from collections import Counter
from pathlib import Path
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.retrieval.index_builder import build_retrieval_index
from heitang_kb_forge.retrieval.ranker import rank_records


KB_RUNTIME_VERSION = "2.9.0-alpha.1"
KB_INDEX_FILES = [
    "kb_index.jsonl",
    "kb_index_manifest.json",
    "retrieval_quality_report.json",
    "rag_eval_baseline.jsonl",
    "rag_eval_baseline_report.md",
]
KB_QUERY_FILES = ["kb_query_result.json", "kb_query_trace.json", "kb_citation_trace.json"]
KB_ANSWER_FILES = ["kb_answer.md", "kb_answer_report.json"]
KB_RUNTIME_OUTPUT_FILES = KB_INDEX_FILES + KB_QUERY_FILES + KB_ANSWER_FILES


def build_kb_index_outputs(package: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    records = _records(package)
    quality = _quality_report(records)
    eval_rows = _rag_eval_baseline(package, records)
    manifest = {
        "kb_index_version": KB_RUNTIME_VERSION,
        "package": _safe_path(package),
        "total_records": len(records),
        "asset_type_counts": dict(Counter(record["asset_type"] for record in records)),
        "citation_coverage": quality["citation_coverage"],
        "output_files": KB_INDEX_FILES,
    }
    write_jsonl(output / "kb_index.jsonl", records)
    write_json(output / "kb_index_manifest.json", manifest)
    write_json(output / "retrieval_quality_report.json", quality)
    write_jsonl(output / "rag_eval_baseline.jsonl", eval_rows)
    (output / "rag_eval_baseline_report.md").write_text(_render_eval_report(eval_rows), encoding="utf-8")
    return manifest


def query_kb_outputs(package: Path, output: Path, query: str, top_k: int = 5, min_score: int = 2) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    records = _records(package)
    selected = rank_records(records, query, top_k)
    top_score = int(selected[0]["score"]) if selected else 0
    warnings = []
    if not selected:
        warnings.append("no_retrieval_records")
    elif top_score < min_score:
        warnings.append("low_confidence_retrieval")
    result = {
        "kb_query_version": KB_RUNTIME_VERSION,
        "status": "warning" if warnings else "pass",
        "query": query,
        "top_k": top_k,
        "min_score": min_score,
        "selected_count": len(selected),
        "top_score": top_score,
        "records": selected,
        "warnings": warnings,
    }
    trace = {
        "kb_query_trace_version": KB_RUNTIME_VERSION,
        "query": query,
        "top_k": top_k,
        "min_score": min_score,
        "selected_ids": [record["retrieval_id"] for record in selected],
        "ranking": [
            {
                "retrieval_id": record["retrieval_id"],
                "asset_type": record["asset_type"],
                "score": record["score"],
                "citation": record.get("citation", ""),
            }
            for record in selected
        ],
        "warnings": warnings,
    }
    write_json(output / "kb_query_result.json", result)
    write_json(output / "kb_query_trace.json", trace)
    write_json(output / "kb_citation_trace.json", _citation_trace(selected))
    write_json(output / "retrieval_quality_report.json", _quality_report(records, query, selected, min_score))
    return result


def answer_kb_outputs(
    package: Path,
    output: Path,
    query: str,
    top_k: int = 5,
    min_score: int = 2,
    citation_required: bool = True,
) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    build_kb_index_outputs(package, output)
    query_result = query_kb_outputs(package, output, query, top_k, min_score)
    selected = query_result["records"]
    top_score = query_result["top_score"]
    citations = [record.get("citation", "") for record in selected if record.get("citation")]
    refusal_reason = ""
    if not selected:
        refusal_reason = "insufficient_context"
    elif top_score < min_score:
        refusal_reason = "low_confidence"
    elif citation_required and not citations:
        refusal_reason = "missing_citation"

    if refusal_reason:
        answer = _refusal_answer(query, refusal_reason)
        status = "refused"
    else:
        answer = _grounded_answer(query, selected, citations)
        status = "answered"
    report = {
        "kb_answer_version": KB_RUNTIME_VERSION,
        "status": status,
        "query": query,
        "top_k": top_k,
        "min_score": min_score,
        "top_score": top_score,
        "citation_required": citation_required,
        "citation_count": len(citations),
        "refusal_reason": refusal_reason,
        "low_confidence_refusal": refusal_reason == "low_confidence",
        "output_files": KB_RUNTIME_OUTPUT_FILES,
    }
    (output / "kb_answer.md").write_text(answer, encoding="utf-8")
    write_json(output / "kb_answer_report.json", report)
    return report


def _records(package: Path) -> list[dict]:
    return [record.model_dump(mode="json") for record in build_retrieval_index(package)]


def _quality_report(records: list[dict], query: str | None = None, selected: list[dict] | None = None, min_score: int = 2) -> dict:
    total = len(records)
    cited = len([record for record in records if record.get("citation")])
    selected = selected or []
    selected_cited = len([record for record in selected if record.get("citation")])
    top_score = int(selected[0]["score"]) if selected else 0
    warnings = []
    if not records:
        warnings.append("empty_kb_index")
    if selected and top_score < min_score:
        warnings.append("low_confidence_retrieval")
    if selected and selected_cited < len(selected):
        warnings.append("selected_records_missing_citation")
    return {
        "retrieval_quality_version": KB_RUNTIME_VERSION,
        "status": "warning" if warnings else "pass",
        "query": query,
        "total_records": total,
        "selected_count": len(selected),
        "top_score": top_score,
        "min_score": min_score,
        "citation_coverage": cited / total if total else 0.0,
        "selected_citation_coverage": selected_cited / len(selected) if selected else 0.0,
        "warnings": warnings,
    }


def _rag_eval_baseline(package: Path, records: list[dict]) -> list[dict]:
    qa_rows = _read_jsonl(package / "qa_pairs.jsonl")
    rows = []
    for index, item in enumerate(qa_rows, start=1):
        question = str(item.get("question", "")).strip()
        if not question:
            continue
        rows.append(
            {
                "case_id": f"rag_eval_{index}",
                "query": question,
                "expected_citation": str(item.get("citation", "")),
                "expected_answer_hint": str(item.get("answer", ""))[:300],
            }
        )
    if rows:
        return rows
    for index, record in enumerate(records[:5], start=1):
        rows.append(
            {
                "case_id": f"rag_eval_{index}",
                "query": f"Summarize evidence from {record.get('retrieval_id')}",
                "expected_citation": str(record.get("citation", "")),
                "expected_answer_hint": str(record.get("text", ""))[:300],
            }
        )
    return rows


def _citation_trace(records: list[dict]) -> dict:
    return {
        "kb_citation_trace_version": KB_RUNTIME_VERSION,
        "citations": [
            {
                "retrieval_id": record.get("retrieval_id", ""),
                "source_path": record.get("source_path", ""),
                "chunk_id": record.get("chunk_id", ""),
                "citation": record.get("citation", ""),
            }
            for record in records
            if record.get("citation")
        ],
    }


def _grounded_answer(query: str, records: list[dict], citations: list[str]) -> str:
    context = records[0].get("text", "")
    citation_block = "\n".join(f"- {citation}" for citation in citations)
    return f"""# KB Answer

Query: {query}

{context}

## Citations

{citation_block}
"""


def _refusal_answer(query: str, reason: str) -> str:
    return f"""# KB Answer

Query: {query}

I cannot answer from this knowledge package with sufficient cited evidence.

Refusal reason: {reason}
"""


def _render_eval_report(rows: list[dict]) -> str:
    lines = ["# RAG Eval Baseline", "", f"- Cases: {len(rows)}", ""]
    for row in rows:
        lines.append(f"- {row['case_id']}: {row['query']} ({row.get('expected_citation') or 'no citation'})")
    return "\n".join(lines) + "\n"


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _safe_path(path: Path) -> str:
    return str(path).replace("\\", "/")
