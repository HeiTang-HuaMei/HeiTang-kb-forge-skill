from heitang_kb_forge.schemas.retrieval_regression_schema import (
    RetrievalRegressionInput,
    RetrievalRegressionReport,
    RetrievalRegressionRun,
)


def run_retrieval_regression(payload: RetrievalRegressionInput | dict) -> RetrievalRegressionReport:
    data = payload if isinstance(payload, RetrievalRegressionInput) else RetrievalRegressionInput.model_validate(payload)
    baseline_top = _top(data.baseline)
    current_top = _top(data.current)
    checks = {
        "query_changed": _key(data.baseline.query) != _key(data.current.query),
        "top_record_changed": baseline_top.record_id != current_top.record_id,
        "top_citation_changed": baseline_top.citation != current_top.citation,
        "citation_trace_count_changed": data.baseline.citation_trace_count != data.current.citation_trace_count,
    }
    regressions = [name for name, failed in checks.items() if failed]
    return RetrievalRegressionReport(
        status="pass" if not regressions else "regression_found",
        query_match=not checks["query_changed"],
        top_record_match=not checks["top_record_changed"],
        top_citation_match=not checks["top_citation_changed"],
        citation_trace_count_match=not checks["citation_trace_count_changed"],
        baseline_top_record_id=baseline_top.record_id,
        current_top_record_id=current_top.record_id,
        baseline_top_citation=baseline_top.citation,
        current_top_citation=current_top.citation,
        regression_count=len(regressions),
        regressions=regressions,
        summary=f"{len(regressions)} retrieval regression(s) found.",
    )


def _top(run: RetrievalRegressionRun):
    if run.records:
        return run.records[0]
    return type("_EmptyRecord", (), {"record_id": "", "citation": ""})()


def _key(value: str) -> str:
    return " ".join(str(value).strip().lower().split())
