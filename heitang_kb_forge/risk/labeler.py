from heitang_kb_forge.schemas.risk_schema import RiskLabelRecord

RISK_OUTPUT_FILES = ["risk_labels.jsonl", "source_reliability_report.md"]


def make_risk_labels(chunks: list, cards: list, qa_pairs: list, glossary: list[dict], llm_outputs: dict | None = None, validation_report: dict | None = None) -> tuple[list[RiskLabelRecord], str]:
    labels: list[RiskLabelRecord] = []
    for chunk in chunks:
        lowered = chunk.text.lower()
        if "ocr" in lowered or "[page" in lowered:
            labels.append(_label("ocr_uncertain", "medium", "OCR-derived content may contain recognition errors.", chunk.source_path, chunk.chunk_id, _citation(chunk.source_path, chunk.chunk_id)))
        if "table" in lowered or "column a" in lowered:
            labels.append(_label("table_best_effort", "medium", "Table-like content was converted to text best-effort.", chunk.source_path, chunk.chunk_id, _citation(chunk.source_path, chunk.chunk_id)))
    for item in list(cards) + list(qa_pairs):
        if not getattr(item, "citation", ""):
            labels.append(_label("missing_citation", "high", "Asset has no citation.", getattr(item, "source_path", ""), getattr(item, "chunk_id", ""), ""))
    if llm_outputs:
        for records in llm_outputs.values():
            for record in records:
                if float(record.get("confidence", 1.0)) < 0.5:
                    labels.append(_label("low_confidence_llm", "medium", "LLM asset confidence is below threshold.", str(record.get("source_path", "")), str(record.get("chunk_id", "")), str(record.get("citation", ""))))
    if validation_report and validation_report.get("hallucination_risk_level") in {"medium", "high"}:
        labels.append(_label("hallucination_risk", validation_report["hallucination_risk_level"], "Package validation reported hallucination risk.", "", "", ""))
    return labels, _report(labels)


def _label(label: str, severity: str, reason: str, source_path: str, chunk_id: str, citation: str) -> RiskLabelRecord:
    return RiskLabelRecord(risk_id=f"{label}_{len(reason)}_{abs(hash((label, source_path, chunk_id))) % 100000}", label=label, severity=severity, reason=reason, source_path=source_path, chunk_id=chunk_id, citation=citation)


def _citation(source_path: str, chunk_id: str) -> str:
    return f"{source_path}#chunk={chunk_id}"


def _report(labels: list[RiskLabelRecord]) -> str:
    rows = "\n".join(f"| {item.label} | {item.severity} | {item.source_path} | {item.chunk_id} |" for item in labels) or "| - | - | - | - |"
    return f"""# Source Reliability Report

## Summary

- Risk labels: {len(labels)}

## Labels

| Label | Severity | Source Path | Chunk ID |
| --- | --- | --- | --- |
{rows}
"""
